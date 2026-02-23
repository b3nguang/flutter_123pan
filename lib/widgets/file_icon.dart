import 'package:flutter/material.dart';
import '../models/file_item.dart';

class FileIconWidget extends StatelessWidget {
  final FileItem file;
  final double size;

  const FileIconWidget({super.key, required this.file, this.size = 24});

  @override
  Widget build(BuildContext context) {
    if (file.isFolder) {
      return Icon(Icons.folder_rounded, color: const Color(0xFFFFC107), size: size);
    }
    final ext = _getExt(file.fileName);
    final (icon, color) = _iconForExt(ext);
    return Icon(icon, color: color, size: size);
  }

  String _getExt(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  (IconData, Color) _iconForExt(String ext) {
    switch (ext) {
      case 'pdf':
        return (Icons.picture_as_pdf_rounded, const Color(0xFFEF5350));
      case 'doc':
      case 'docx':
        return (Icons.description_rounded, const Color(0xFF2196F3));
      case 'xls':
      case 'xlsx':
        return (Icons.table_chart_rounded, const Color(0xFF4CAF50));
      case 'ppt':
      case 'pptx':
        return (Icons.slideshow_rounded, const Color(0xFFFF9800));
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
        return (Icons.image_rounded, const Color(0xFF9C27B0));
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
      case 'flv':
        return (Icons.video_file_rounded, const Color(0xFFE91E63));
      case 'mp3':
      case 'flac':
      case 'wav':
      case 'aac':
      case 'ogg':
        return (Icons.audio_file_rounded, const Color(0xFF673AB7));
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return (Icons.folder_zip_rounded, const Color(0xFF795548));
      case 'txt':
      case 'md':
        return (Icons.text_snippet_rounded, const Color(0xFF1976D2));
      case 'dart':
      case 'py':
      case 'js':
      case 'ts':
      case 'java':
      case 'cpp':
      case 'c':
      case 'go':
      case 'rs':
        return (Icons.code_rounded, const Color(0xFF00BCD4));
      case 'apk':
        return (Icons.android_rounded, const Color(0xFF4CAF50));
      case 'exe':
      case 'msi':
        return (Icons.window_rounded, const Color(0xFF2196F3));
      case 'iso':
      case 'img':
        return (Icons.disc_full_rounded, const Color(0xFF607D8B));
      default:
        return (Icons.insert_drive_file_rounded, const Color(0xFF78909C));
    }
  }
}
