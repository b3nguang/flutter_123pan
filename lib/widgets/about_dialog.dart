import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppAboutDialog extends StatelessWidget {
  const AppAboutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const AppAboutDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cloud_outlined, color: accent, size: 28),
          const SizedBox(width: 10),
          const Text('关于 123pan'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            _row('版本', 'v2.3.1 (Flutter 重构版)'),
            const SizedBox(height: 8),
            const Text(
              '123pan 是一款高效下载辅助工具，通过模拟安卓客户端协议，'
              '帮助用户绕过 123云盘 的自用下载流量限制，实现无阻碍下载体验。',
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _row('开发者', 'b3nguang'),
            const SizedBox(height: 6),
            InkWell(
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'https://github.com/b3nguang/flutter_123pan'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('GitHub 地址已复制'), duration: Duration(seconds: 2)),
                );
              },
              child: Row(
                children: [
                  const Text('GitHub：', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  Text(
                    'github.com/123panNextGen/123pan',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.copy_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _row('许可证', 'Apache License 2.0'),
            const SizedBox(height: 8),
            Text(
              '⚠️ 本工具仅用于学习研究，请勿商业使用。使用者需遵守 123云盘 用户协议。',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        Text('$label：', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
