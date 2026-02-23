import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/file_item.dart';

class ApiService {
  static final List<String> _allDeviceTypes = [
    'MI-ONE PLUS', 'MI-ONE C1', 'MI-ONE', '2013061', '2013062',
    'M1804D2SE', 'M1803E1A', 'M1807E8S', 'M1902F1A', 'M1908F1XE',
    'M2001J2E', 'M2001J1E', 'M2002J9E', 'M2007J3SY', 'M2007J17G',
    'M2102J2SC', 'M2011K2C', 'M2102K1AC', 'M2101K9C', 'M2101K9G',
    '2107119DC', '2109119DG', 'M2012K11G', '21081111RG', '2107113SG',
    '2201123C', '2201123G', '2112123AC', '2207122MC', '2203129G',
  ];

  static final List<String> _allOsVersions = [
    'Android_7.1.2', 'Android_8.0.0', 'Android_8.1.0', 'Android_9.0',
    'Android_10', 'Android_11', 'Android_12', 'Android_13',
  ];

  late String _deviceType;
  late String _osVersion;
  late Map<String, String> _headers;
  String _authorization = '';

  ApiService() {
    final rng = Random();
    _deviceType = _allDeviceTypes[rng.nextInt(_allDeviceTypes.length)];
    _osVersion = _allOsVersions[rng.nextInt(_allOsVersions.length)];
    _buildHeaders();
  }

  void _buildHeaders() {
    _headers = {
      'user-agent': 'com.jinStorage.mobile.Client/$_osVersion;Xiaomi',
      'authorization': _authorization,
      'accept-encoding': 'gzip',
      'content-type': 'application/json',
      'osversion': _osVersion,
      'platform': 'android',
      'devicetype': _deviceType,
      'devicename': 'Xiaomi',
      'host': 'www.123pan.com',
      'app-version': '61',
      'x-app-version': '2.4.0',
    };
  }

  String get deviceType => _deviceType;
  String get osVersion => _osVersion;
  String get authorization => _authorization;

  void setDeviceInfo(String deviceType, String osVersion) {
    _deviceType = deviceType;
    _osVersion = osVersion;
    _buildHeaders();
  }

  void setAuthorization(String auth) {
    _authorization = auth;
    _headers['authorization'] = auth;
  }

