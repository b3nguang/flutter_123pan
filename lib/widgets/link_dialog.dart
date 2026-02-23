import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LinkDialog extends StatelessWidget {
  final String url;

  const LinkDialog({super.key, required this.url});

  static Future<void> show(BuildContext context, String url) {
    return showDialog(
      context: context,
      builder: (_) => LinkDialog(url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('下载链接'),
      content: SizedBox(
        width: 600,
        child: SelectableText(
          url,
          style: const TextStyle(fontSize: 13, fontFamily: 'Consolas'),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('复制链接'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('链接已复制到剪贴板'), duration: Duration(seconds: 2)),
            );
          },
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
