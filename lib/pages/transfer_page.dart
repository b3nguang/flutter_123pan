import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transfer_task.dart';
import '../providers/transfer_provider.dart';
import '../theme/app_colors.dart';
import '../screens/home_screen.dart' show isMobile;

class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mobile = isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, mobile ? 10 : 16, 16, 8),
          child: Row(
            children: [
              if (!mobile)
                Text('传输任务', style: Theme.of(context).textTheme.titleLarge),
              if (!mobile) const Spacer(),
              if (mobile) const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('清除已完成', style: TextStyle(fontSize: 13)),
                onPressed: () => context.read<TransferProvider>().clearCompleted(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        if (!mobile) ...[
          Container(
            color: isDark ? CatppuccinMocha.mantle : CatppuccinLatte.mantle,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text('类型',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? CatppuccinMocha.subtext1 : CatppuccinLatte.subtext1)),
                ),
                Expanded(
                  flex: 4,
                  child: Text('文件名',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? CatppuccinMocha.subtext1 : CatppuccinLatte.subtext1)),
                ),
                SizedBox(
                  width: 90,
                  child: Text('大小',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? CatppuccinMocha.subtext1 : CatppuccinLatte.subtext1)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('进度',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? CatppuccinMocha.subtext1 : CatppuccinLatte.subtext1)),
                ),
                SizedBox(
                  width: 80,
                  child: Text('状态',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? CatppuccinMocha.subtext1 : CatppuccinLatte.subtext1)),
                ),
                const SizedBox(width: 120),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: Consumer<TransferProvider>(
            builder: (_, provider, _) {
              final tasks = provider.tasks;
              if (tasks.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_vert_rounded, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('暂无传输任务', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              if (mobile) {
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: tasks.length,
                  itemBuilder: (ctx, i) => _TransferTaskCard(
                    task: tasks[i],
                    provider: provider,
                  ),
                );
              }
              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (ctx, i) => _TransferTaskRow(
                  task: tasks[i],
                  provider: provider,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TransferTaskRow extends StatelessWidget {
  final TransferTask task;
  final TransferProvider provider;

  const _TransferTaskRow({required this.task, required this.provider});

  Color _statusColor(BuildContext context, TransferStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case TransferStatus.completed:
        return isDark ? CatppuccinMocha.green : CatppuccinLatte.green;
      case TransferStatus.failed:
        return isDark ? CatppuccinMocha.red : CatppuccinLatte.red;
      case TransferStatus.cancelled:
        return isDark ? CatppuccinMocha.overlay0 : CatppuccinLatte.overlay0;
      case TransferStatus.paused:
        return isDark ? CatppuccinMocha.yellow : CatppuccinLatte.yellow;
      default:
        return isDark ? CatppuccinMocha.blue : CatppuccinLatte.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = task.status == TransferStatus.running ||
        task.status == TransferStatus.paused ||
        task.status == TransferStatus.waiting;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Chip(
              label: Text(
                task.typeLabel,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              backgroundColor: task.type == TransferType.download
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
              side: BorderSide.none,
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  task.fileName,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.errorMessage != null)
                  Text(
                    task.errorMessage!,
                    style: TextStyle(
                        fontSize: 11, color: Theme.of(context).colorScheme.error),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(task.formattedSize, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: task.status == TransferStatus.running ||
                    task.status == TransferStatus.paused
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(
                        value: task.progress,
                        backgroundColor:
                            Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${(task.progress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  )
                : task.status == TransferStatus.completed
                    ? LinearProgressIndicator(
                        value: 1.0,
                        color: _statusColor(context, task.status),
                        backgroundColor:
                            Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      )
                    : const SizedBox.shrink(),
          ),
          SizedBox(
            width: 80,
            child: Text(
              task.statusLabel,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _statusColor(context, task.status)),
            ),
          ),
          SizedBox(
            width: 120,
            child: isActive
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (task.status == TransferStatus.running ||
                          task.status == TransferStatus.waiting)
                        TextButton(
                          onPressed: () => provider.pauseTask(task.id),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('暂停', style: TextStyle(fontSize: 12)),
                        )
                      else if (task.status == TransferStatus.paused)
                        TextButton(
                          onPressed: () => provider.resumeTask(task.id),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('恢复', style: TextStyle(fontSize: 12)),
                        ),
                      TextButton(
                        onPressed: () => provider.cancelTask(task.id),
                        style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('取消', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  )
                : TextButton(
                    onPressed: () => provider.removeTask(task.id),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('移除', style: TextStyle(fontSize: 12)),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile Card row ───────────────────────────────────────────────────────────
class _TransferTaskCard extends StatelessWidget {
  final TransferTask task;
  final TransferProvider provider;

  const _TransferTaskCard({required this.task, required this.provider});

  Color _statusColor(BuildContext context, TransferStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case TransferStatus.completed:
        return isDark ? CatppuccinMocha.green : CatppuccinLatte.green;
      case TransferStatus.failed:
        return isDark ? CatppuccinMocha.red : CatppuccinLatte.red;
      case TransferStatus.cancelled:
        return isDark ? CatppuccinMocha.overlay0 : CatppuccinLatte.overlay0;
      case TransferStatus.paused:
        return isDark ? CatppuccinMocha.yellow : CatppuccinLatte.yellow;
      default:
        return isDark ? CatppuccinMocha.blue : CatppuccinLatte.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = task.status == TransferStatus.running ||
        task.status == TransferStatus.paused ||
        task.status == TransferStatus.waiting;
    final statusColor = _statusColor(context, task.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(
                    task.typeLabel,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: task.type == TransferType.download
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15)
                      : Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.15),
                  side: BorderSide.none,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.fileName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  task.statusLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
                ),
              ],
            ),
            if (task.errorMessage != null) ...[
              const SizedBox(height: 2),
              Text(
                task.errorMessage!,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.error),
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (task.status == TransferStatus.running ||
                task.status == TransferStatus.paused ||
                task.status == TransferStatus.completed) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: task.status == TransferStatus.completed
                    ? 1.0
                    : task.progress,
                color: statusColor,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    task.formattedSize,
                    style: const TextStyle(fontSize: 11),
                  ),
                  const Spacer(),
                  if (task.status == TransferStatus.running ||
                      task.status == TransferStatus.paused)
                    Text(
                      '${(task.progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 11),
                    ),
                ],
              ),
            ],
            if (isActive || !isActive) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (task.status == TransferStatus.running ||
                      task.status == TransferStatus.waiting)
                    TextButton(
                      onPressed: () => provider.pauseTask(task.id),
                      style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('暂停', style: TextStyle(fontSize: 12)),
                    )
                  else if (task.status == TransferStatus.paused)
                    TextButton(
                      onPressed: () => provider.resumeTask(task.id),
                      style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('恢复', style: TextStyle(fontSize: 12)),
                    ),
                  if (isActive)
                    TextButton(
                      onPressed: () => provider.cancelTask(task.id),
                      style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.error,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('取消', style: TextStyle(fontSize: 12)),
                    )
                  else
                    TextButton(
                      onPressed: () => provider.removeTask(task.id),
                      style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('移除', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
