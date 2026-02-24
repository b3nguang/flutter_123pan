import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_config.dart';
import '../providers/webdav_provider.dart';
import '../screens/home_screen.dart' show isMobile;

class WebDavDialog extends StatefulWidget {
  const WebDavDialog({super.key});

  static Future<void> show(BuildContext context) {
    if (isMobile(context)) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<WebDavProvider>(),
          child: const _WebDavSheet(),
        ),
      );
    }
    return showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<WebDavProvider>(),
        child: const WebDavDialog(),
      ),
    );
  }

  @override
  State<WebDavDialog> createState() => _WebDavDialogState();
}

class _WebDavDialogState extends State<WebDavDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('WebDAV 服务'),
      content: SizedBox(
        width: 480,
        child: _WebDavForm(onSaved: () => Navigator.pop(context)),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

// ── Mobile bottom sheet ───────────────────────────────────────────────────────

class _WebDavSheet extends StatelessWidget {
  const _WebDavSheet();

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
          Text(
            'WebDAV 服务',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _WebDavForm(onSaved: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

// ── Shared form ───────────────────────────────────────────────────────────────

class _WebDavForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _WebDavForm({required this.onSaved});

  @override
  State<_WebDavForm> createState() => _WebDavFormState();
}

class _WebDavFormState extends State<_WebDavForm> {
  late TextEditingController _portCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _pwdCtrl;
  late TextEditingController _baseCtrl;
  bool _obscurePwd = true;

  @override
  void initState() {
    super.initState();
    final cfg = context.read<WebDavProvider>().config;
    _portCtrl = TextEditingController(text: cfg.port.toString());
    _userCtrl = TextEditingController(text: cfg.username);
    _pwdCtrl = TextEditingController(text: cfg.password);
    _baseCtrl = TextEditingController(text: cfg.basePath);
  }

  @override
  void dispose() {
    _portCtrl.dispose();
    _userCtrl.dispose();
    _pwdCtrl.dispose();
    _baseCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndApply() async {
    final provider = context.read<WebDavProvider>();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 8090;
    final cfg = WebDavConfig(
      enabled: provider.config.enabled,
      port: port,
      username: _userCtrl.text.trim(),
      password: _pwdCtrl.text,
      basePath: _baseCtrl.text.trim().isEmpty ? '/dav' : _baseCtrl.text.trim(),
    );
    await provider.saveConfig(cfg);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('配置已保存'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _toggle() async {
    await _saveAndApply();
    if (!mounted) return;
    await context.read<WebDavProvider>().toggle();
  }

  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制地址'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WebDavProvider>();
    final isRunning = provider.isRunning;
    final isStarting = provider.state == WebDavState.starting;
    final url = provider.serverUrl;
    final accent = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRunning
                      ? Colors.green
                      : isStarting
                          ? Colors.orange
                          : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isRunning
                    ? '运行中  ·  端口 ${provider.port}'
                    : isStarting
                        ? '启动中...'
                        : '已停止',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isRunning ? Colors.green : null,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: isStarting ? null : _toggle,
                icon: Icon(isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 18),
                label: Text(isRunning ? '停止' : '启动'),
                style: FilledButton.styleFrom(
                  backgroundColor: isRunning ? Colors.red.shade600 : accent,
                ),
              ),
            ],
          ),

          // Error message
          if (provider.state == WebDavState.error) ...[
            const SizedBox(height: 8),
            Text(
              provider.errorMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ],

          // Connection URL
          if (isRunning && url.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: '复制地址',
                    onPressed: () => _copyUrl(url),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text('服务配置', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),

          // Port
          TextField(
            controller: _portCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '端口',
              hintText: '8090',
              prefixIcon: Icon(Icons.lan_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 10),

          // Base path
          TextField(
            controller: _baseCtrl,
            decoration: const InputDecoration(
              labelText: 'Base Path',
              hintText: '/dav',
              prefixIcon: Icon(Icons.link_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          const Text('鉴权（留空则不验证）',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 12),

          // Username
          TextField(
            controller: _userCtrl,
            decoration: const InputDecoration(
              labelText: '用户名',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 10),

          // Password
          TextField(
            controller: _pwdCtrl,
            obscureText: _obscurePwd,
            decoration: InputDecoration(
              labelText: '密码',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePwd ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _saveAndApply,
              child: const Text('保存配置'),
            ),
          ),
        ],
      ),
    );
  }
}
