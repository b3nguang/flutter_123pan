import 'package:flutter/foundation.dart';
import '../models/file_item.dart';
import '../services/api_service.dart';

enum FileLoadState { idle, loading, loaded, error }

class FileProvider extends ChangeNotifier {
  final ApiService apiService;

  FileLoadState _state = FileLoadState.idle;
  String _errorMessage = '';
  List<FileItem> _files = [];
  final List<int> _pathIds = [0];
  final List<String> _pathNames = [];
  int _currentPage = 1;
  int _totalFiles = 0;
  bool _hasMore = true;

  FileProvider({required this.apiService});

  FileLoadState get state => _state;
  String get errorMessage => _errorMessage;
  List<FileItem> get files => List.unmodifiable(_files);
  List<String> get pathNames => List.unmodifiable(_pathNames);
  int get currentFolderId => _pathIds.last;
  bool get isRoot => _pathIds.length == 1;
  bool get hasMore => _hasMore;
  int get totalFiles => _totalFiles;

  String get currentPath {
    if (_pathNames.isEmpty) return '/';
    return '/${_pathNames.join('/')}';
  }

  Future<void> loadFiles({bool reset = true}) async {
    if (reset) {
      _files = [];
      _currentPage = 1;
      _totalFiles = 0;
      _hasMore = true;
    }

    if (!_hasMore && !reset) return;

    _state = FileLoadState.loading;
    notifyListeners();

    try {
      const pagesPerLoad = 3;
      int fetched = 0;
      while (fetched < pagesPerLoad) {
        final result = await apiService.getFileList(
          parentFileId: currentFolderId,
          page: _currentPage,
        );
        if (result['code'] != 0) {
          throw Exception(result['message'] ?? '获取文件列表失败');
        }
        final infoList = result['data']['InfoList'] as List<dynamic>? ?? [];
        _totalFiles = result['data']['Total'] as int? ?? 0;
        final items = infoList
            .map((e) => FileItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _files.addAll(items);
        _currentPage++;
        fetched++;
        if (_files.length >= _totalFiles || items.isEmpty) {
          _hasMore = false;
          break;
        }
      }
      _state = FileLoadState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = FileLoadState.error;
    }
    notifyListeners();
  }

  Future<void> enterFolder(FileItem folder) async {
    _pathIds.add(folder.fileId);
    _pathNames.add(folder.fileName);
    await loadFiles(reset: true);
  }

  Future<void> goUp() async {
    if (_pathIds.length <= 1) return;
    _pathIds.removeLast();
    _pathNames.removeLast();
    await loadFiles(reset: true);
  }

  Future<void> goToRoot() async {
    _pathIds.clear();
    _pathIds.add(0);
    _pathNames.clear();
    await loadFiles(reset: true);
  }

  Future<void> goToIndex(int index) async {
    if (index >= _pathIds.length - 1) return;
    while (_pathIds.length > index + 2) {
      _pathIds.removeLast();
      _pathNames.removeLast();
    }
    await loadFiles(reset: true);
  }

  void clearError() {
    _errorMessage = '';
    _state = FileLoadState.idle;
    notifyListeners();
  }
}
