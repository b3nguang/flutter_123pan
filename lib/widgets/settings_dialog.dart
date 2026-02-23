import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/app_config.dart';
import '../providers/settings_provider.dart';
import '../screens/home_screen.dart' show isMobile;

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    if (isMobile(context)) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const _SettingsSheet(),
      );
    }
    return showDialog(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _pathCtrl;
  late bool _askLocation;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _pathCtrl = TextEditingController(text: settings.defaultDownloadPath);
    _askLocation = settings.askDownloadLocation;
  }

  @override
  void dispose() {
    _pathCtrl.dispose();
    super.dispose();
  }

  Future<void> _browsePath() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择默认下载路径',
      initialDirectory: _pathCtrl.text,
    );
    if (result != null) {
      setState(() => _pathCtrl.text = result);
    }
  }

  Future<void> _save() async {
    final provider = context.read<SettingsProvider>();
    await provider.updateSettings(AppSettings(
      defaultDownloadPath: _pathCtrl.text.trim(),
      askDownloadLocation: _askLocation,
    ));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已保存'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('下载设置', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: '默认下载路径',
                      prefixIcon: Icon(Icons.folder_outlined, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _browsePath,
                  child: const Text('浏览...'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _askLocation,
              onChanged: (v) => setState(() => _askLocation = v ?? true),
              title: const Text('每次下载前询问保存位置'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

// ── Mobile bottom sheet ───────────────────────────────────────────────────────
class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late TextEditingController _pathCtrl;
  late bool _askLocation;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _pathCtrl = TextEditingController(text: settings.defaultDownloadPath);
    _askLocation = settings.askDownloadLocation;
  }

  @override
  void dispose() {
    _pathCtrl.dispose();
    super.dispose();
  }

  Future<void> _browsePath() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择默认下载路径',
      initialDirectory: _pathCtrl.text,
    );
    if (result != null) setState(() => _pathCtrl.text = result);
  }

  Future<void> _save() async {
    final provider = context.read<SettingsProvider>();
    await provider.updateSettings(AppSettings(
      defaultDownloadPath: _pathCtrl.text.trim(),
      askDownloadLocation: _askLocation,
    ));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('设置已保存'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('设置',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('下载设置',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pathCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '默认下载路径',
                    prefixIcon: Icon(Icons.folder_outlined, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                  onPressed: _browsePath, child: const Text('浏览...')),
            ],
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _askLocation,
            onChanged: (v) => setState(() => _askLocation = v ?? true),
            title: const Text('每次下载前询问保存位置'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _save, child: const Text('保存')),
            ],
          ),
        ],
      ),
    );
  }
}
