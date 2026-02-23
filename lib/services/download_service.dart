import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/transfer_task.dart';

class DownloadService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 30),
  ));

  Future<String> download({
    required String url,
    required String savePath,
    required String fileName,
    required TransferController controller,
    void Function(double progress)? onProgress,
  }) async {
    final dir = Directory(savePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final outPath = '$savePath${Platform.pathSeparator}$fileName';
    final tempPath = '$outPath.123pan';

    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    try {
      await _dio.download(
        url,
        tempPath,
        options: Options(headers: {'User-Agent': 'Mozilla/5.0'}),
        onReceiveProgress: (count, totalLen) async {
          if (controller.isCancelled) {
            throw DioException.requestCancelled(
              requestOptions: RequestOptions(path: url),
              reason: 'Cancelled',
            );
          }
          await controller.checkPause();
          if (totalLen > 0) {
            onProgress?.call(count / totalLen);
          }
        },
        cancelToken: CancelToken(),
      );

      if (controller.isCancelled) {
        if (await tempFile.exists()) await tempFile.delete();
        throw Exception('已取消');
      }

      final existingFile = File(outPath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }
      await tempFile.rename(outPath);
      return outPath;
    } catch (e) {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }
}
