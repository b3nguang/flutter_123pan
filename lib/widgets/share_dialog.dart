import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/api_service.dart';

class ShareDialog extends StatefulWidget {
  final FileItem file;

  const ShareDialog({super.key, required this.file});

  static Future<void> show(BuildContext context, FileItem file) {
    return showDialog(
      context: context,
      builder: (_) => ShareDialog(file: file),
    );
  }

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  String? _shareUrl;
  String? _error;

  @override
  void dispose() {
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _doShare() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final url = await api.shareFile(widget.file.fileId, sharePwd: _pwdCtrl.text.trim());
      setState(() {
        _shareUrl = url;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('分享 "${widget.file.fileName}"'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _pwdCtrl,
              decoration: const InputDecoration(
                labelText: '提取码（留空则无提取码）',
                prefixIcon: Icon(Icons.lock_outline, size: 18),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
            ],
            if (_shareUrl != null) ...[
              const SizedBox(height: 16),
              const Text('分享链接：', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SelectableText(
                _shareUrl!,
                style: const TextStyle(fontSize: 13, fontFamily: 'Consolas'),
              ),
              if (_pwdCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('提取码：${_pwdCtrl.text}', style: const TextStyle(fontSize: 13)),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (_shareUrl != null)
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('复制链接'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _shareUrl!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('链接已复制'), duration: Duration(seconds: 2)),
              );
            },
          ),
        if (_shareUrl == null)
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        if (_shareUrl == null)
          FilledButton(
            onPressed: _loading ? null : _doShare,
            child: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('创建分享'),
          ),
        if (_shareUrl != null)
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
      ],
    );
  }
}
