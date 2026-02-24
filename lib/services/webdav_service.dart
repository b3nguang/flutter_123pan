import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';
import 'api_service.dart';

class WebDavService {
  HttpServer? _server;
  ApiService? _apiService;
  String _basePath = '/dav';
  String _username = '';
  String _password = '';

  // path → fileId cache  (e.g. '/Documents/' → 12345)
  final Map<String, int> _pathCache = {'/': 0};
  // fileId → children cache
  final Map<int, List<FileItem>> _dirCache = {};

  bool get isRunning => _server != null;
  int get port => _server?.port ?? 0;

  Future<void> start({
    required int port,
    required String basePath,
    required String username,
    required String password,
    required ApiService apiService,
  }) async {
    await stop();
    _apiService = apiService;
    _basePath = basePath.isEmpty ? '/dav' : basePath;
    if (!_basePath.startsWith('/')) _basePath = '/$_basePath';
    _username = username;
    _password = password;
    _pathCache.clear();
    _pathCache['/'] = 0;
    _dirCache.clear();

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_handleRequest, onError: (_) {});
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _pathCache.clear();
    _pathCache['/'] = 0;
    _dirCache.clear();
  }

  // ── request dispatcher ────────────────────────────────────────────────────

  Future<void> _handleRequest(HttpRequest req) async {
    try {
      if (!_checkAuth(req)) {
        req.response
          ..statusCode = HttpStatus.unauthorized
          ..headers.set('WWW-Authenticate', 'Basic realm="WebDAV"')
          ..write('Unauthorized');
        await req.response.close();
        return;
      }

      switch (req.method.toUpperCase()) {
        case 'OPTIONS':
          await _handleOptions(req);
          break;
        case 'PROPFIND':
          await _handlePropfind(req);
          break;
        case 'GET':
        case 'HEAD':
          await _handleGet(req);
          break;
        default:
          req.response
            ..statusCode = HttpStatus.methodNotAllowed
            ..headers.set('Allow', 'OPTIONS, GET, HEAD, PROPFIND')
            ..write('Method Not Allowed');
          await req.response.close();
      }
    } catch (e) {
      try {
        req.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Internal Server Error: $e');
        await req.response.close();
      } catch (_) {}
    }
  }

  // ── Basic Auth ────────────────────────────────────────────────────────────

  bool _checkAuth(HttpRequest req) {
    if (_username.isEmpty && _password.isEmpty) return true;
    final authHeader = req.headers.value('authorization') ?? '';
    if (!authHeader.startsWith('Basic ')) return false;
    final decoded = utf8.decode(base64.decode(authHeader.substring(6)));
    final idx = decoded.indexOf(':');
    if (idx < 0) return false;
    final u = decoded.substring(0, idx);
    final pw = decoded.substring(idx + 1);
    return u == _username && pw == _password;
  }

  // ── OPTIONS ───────────────────────────────────────────────────────────────

  Future<void> _handleOptions(HttpRequest req) async {
    req.response
      ..statusCode = HttpStatus.noContent
      ..headers.set('DAV', '1')
      ..headers.set('MS-Author-Via', 'DAV')
      ..headers.set('Allow', 'OPTIONS, GET, HEAD, PROPFIND');
    await req.response.close();
  }

  // ── PROPFIND ──────────────────────────────────────────────────────────────

  Future<void> _handlePropfind(HttpRequest req) async {
    final davPath = _urlToDavPath(req.uri.path);
    if (davPath == null) {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found');
      await req.response.close();
      return;
    }

    final depth = req.headers.value('Depth') ?? '1';
    if (depth != '0' && depth != '1') {
      req.response
        ..statusCode = HttpStatus.forbidden
        ..write('Forbidden: depth must be 0 or 1');
      await req.response.close();
      return;
    }

    // Resolve the target resource
    final target = await _resolvePath(davPath);
    if (target == null) {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found');
      await req.response.close();
      return;
    }

    final responses = <_DavEntry>[target];

    if (target.isDir && depth == '1') {
      final children = await _listDir(target.fileId, davPath);
      responses.addAll(children);
    }

    final xml = _buildMultistatus(responses);
    req.response
      ..statusCode = 207
      ..headers.contentType = ContentType('application', 'xml', charset: 'utf-8')
      ..write(xml);
    await req.response.close();
  }

  // ── GET / HEAD ────────────────────────────────────────────────────────────

  Future<void> _handleGet(HttpRequest req) async {
    final davPath = _urlToDavPath(req.uri.path);
    if (davPath == null) {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found');
      await req.response.close();
      return;
    }

    final entry = await _resolvePath(davPath);
    if (entry == null) {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found');
      await req.response.close();
      return;
    }

    if (entry.isDir) {
      req.response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Method Not Allowed');
      await req.response.close();
      return;
    }

    // Fetch real download URL and redirect
    try {
      final url = await _apiService!.getDownloadLink(entry.file!);
      req.response
        ..statusCode = HttpStatus.found
        ..headers.set('Location', url);
      await req.response.close();
    } catch (e) {
      req.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Failed to get download URL: $e');
      await req.response.close();
    }
  }

  // ── Path helpers ──────────────────────────────────────────────────────────

  /// Convert a request URL path to a clean DAV-relative path.
  /// Returns null if the URL is outside the base path.
  String? _urlToDavPath(String urlPath) {
    final base = _basePath.endsWith('/') ? _basePath : '$_basePath/';
    final exactBase = _basePath;

    String cleaned;
    if (urlPath == exactBase || urlPath == base) {
      cleaned = '/';
    } else if (urlPath.startsWith(base)) {
      cleaned = '/${urlPath.substring(base.length)}';
    } else {
      return null;
    }

    // normalise: ensure trailing slash for directory-like paths
    return cleaned;
  }

  /// Resolve a DAV path to a _DavEntry. Returns null if not found.
  Future<_DavEntry?> _resolvePath(String davPath) async {
    // Root is always a directory
    if (davPath == '/' || davPath == '') {
      return _DavEntry.directory(
        href: _davPathToHref('/'),
        name: '/',
        fileId: 0,
      );
    }

    // Normalize: strip trailing slash for file lookup
    final normalised = davPath.endsWith('/')
        ? davPath.substring(0, davPath.length - 1)
        : davPath;

    final parentPath = '${p.dirname(normalised)}/'.replaceAll(r'\', '/');
    final name = p.basename(normalised);

    final parentId = await _resolvePathToId(parentPath);
    if (parentId == null) return null;

    final children = await _fetchDir(parentId);
    for (final item in children) {
      if (item.fileName == name) {
        return item.isFolder
            ? _DavEntry.directory(
                href: _davPathToHref('$normalised/'),
                name: item.fileName,
                fileId: item.fileId,
              )
            : _DavEntry.file(
                href: _davPathToHref(normalised),
                name: item.fileName,
                file: item,
              );
      }
    }
    return null;
  }

  /// Resolve a directory DAV path to its fileId (cached).
  Future<int?> _resolvePathToId(String dirPath) async {
    final norm = dirPath.isEmpty ? '/' : dirPath;
    if (_pathCache.containsKey(norm)) return _pathCache[norm];

    // Build path incrementally from root
    final segments = norm.split('/').where((s) => s.isNotEmpty).toList();
    int currentId = 0;
    String currentPath = '/';

    for (final seg in segments) {
      final children = await _fetchDir(currentId);
      FileItem? found;
      for (final item in children) {
        if (item.fileName == seg && item.isFolder) {
          found = item;
          break;
        }
      }
      if (found == null) return null;
      currentPath = '$currentPath$seg/';
      _pathCache[currentPath] = found.fileId;
      currentId = found.fileId;
    }
    return currentId;
  }

  /// Fetch directory contents (with cache).
  Future<List<FileItem>> _fetchDir(int folderId) async {
    if (_dirCache.containsKey(folderId)) return _dirCache[folderId]!;
    final items = await _apiService!.getAllFiles(parentFileId: folderId);
    _dirCache[folderId] = items;
    return items;
  }

  /// List a directory and return _DavEntry children.
  Future<List<_DavEntry>> _listDir(int folderId, String davDirPath) async {
    final children = await _fetchDir(folderId);
    final dirPrefix = davDirPath.endsWith('/') ? davDirPath : '$davDirPath/';
    return children.map((item) {
      if (item.isFolder) {
        final childPath = '$dirPrefix${item.fileName}/';
        _pathCache[childPath] = item.fileId;
        return _DavEntry.directory(
          href: _davPathToHref(childPath),
          name: item.fileName,
          fileId: item.fileId,
        );
      } else {
        return _DavEntry.file(
          href: _davPathToHref('$dirPrefix${item.fileName}'),
          name: item.fileName,
          file: item,
        );
      }
    }).toList();
  }

  String _davPathToHref(String davPath) {
    final base = _basePath.endsWith('/') ? _basePath : '$_basePath/';
    if (davPath == '/') return base;
    final rel = davPath.startsWith('/') ? davPath.substring(1) : davPath;
    return '$base$rel';
  }

  // ── XML builder ───────────────────────────────────────────────────────────

  String _buildMultistatus(List<_DavEntry> entries) {
    final buf = StringBuffer();
    buf.write('<?xml version="1.0" encoding="UTF-8"?>');
    buf.write('<d:multistatus xmlns:d="DAV:">');
    for (final e in entries) {
      buf.write('<d:response>');
      buf.write('<d:href>${_escapeXml(e.href)}</d:href>');
      buf.write('<d:propstat>');
      buf.write('<d:Prop>');
      buf.write('<d:displayname>${_escapeXml(e.name)}</d:displayname>');
      if (e.isDir) {
        buf.write('<d:resourcetype><d:collection/></d:resourcetype>');
      } else {
        buf.write('<d:resourcetype/>');
        buf.write('<d:getcontentlength>${e.file!.size}</d:getcontentlength>');
        if (e.file!.etag.isNotEmpty) {
          buf.write('<d:getetag>"${_escapeXml(e.file!.etag)}"</d:getetag>');
        }
        final ext = p.extension(e.name).toLowerCase();
        final ct = _mimeType(ext);
        if (ct.isNotEmpty) {
          buf.write('<d:getcontenttype>$ct</d:getcontenttype>');
        }
      }
      buf.write('</d:Prop>');
      buf.write('<d:status>HTTP/1.1 200 OK</d:status>');
      buf.write('</d:propstat>');
      buf.write('</d:response>');
    }
    buf.write('</d:multistatus>');
    return buf.toString();
  }

  String _escapeXml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  String _mimeType(String ext) {
    const map = {
      '.mp4': 'video/mp4', '.mkv': 'video/x-matroska',
      '.avi': 'video/x-msvideo', '.mov': 'video/quicktime',
      '.mp3': 'audio/mpeg', '.flac': 'audio/flac', '.wav': 'audio/wav',
      '.aac': 'audio/aac',
      '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png',
      '.gif': 'image/gif', '.webp': 'image/webp',
      '.pdf': 'application/pdf',
      '.zip': 'application/zip', '.rar': 'application/x-rar-compressed',
      '.7z': 'application/x-7z-compressed',
      '.txt': 'text/plain', '.md': 'text/markdown',
    };
    return map[ext] ?? 'application/octet-stream';
  }
}

// ── Helper data class ─────────────────────────────────────────────────────────

class _DavEntry {
  final String href;
  final String name;
  final bool isDir;
  final int fileId;
  final FileItem? file;

  const _DavEntry._({
    required this.href,
    required this.name,
    required this.isDir,
    required this.fileId,
    this.file,
  });

  factory _DavEntry.directory({
    required String href,
    required String name,
    required int fileId,
  }) =>
      _DavEntry._(href: href, name: name, isDir: true, fileId: fileId);

  factory _DavEntry.file({
    required String href,
    required String name,
    required FileItem file,
  }) =>
      _DavEntry._(href: href, name: name, isDir: false, fileId: 0, file: file);
}
