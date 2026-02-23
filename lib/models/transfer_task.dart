import 'package:flutter/foundation.dart';

enum TransferType { download, upload }

enum TransferStatus { waiting, running, paused, completed, failed, cancelled }

class TransferTask {
  final int id;
  final TransferType type;
  final String fileName;
  final int fileSize;
  double progress;
  TransferStatus status;
  String? errorMessage;

  TransferTask({
    required this.id,
    required this.type,
    required this.fileName,
    required this.fileSize,
    this.progress = 0.0,
    this.status = TransferStatus.waiting,
    this.errorMessage,
  });

  String get typeLabel => type == TransferType.download ? '下载' : '上传';

  String get statusLabel {
    switch (status) {
      case TransferStatus.waiting:
        return '等待中';
      case TransferStatus.running:
        return type == TransferType.download ? '下载中' : '上传中';
      case TransferStatus.paused:
        return '已暂停';
      case TransferStatus.completed:
        return '已完成';
      case TransferStatus.failed:
        return '失败';
      case TransferStatus.cancelled:
        return '已取消';
    }
  }

  String get formattedSize {
    if (fileSize >= 1073741824) return '${(fileSize / 1073741824).toStringAsFixed(2)} GB';
    if (fileSize >= 1048576) return '${(fileSize / 1048576).toStringAsFixed(2)} MB';
    if (fileSize >= 1024) return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    return '$fileSize B';
  }
}

class TransferController {
  bool _cancelled = false;
  bool _paused = false;
  VoidCallback? onPause;
  VoidCallback? onResume;
  VoidCallback? onCancel;

  bool get isCancelled => _cancelled;
  bool get isPaused => _paused;

  void cancel() {
    _cancelled = true;
    _paused = false;
    onCancel?.call();
  }

  void pause() {
    _paused = true;
    onPause?.call();
  }

  void resume() {
    _paused = false;
    onResume?.call();
  }

  Future<void> checkPause() async {
    while (_paused && !_cancelled) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }
}
