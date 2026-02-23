import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../providers/file_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transfer_provider.dart';
import '../services/api_service.dart';
import '../widgets/breadcrumb_bar.dart';
import '../widgets/file_icon.dart';
import '../widgets/link_dialog.dart';
import '../widgets/share_dialog.dart';
import '../theme/app_colors.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  final Set<int> _selected = {};
  bool _isDragOver = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileProvider>().loadFiles(reset: true);
    });
  }

  FileItem? get _singleSelected {
    if (_selected.length != 1) return null;
    final files = context.read<FileProvider>().files;
    final idx = _selected.first;
    if (idx < files.length) return files[idx];
    return null;
  }

  Future<String?> _askDownloadPath(String fileName) async {
    final settings = context.read<SettingsProvider>().settings;
    if (!settings.askDownloadLocation) {
      return settings.defaultDownloadPath;
    }
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择下载保存位置',
      initialDirectory: settings.defaultDownloadPath,
    );
    return result;
  }

  Future<void> _download(FileItem file) async {
    final savePath = await _askDownloadPath(file.fileName);
    if (savePath == null || !mounted) return;
    final transfer = context.read<TransferProvider>();
    await transfer.addDownload(file: file, savePath: savePath);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加下载任务：${file.fileName}'), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<void> _showLink(FileItem file) async {
    try {
      final api = context.read<ApiService>();
      final url = await api.getDownloadLink(file);
      if (mounted) await LinkDialog.show(context, url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取链接失败：$e'), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _delete(FileItem file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确认将 "${file.fileName}" 移入回收站？'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final api = context.read<ApiService>();
      await api.deleteFile(file);
      if (mounted) {
        context.read<FileProvider>().loadFiles(reset: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e'), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _share(FileItem file) async {
    await ShareDialog.show(context, file);
  }

  Future<void> _mkdir() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '文件夹名称'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('创建')),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    try {
      final api = context.read<ApiService>();
      final fileProvider = context.read<FileProvider>();
      await api.mkdir(name.trim(), fileProvider.currentFolderId);
      fileProvider.loadFiles(reset: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败：$e'), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _uploadFiles(List<String> paths) async {
    final fileProvider = context.read<FileProvider>();
    final transfer = context.read<TransferProvider>();
    for (final path in paths) {
      final file = File(path);
      if (!await file.exists()) continue;
      final fileName = file.uri.pathSegments.last;
      final existing = fileProvider.files.where((f) => f.fileName == fileName).toList();
      int duplicate = 0;
      if (existing.isNotEmpty && mounted) {
        final choice = await showDialog<int>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('同名文件'),
            content: Text('检测到同名文件：$fileName\n请选择处理方式：'),
            actions: [
              OutlinedButton(onPressed: () => Navigator.pop(context, 0), child: const Text('取消')),
              OutlinedButton(onPressed: () => Navigator.pop(context, 1), child: const Text('覆盖')),
              FilledButton(onPressed: () => Navigator.pop(context, 2), child: const Text('保留两者')),
            ],
          ),
        );
        if (choice == null || choice == 0) continue;
        duplicate = choice;
      }
      await transfer.addUpload(
        filePath: path,
        parentFileId: fileProvider.currentFolderId,
        duplicate: duplicate,
        onComplete: () {
          if (mounted) fileProvider.loadFiles(reset: true);
        },
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加上传任务'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      dialogTitle: '选择要上传的文件',
    );
    if (result == null || !mounted) return;
    final paths = result.paths.whereType<String>().toList();
    if (paths.isNotEmpty) await _uploadFiles(paths);
  }

  void _showContextMenu(BuildContext context, FileItem file, Offset position) {
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: <PopupMenuEntry<void>>[
        if (!file.isFolder)
          PopupMenuItem<void>(
            child: const ListTile(leading: Icon(Icons.download_rounded), title: Text('下载')),
            onTap: () => _download(file),
          ),
        if (!file.isFolder)
          PopupMenuItem<void>(
            child: const ListTile(leading: Icon(Icons.link_rounded), title: Text('显示链接')),
            onTap: () => _showLink(file),
          ),
        PopupMenuItem<void>(
          child: const ListTile(leading: Icon(Icons.share_rounded), title: Text('分享')),
          onTap: () => _share(file),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<void>(
          child: ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
            title: Text('删除', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          onTap: () => _delete(file),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fileProvider = context.watch<FileProvider>();
    final files = fileProvider.files;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(context, fileProvider),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.folder_open_rounded, size: 16),
              const SizedBox(width: 6),
              Expanded(child: BreadcrumbBar()),
              if (fileProvider.totalFiles > 0)
                Text(
                  '共 ${files.length}${fileProvider.hasMore ? '+' : ''} / ${fileProvider.totalFiles} 项',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: DropTarget(
            onDragDone: (detail) {
              final paths = detail.files
                  .where((f) => File(f.path).existsSync())
                  .map((f) => f.path)
                  .toList();
              if (paths.isNotEmpty) _uploadFiles(paths);
              setState(() => _isDragOver = false);
            },
            onDragEntered: (_) => setState(() => _isDragOver = true),
            onDragExited: (_) => setState(() => _isDragOver = false),
            child: _buildFileList(context, fileProvider, files, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, FileProvider fileProvider) {
    final hasSelection = _selected.isNotEmpty;
    final singleFile = _singleSelected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _toolBtn(
            icon: Icons.refresh_rounded,
            label: '刷新',
            onPressed: () {
              _selected.clear();
              fileProvider.loadFiles(reset: true);
            },
          ),
          _toolBtn(
            icon: Icons.expand_more_rounded,
            label: '加载更多',
            onPressed: fileProvider.hasMore
                ? () => fileProvider.loadFiles(reset: false)
                : null,
          ),
          _toolBtn(
            icon: Icons.arrow_upward_rounded,
            label: '上级',
            onPressed: fileProvider.isRoot
                ? null
                : () {
                    _selected.clear();
                    fileProvider.goUp();
                  },
          ),
          const SizedBox(width: 4),
          _toolBtn(
            icon: Icons.download_rounded,
            label: '下载',
            onPressed: hasSelection && singleFile != null
                ? () => _download(singleFile)
                : null,
          ),
          _toolBtn(
            icon: Icons.upload_file_rounded,
            label: '上传文件',
            onPressed: _pickAndUpload,
          ),
          _toolBtn(
            icon: Icons.create_new_folder_rounded,
            label: '新建文件夹',
            onPressed: _mkdir,
          ),
          _toolBtn(
            icon: Icons.link_rounded,
            label: '显示链接',
            onPressed: hasSelection && singleFile != null && !singleFile.isFolder
                ? () => _showLink(singleFile)
                : null,
          ),
          _toolBtn(
            icon: Icons.share_rounded,
            label: '分享',
            onPressed: hasSelection && singleFile != null
                ? () => _share(singleFile)
                : null,
          ),
          _toolBtn(
            icon: Icons.delete_outline_rounded,
            label: '删除',
            color: Theme.of(context).colorScheme.error,
            onPressed: hasSelection && singleFile != null
                ? () => _delete(singleFile)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _toolBtn({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16, color: onPressed == null ? null : color),
      label: Text(label, style: TextStyle(color: onPressed == null ? null : color, fontSize: 13)),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildFileList(
    BuildContext context,
    FileProvider fileProvider,
    List<FileItem> files,
    bool isDark,
  ) {
    if (fileProvider.state == FileLoadState.loading && files.isEmpty) {
      return const Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在加载...'),
        ],
      ));
    }

    if (fileProvider.state == FileLoadState.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(fileProvider.errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => fileProvider.loadFiles(reset: true),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (files.isEmpty && fileProvider.state == FileLoadState.loaded) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('此文件夹为空', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final dropOverlay = _isDragOver
        ? Container(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_upload_rounded,
                      size: 56, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('松开以上传文件',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          )
        : null;

    return Stack(
      children: [
        Column(
          children: [
            _buildTableHeader(context),
            Expanded(
              child: ListView.builder(
                itemCount: files.length + (fileProvider.state == FileLoadState.loading ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == files.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final file = files[i];
                  final isSelected = _selected.contains(i);
                  return _buildFileRow(context, file, i, isSelected, isDark);
                },
              ),
            ),
          ],
        ),
        if (dropOverlay case final overlay?) overlay,
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? CatppuccinMocha.mantle : CatppuccinLatte.mantle;
    final headerText = isDark ? CatppuccinMocha.subtext1 : CatppuccinLatte.subtext1;

    return Container(
      color: headerBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 32),
          Expanded(
            flex: 5,
            child: Text('名称', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: headerText)),
          ),
          SizedBox(
            width: 80,
            child: Text('类型', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: headerText)),
          ),
          SizedBox(
            width: 100,
            child: Text('大小', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: headerText)),
          ),
        ],
      ),
    );
  }

  Widget _buildFileRow(
    BuildContext context,
    FileItem file,
    int index,
    bool isSelected,
    bool isDark,
  ) {
    final selectedBg = isDark
        ? CatppuccinMocha.blue.withValues(alpha: 0.2)
        : CatppuccinLatte.blue.withValues(alpha: 0.12);

    return GestureDetector(
      onSecondaryTapUp: (details) => _showContextMenu(context, file, details.globalPosition),
      child: InkWell(
        onTap: () => setState(() {
          if (isSelected) {
            _selected.remove(index);
          } else {
            _selected.clear();
            _selected.add(index);
          }
        }),
        onDoubleTap: () {
          if (file.isFolder) {
            _selected.clear();
            context.read<FileProvider>().enterFolder(file);
          } else {
            _download(file);
          }
        },
        child: Container(
          color: isSelected ? selectedBg : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              FileIconWidget(file: file, size: 22),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Text(
                  file.fileName,
                  style: TextStyle(
                    fontWeight: file.isFolder ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  file.isFolder ? '文件夹' : '文件',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  file.formattedSize,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
