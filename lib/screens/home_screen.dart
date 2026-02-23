import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/files_page.dart';
import '../pages/transfer_page.dart';
import '../providers/auth_provider.dart';
import '../providers/transfer_provider.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/about_dialog.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [FilesPage(), TransferPage()];

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true), child: const Text('退出')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? CatppuccinMocha.mantle : CatppuccinLatte.mantle;
    final authProvider = context.watch<AuthProvider>();
    final transferProvider = context.watch<TransferProvider>();

    final runningCount =
        transferProvider.tasks.where((t) => t.status.index <= 2).length;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 200,
            color: sidebarBg,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_outlined,
                          size: 26,
                          color: isDark ? CatppuccinMocha.blue : CatppuccinLatte.blue),
                      const SizedBox(width: 8),
                      Text(
                        '123云盘',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? CatppuccinMocha.blue : CatppuccinLatte.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                if (authProvider.userName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.account_circle_outlined,
                            size: 14,
                            color: isDark
                                ? CatppuccinMocha.subtext0
                                : CatppuccinLatte.subtext0),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            authProvider.userName,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? CatppuccinMocha.subtext0
                                  : CatppuccinLatte.subtext0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Divider(
                  height: 1,
                  color: isDark ? CatppuccinMocha.surface1 : CatppuccinLatte.surface0,
                ),
                const SizedBox(height: 12),
                _SidebarNavItem(
                  icon: Icons.folder_rounded,
                  label: '文件',
                  selected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                  isDark: isDark,
                ),
                const SizedBox(height: 6),
                _SidebarNavItem(
                  icon: Icons.swap_vert_rounded,
                  label: '传输',
                  selected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                  isDark: isDark,
                  badge: runningCount > 0 ? runningCount.toString() : null,
                ),
                const Spacer(),
                Divider(
                  height: 1,
                  color: isDark ? CatppuccinMocha.surface1 : CatppuccinLatte.surface0,
                ),
                _SidebarIconBtn(
                    icon: Icons.settings_outlined,
                    tooltip: '设置',
                    onTap: () => SettingsDialog.show(context),
                    isDark: isDark),
                _SidebarIconBtn(
                    icon: Icons.info_outline_rounded,
                    tooltip: '关于',
                    onTap: () => AppAboutDialog.show(context),
                    isDark: isDark),
                _SidebarIconBtn(
                    icon: Icons.logout_rounded,
                    tooltip: '退出登录',
                    onTap: _logout,
                    isDark: isDark),
                const SizedBox(height: 12),
              ],
            ),
          ),
          VerticalDivider(
            width: 1,
            color: isDark ? CatppuccinMocha.surface1 : CatppuccinLatte.surface0,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final String? badge;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? CatppuccinMocha.blue : CatppuccinLatte.blue;
    final bg = selected
        ? (isDark
            ? CatppuccinMocha.blue.withValues(alpha: 0.18)
            : CatppuccinLatte.blue.withValues(alpha: 0.12))
        : Colors.transparent;
    final fg = selected
        ? accent
        : (isDark ? CatppuccinMocha.subtext1 : CatppuccinLatte.subtext1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDark;

  const _SidebarIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? CatppuccinMocha.subtext0 : CatppuccinLatte.subtext0;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 10),
              Text(tooltip, style: TextStyle(color: fg, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
