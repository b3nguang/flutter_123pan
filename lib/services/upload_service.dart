import 'dart:io';
import 'package:crypto/crypto.dart';
import '../models/transfer_task.dart';
import 'api_service.dart';

class UploadService {
  final ApiService _api;

  UploadService(this._api);

  Future<String> _computeMd5(String filePath) async {
    final input = File(filePath).openRead();
    final digest = await md5.bind(input).first;
    return digest.toString();
  }

  Future<void> upload({
    required String filePath,
    required int parentFileId,
    required int duplicate,
    required TransferController controller,
    void Function(double progress)? onProgress,
  }) async {
    filePath = filePath.replaceAll('"', '');
    final file = File(filePath);
    if (!await file.exists()) throw Exception('文件不存在');
    if (await FileSystemEntity.isDirectory(filePath)) {
      throw Exception('不支持文件夹上传');
    }

    final fileName = file.uri.pathSegments.last;
    final fileSize = await file.length();

    if (controller.isCancelled) throw Exception('已取消');

    final etag = await _computeMd5(filePath);
    if (controller.isCancelled) throw Exception('已取消');

    var uploadResp = await _api.uploadRequest(
      fileName: fileName,
      fileSize: fileSize,
      etag: etag,
      parentFileId: parentFileId,
      duplicate: 0,
    );

    if (uploadResp['code'] == 5060) {
      uploadResp = await _api.uploadRequest(
        fileName: fileName,
        fileSize: fileSize,
        etag: etag,
        parentFileId: parentFileId,
        duplicate: duplicate,
      );
    }

    if (uploadResp['code'] != 0) {
      throw Exception('上传请求失败: ${uploadResp['message']}');
    }

    final data = uploadResp['data'] as Map<String, dynamic>;
    if (data['Reuse'] == true) {
      onProgress?.call(1.0);
      return;
    }

    final bucket = data['Bucket'] as String;
    final storageNode = data['StorageNode'] as String;
    final uploadKey = data['Key'] as String;
    final uploadId = data['UploadId'] as String;
    final upFileId = data['FileId'] as int;

    const blockSize = 5 * 1024 * 1024;
    int totalSent = 0;
    int partNumber = 1;

    final raf = await file.open();
    try {
      while (true) {
        if (controller.isCancelled) throw Exception('已取消');
        await controller.checkPause();

        final block = await raf.read(blockSize);
        if (block.isEmpty) break;

        final uploadUrl = await _api.getUploadPartUrl(
          bucket: bucket,
          key: uploadKey,
          uploadId: uploadId,
          storageNode: storageNode,
          partNumber: partNumber,
        );

        await _api.putFilePart(uploadUrl, block);

        totalSent += block.length;
        if (fileSize > 0) {
          onProgress?.call(totalSent / fileSize);
        }
        partNumber++;
      }
    } finally {
      await raf.close();
    }

    await _api.completeUpload(
      bucket: bucket,
      key: uploadKey,
      uploadId: uploadId,
      storageNode: storageNode,
      fileId: upFileId,
      fileSize: fileSize,
    );
  }
}
