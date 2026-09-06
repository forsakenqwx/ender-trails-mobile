import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/app_colors.dart';
import '../../../../shared/design_system/theme/app_typography.dart';
import '../../../../shared/design_system/widgets/pixel_app_bar.dart';
import '../../../../shared/design_system/widgets/pixel_toast.dart';

enum LogLevel { all, info, warn, error }

class LogItem {
  const LogItem({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String message;
}

/// Провайдер буфера логов приложения.
final logsProvider =
    NotifierProvider<LogsNotifier, List<LogItem>>(LogsNotifier.new);

class LogsNotifier extends Notifier<List<LogItem>> {
  @override
  List<LogItem> build() {
    return [
      LogItem(
        timestamp: DateTime.now().subtract(const Duration(seconds: 12)),
        level: LogLevel.info,
        message: 'Application booted in ${const String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev')} mode',
      ),
      LogItem(
        timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
        level: LogLevel.info,
        message: 'Sing-box core initialized',
      ),
      LogItem(
        timestamp: DateTime.now().subtract(const Duration(seconds: 5)),
        level: LogLevel.info,
        message: 'TUN interface ready (172.19.0.1/30)',
      ),
    ];
  }

  void add(LogLevel level, String message) {
    state = [
      ...state,
      LogItem(
        timestamp: DateTime.now(),
        level: level,
        message: message,
      ),
    ];
  }

  void clear() {
    state = const [];
  }
}

/// Экран логов ядра и приложения с фильтрацией по уровню.
class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  LogLevel _selectedFilter = LogLevel.all;

  Color _levelColor(LogLevel level) => switch (level) {
        LogLevel.all => AppColors.mcTextDim,
        LogLevel.info => AppColors.mcPearl,
        LogLevel.warn => AppColors.mcGold,
        LogLevel.error => AppColors.mcRedstone,
      };

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logsProvider);
    final filteredLogs = _selectedFilter == LogLevel.all
        ? logs
        : logs.where((l) => l.level == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.mcVoid,
      appBar: PixelAppBar(
        title: 'ЛОГИ ЯДРА',
        actions: [
          GestureDetector(
            onTap: () {
              final text = filteredLogs
                  .map((l) =>
                      '[${_formatTime(l.timestamp)}] [${l.level.name.toUpperCase()}] ${l.message}')
                  .join('\n');
              Clipboard.setData(ClipboardData(text: text));
              PixelToast.show(
                context,
                message: 'Логи скопированы в буфер',
                variant: PixelToastVariant.success,
              );
            },
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x18FFFFFF),
                border: Border.all(color: const Color(0x22FFFFFF), width: 1),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.copy_rounded, color: AppColors.mcGrass, size: 16),
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(logsProvider.notifier).clear(),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x18FFFFFF),
                border: Border.all(color: const Color(0x22FFFFFF), width: 1),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.mcTextDim, size: 18),
            ),
          ),
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x18FFFFFF),
                border: Border.all(color: const Color(0x22FFFFFF), width: 1),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.close_rounded, color: AppColors.mcText, size: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Панель фильтров (iOS Segmented Pills)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0x0CFFFFFF),
            child: Row(
              children: LogLevel.values.map((lvl) {
                final isSelected = _selectedFilter == lvl;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = lvl),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.mcEnder
                            : const Color(0x14FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.mcEnder
                              : const Color(0x18FFFFFF),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        lvl.name.toUpperCase(),
                        style: AppTypography.caption(
                          isSelected ? Colors.white : AppColors.mcTextDim,
                        ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Список логов
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Text(
                      'Нет записей',
                      style: AppTypography.caption(AppColors.mcTextDim),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final item = filteredLogs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '[${_formatTime(item.timestamp)}] ',
                              style: AppTypography.caption(AppColors.mcTextDim),
                            ),
                            Text(
                              '[${item.level.name.toUpperCase()}] ',
                              style: AppTypography.caption(_levelColor(item.level)),
                            ),
                            Expanded(
                              child: Text(
                                item.message,
                                style: AppTypography.caption(AppColors.mcText),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
