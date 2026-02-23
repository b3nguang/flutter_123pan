import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../theme/app_colors.dart';

class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({super.key});

  @override
  Widget build(BuildContext context) {
    final fileProvider = context.watch<FileProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? CatppuccinMocha.blue : CatppuccinLatte.blue;
    final textColor = isDark ? CatppuccinMocha.subtext1 : CatppuccinLatte.subtext1;

    final pathNames = fileProvider.pathNames;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          InkWell(
            onTap: () => fileProvider.goToRoot(),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.home_rounded, size: 16, color: accent),
                  const SizedBox(width: 4),
                  Text('根目录', style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ),
          ...List.generate(pathNames.length, (i) {
            final isLast = i == pathNames.length - 1;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_right_rounded, size: 16, color: textColor),
                InkWell(
                  onTap: isLast ? null : () => fileProvider.goToIndex(i),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      pathNames[i],
                      style: TextStyle(
                        color: isLast ? (isDark ? CatppuccinMocha.text : CatppuccinLatte.text) : accent,
                        fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
