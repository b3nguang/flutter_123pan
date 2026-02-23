import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/transfer_task.dart';
import '../models/file_item.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/upload_service.dart';

class TransferProvider extends ChangeNotifier {
  final ApiService apiService;
  final DownloadService downloadService;
  final UploadService uploadService;

  final List<TransferTask> _tasks = [];
  final Map<int, TransferController> _controllers = {};
  int _nextId = 0;

  TransferProvider({
    required this.apiService,
    required this.downloadService,
    required this.uploadService,
  });

  List<TransferTask> get tasks => List.unmodifiable(_tasks);

  Future<void> addDownload({
    required FileItem file,
    required String savePath,
  }) async {
    final id = _nextId++;
    final task = TransferTask(
      id: id,
      type: TransferType.download,
      fileName: file.isFolder ? '${file.fileName}.zip' : file.fileName,
      fileSize: file.size,
    );
    final controller = TransferController();
    _tasks.add(task);
    _controllers[id] = controller;
    notifyListeners();

    _runDownload(task, file, savePath, controller);
  }

  void _runDownload(
    TransferTask task,
    FileItem file,
    String savePath,
    TransferController controller,
  ) async {
    task.status = TransferStatus.running;
    notifyListeners();

    try {
      final url = await apiService.getDownloadLink(file);
      await downloadService.download(
        url: url,
        savePath: savePath,
        fileName: task.fileName,
        controller: controller,
        onProgress: (p) {
          task.progress = p;
          notifyListeners();
        },
      );
      if (controller.isCancelled) {
        task.status = TransferStatus.cancelled;
      } else {
        task.status = TransferStatus.completed;
        task.progress = 1.0;
      }
    } catch (e) {
      if (controller.isCancelled) {
        task.status = TransferStatus.cancelled;
      } else {
        task.status = TransferStatus.failed;
        task.errorMessage = e.toString();
      }
    }
    notifyListeners();
  }

  Future<void> addUpload({
    required String filePath,
    required int parentFileId,
    required int duplicate,
    void Function()? onComplete,
  }) async {
    final id = _nextId++;
    final parts = filePath.replaceAll('\\', '/').split('/');
    final fileName = parts.last;
    int fileSize = 0;
    try {
      final f = await _getFileSize(filePath);
      fileSize = f;
    } catch (_) {}

    final task = TransferTask(
      id: id,
      type: TransferType.upload,
      fileName: fileName,
      fileSize: fileSize,
    );
    final controller = TransferController();
    _tasks.add(task);
    _controllers[id] = controller;
    notifyListeners();

    _runUpload(task, filePath, parentFileId, duplicate, controller, onComplete);
  }

  void _runUpload(
    TransferTask task,
    String filePath,
    int parentFileId,
    int duplicate,
    TransferController controller,
    void Function()? onComplete,
  ) async {
    task.status = TransferStatus.running;
    notifyListeners();

    try {
      await uploadService.upload(
        filePath: filePath,
        parentFileId: parentFileId,
        duplicate: duplicate,
        controller: controller,
        onProgress: (p) {
          task.progress = p;
          notifyListeners();
        },
      );
      if (controller.isCancelled) {
        task.status = TransferStatus.cancelled;
      } else {
        task.status = TransferStatus.completed;
        task.progress = 1.0;
        onComplete?.call();
      }
    } catch (e) {
      if (controller.isCancelled) {
        task.status = TransferStatus.cancelled;
      } else {
        task.status = TransferStatus.failed;
        task.errorMessage = e.toString();
      }
    }
    notifyListeners();
  }

  void pauseTask(int id) {
    final controller = _controllers[id];
    final task = _tasks.firstWhere((t) => t.id == id, orElse: () => throw Exception());
    if (controller != null && task.status == TransferStatus.running) {
      controller.pause();
      task.status = TransferStatus.paused;
      notifyListeners();
    }
  }

  void resumeTask(int id) {
    final controller = _controllers[id];
    final task = _tasks.firstWhere((t) => t.id == id, orElse: () => throw Exception());
    if (controller != null && task.status == TransferStatus.paused) {
      controller.resume();
      task.status = TransferStatus.running;
      notifyListeners();
    }
  }

  void cancelTask(int id) {
    final controller = _controllers[id];
    final task = _tasks.firstWhere((t) => t.id == id, orElse: () => throw Exception());
    if (controller != null) {
      controller.cancel();
      task.status = TransferStatus.cancelled;
      notifyListeners();
    }
  }

  void removeTask(int id) {
    _controllers.remove(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void clearCompleted() {
    _tasks.removeWhere((t) =>
        t.status == TransferStatus.completed ||
        t.status == TransferStatus.cancelled ||
        t.status == TransferStatus.failed);
    notifyListeners();
  }

  Future<int> _getFileSize(String path) async {
    try {
      return await File(path).length();
    } catch (_) {
      return 0;
    }
  }
}
