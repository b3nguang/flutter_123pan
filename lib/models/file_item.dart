class FileItem {
  final int fileId;
  final String fileName;
  final int type; // 0=file, 1=folder
  final int size;
  final String etag;
  final String s3KeyFlag;
  final String absPath;
  final String? downloadUrl;

  const FileItem({
    required this.fileId,
    required this.fileName,
    required this.type,
    required this.size,
    required this.etag,
    required this.s3KeyFlag,
    required this.absPath,
    this.downloadUrl,
  });

  bool get isFolder => type == 1;

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      fileId: json['FileId'] is int
          ? json['FileId'] as int
          : int.tryParse(json['FileId'].toString()) ?? 0,
      fileName: json['FileName'] as String? ?? '',
      type: json['Type'] as int? ?? 0,
      size: json['Size'] is int
          ? json['Size'] as int
          : int.tryParse(json['Size'].toString()) ?? 0,
      etag: json['Etag'] as String? ?? '',
      s3KeyFlag: json['S3KeyFlag'] as String? ?? '',
      absPath: json['AbsPath'] as String? ?? '',
      downloadUrl: json['DownloadUrl'] as String?,
    );
  }

  String get formattedSize {
    if (isFolder) return '-';
    if (size >= 1073741824) return '${(size / 1073741824).toStringAsFixed(2)} GB';
    if (size >= 1048576) return '${(size / 1048576).toStringAsFixed(2)} MB';
    if (size >= 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    return '$size B';
  }
}
