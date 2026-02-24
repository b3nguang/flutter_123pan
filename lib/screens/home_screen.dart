import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/files_page.dart';
import '../pages/transfer_page.dart';
import '../providers/auth_provider.dart';
import '../providers/transfer_provider.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/about_dialog.dart';
import '../widgets/webdav_dialog.dart';
import '../providers/webdav_provider.dart';
import '../theme/app_colors.dart';

bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < 700;

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
    final authProvider = context.watch<AuthProvider>();
    final transferProvider = context.watch<TransferProvider>();
    final runningCount =
        transferProvider.tasks.where((t) => t.status.index <= 2).length;
    final mobile = isMobile(context);

    if (mobile) {
      return _buildMobileLayout(context, isDark, authProvider, runningCount);
    }
    return _buildDesktopLayout(context, isDark, authProvider, runningCount);
  }

  // ── Desktop layout (unchanged) ──────────────────────────────────────────────
  Widget _buildDesktopLayout(
    BuildContext context,
    bool isDark,
    AuthProvider authProvider,
    int runningCount,
  ) {
    final sidebarBg = isDark ? CatppuccinMocha.mantle : CatppuccinLatte.mantle;

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
                    icon: Icons.cloud_sync_outlined,
                    tooltip: 'WebDAV',
                    onTap: () => WebDavDialog.show(context),
                    isDark: isDark,
                    badge: context.watch<WebDavProvider>().isRunning ? '●' : null),
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

  // ── Mobile layout ────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(
    BuildContext context,
    bool isDark,
    AuthProvider authProvider,
    int runningCount,
  ) {
    final accent = isDark ? CatppuccinMocha.blue : CatppuccinLatte.blue;
    final titles = ['文件', '传输'];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Icon(Icons.cloud_outlined, size: 22, color: accent),
            const SizedBox(width: 6),
            Text(
              titles[_selectedIndex],
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: accent),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              switch (v) {
                case 'webdav':
                  WebDavDialog.show(context);
                  break;
                case 'settings':
                  SettingsDialog.show(context);
                  break;
                case 'about':
                  AppAboutDialog.show(context);
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'webdav',
                child: ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: const Text('WebDAV 服务'),
                  trailing: context.watch<WebDavProvider>().isRunning
                      ? const Icon(Icons.circle, color: Colors.green, size: 10)
                      : null,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: const ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('设置'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('关于'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout_rounded,
                      color: Theme.of(context).colorScheme.error),
                  title: Text('退出登录',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: '文件',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: runningCount > 0,
              label: Text('$runningCount'),
              child: const Icon(Icons.swap_vert_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: runningCount > 0,
              label: Text('$runningCount'),
              child: const Icon(Icons.swap_vert_rounded),
            ),
            label: '传输',
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
  final String? badge;

  const _SidebarIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
    this.badge,
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: fg, size: 20),
                  if (badge != null)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Text(tooltip, style: TextStyle(color: fg, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