  Map<String, String> get headers => Map.unmodifiable(_headers);

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  ));

  Future<Map<String, dynamic>> login(String userName, String password) async {
    final data = {'type': 1, 'passport': userName, 'password': password};
    final resp = await _dio.post(
      'https://www.123pan.com/b/api/user/sign_in',
      data: data,
      options: Options(headers: _headers),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFileList({
    required int parentFileId,
    required int page,
    int limit = 100,
  }) async {
    final resp = await _dio.get(
      'https://www.123pan.com/api/file/list/new',
      queryParameters: {
        'driveId': 0,
        'limit': limit,
        'next': 0,
        'orderBy': 'file_id',
        'orderDirection': 'desc',
        'parentFileId': parentFileId.toString(),
        'trashed': false,
        'SearchData': '',
        'Page': page.toString(),
        'OnlyLookAbnormalFile': 0,
      },
      options: Options(headers: _headers),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<List<FileItem>> getAllFiles({required int parentFileId}) async {
    final List<FileItem> result = [];
    int page = 1;
    int total = -1;

    while (result.length < total || total == -1) {
      final data = await getFileList(parentFileId: parentFileId, page: page);
      if (data['code'] != 0) {
        throw Exception('获取文件列表失败: ${data['message']}');
      }
      final infoList = data['data']['InfoList'] as List<dynamic>? ?? [];
      result.addAll(infoList.map((e) => FileItem.fromJson(e as Map<String, dynamic>)));
      total = data['data']['Total'] as int? ?? 0;
      page++;
      if (infoList.isEmpty) break;
    }
    return result;
  }

  Future<String> getDownloadLink(FileItem file) async {
    String url;
    Map<String, dynamic> body;

    if (file.isFolder) {
      url = 'https://www.123pan.com/a/api/file/batch_download_info';
      body = {
        'fileIdList': [
          {'fileId': file.fileId}
        ]
      };
    } else {
      url = 'https://www.123pan.com/a/api/file/download_info';
      body = {
        'driveId': 0,
        'etag': file.etag,
        'fileId': file.fileId,
        's3keyFlag': file.s3KeyFlag,
        'type': file.type,
        'fileName': file.fileName,
        'size': file.size,
      };
    }

    final resp = await _dio.post(
      url,
      data: jsonEncode(body),
      options: Options(headers: _headers),
    );
    final json = resp.data as Map<String, dynamic>;
    if (json['code'] != 0) {
      throw Exception('获取下载链接失败: ${json['message']}');
    }

    final downloadUrl = json['data']['DownloadUrl'] as String;
    final redirectResp = await _dio.get(
      downloadUrl,
      options: Options(
        followRedirects: false,
        validateStatus: (status) => status != null && status < 400,
        headers: {'User-Agent': 'Mozilla/5.0'},
      ),
    );
    final location = redirectResp.headers.value('location');
    if (location != null && location.isNotEmpty) {
      return location;
    }
    final body2 = redirectResp.data?.toString() ?? '';
    final match = RegExp(r"href='(https?://[^']+)'").firstMatch(body2);
    if (match != null) {
      return match.group(1)!;
    }
    return downloadUrl;
  }

  Future<void> deleteFile(FileItem file) async {
    final body = {
      'driveId': 0,
      'fileTrashInfoList': [
        {'fileId': file.fileId, 'driveId': 0}
      ],
      'operation': true,
    };
    final resp = await _dio.post(
      'https://www.123pan.com/a/api/file/trash',
      data: jsonEncode(body),
      options: Options(headers: _headers),
    );
    final json = resp.data as Map<String, dynamic>;
    if (json['code'] != 0) {
      throw Exception('删除失败: ${json['message']}');
    }
  }

  Future<String> shareFile(int fileId, {String sharePwd = ''}) async {
    final body = {
      'driveId': 0,
      'expiration': '2099-12-12T08:00:00+08:00',
      'fileIdList': fileId.toString(),
      'shareName': '123云盘分享',
      'sharePwd': sharePwd,
      'event': 'shareCreate',
    };
    final resp = await _dio.post(
      'https://www.123pan.com/a/api/share/create',
      data: jsonEncode(body),
      options: Options(headers: _headers),
    );
    final json = resp.data as Map<String, dynamic>;
    if (json['code'] != 0) {
      throw Exception('分享失败: ${json['message']}');
    }
    final shareKey = json['data']['ShareKey'] as String;
    return 'https://www.123pan.com/s/$shareKey';
  }

  Future<int> mkdir(String name, int parentFileId) async {
    final body = {
      'driveId': 0,
      'etag': '',
      'fileName': name,
      'parentFileId': parentFileId,
      'size': 0,
      'type': 1,
      'duplicate': 1,
      'NotReuse': true,
      'event': 'newCreateFolder',
      'operateType': 1,
    };
    final resp = await _dio.post(
      'https://www.123pan.com/a/api/file/upload_request',
      data: jsonEncode(body),
      options: Options(headers: _headers),
    );
    final json = resp.data as Map<String, dynamic>;
    if (json['code'] != 0) {
      throw Exception('创建文件夹失败: ${json['message']}');
    }
    return json['data']['FileId'] as int? ?? 0;
  }

  Future<Map<String, dynamic>> uploadRequest({
    required String fileName,
    required int fileSize,
    required String etag,
    required int parentFileId,
    int duplicate = 0,
  }) async {
    final body = {
      'driveId': 0,
      'etag': etag,
      'fileName': fileName,
      'parentFileId': parentFileId,
      'size': fileSize,
      'type': 0,
      'duplicate': duplicate,
    };
    final resp = await _dio.post(
      'https://www.123pan.com/b/api/file/upload_request',
      data: body,
      options: Options(headers: _headers),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<String> getUploadPartUrl({
    required String bucket,
    required String key,
    required String uploadId,
    required String storageNode,
    required int partNumber,
  }) async {
    final body = {
      'bucket': bucket,
      'key': key,
      'partNumberEnd': partNumber + 1,
      'partNumberStart': partNumber,
      'uploadId': uploadId,
      'StorageNode': storageNode,
    };
    final resp = await _dio.post(
      'https://www.123pan.com/b/api/file/s3_repare_upload_parts_batch',
      data: jsonEncode(body),
      options: Options(headers: _headers),
    );
    final json = resp.data as Map<String, dynamic>;
    if (json['code'] != 0) {
      throw Exception('获取上传链接失败: ${json['message']}');
    }
    return json['data']['presignedUrls'][partNumber.toString()] as String;
  }

  Future<void> completeUpload({
    required String bucket,
    required String key,
    required String uploadId,
    required String storageNode,
    required int fileId,
  }) async {
    final compData = {
      'bucket': bucket,
      'key': key,
      'uploadId': uploadId,
      'storageNode': storageNode,
    };
    await _dio.post(
      'https://www.123pan.com/b/api/file/s3_complete_multipart_upload',
      data: jsonEncode(compData),
      options: Options(headers: _headers),
    );

    if (fileId > 64 * 1024 * 1024) {
      await Future.delayed(const Duration(seconds: 3));
    }

    final closeData = {'fileId': fileId};
    final resp = await _dio.post(
      'https://www.123pan.com/b/api/file/upload_complete',
      data: jsonEncode(closeData),
      options: Options(headers: _headers),
    );
    final json = resp.data as Map<String, dynamic>;
    if (json['code'] != 0) {
      throw Exception('上传完成确认失败: ${json['message']}');
    }
  }

  Future<void> putFilePart(String url, List<int> data) async {
    await _dio.put(
      url,
      data: Stream.fromIterable([data]),
      options: Options(
        headers: {
          'Content-Length': data.length,
          HttpHeaders.contentTypeHeader: 'application/octet-stream',
        },
        sendTimeout: const Duration(minutes: 5),
      ),
    );
  }
}
