import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme/app_colors.dart';
import '../../../../shared/design_system/theme/app_typography.dart';
import '../../../../shared/design_system/widgets/block_button.dart';
import '../../../../shared/design_system/widgets/furnace_loader.dart';
import '../../../../shared/design_system/widgets/pixel_app_bar.dart';
import '../../../../shared/design_system/widgets/pixel_switch.dart';
import '../../../../shared/design_system/widgets/procedural_pixel_app_icon.dart';
import '../../data/app_list_service.dart';
import '../providers/settings_providers.dart';

/// Экран выбора приложений для раздельного туннелирования (Split Tunneling).
///
/// Позволяет настроить обход VPN для банковских и локальных сервисов РФ.
class SplitTunnelingScreen extends ConsumerStatefulWidget {
  const SplitTunnelingScreen({super.key});

  @override
  ConsumerState<SplitTunnelingScreen> createState() => _SplitTunnelingScreenState();
}

class _SplitTunnelingScreenState extends ConsumerState<SplitTunnelingScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final settings = settingsAsync.value;
    final selectedPackages = Set<String>.from(settings?.bypassedPackages ?? const []);
    final appsAsync = ref.watch(installedAppsProvider);

    return Scaffold(
      backgroundColor: AppColors.mcVoid,
      appBar: PixelAppBar(
        title: 'ВЫБОР ПРИЛОЖЕНИЙ',
        actions: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/settings');
              }
            },
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
              child: const Icon(Icons.close_rounded, color: AppColors.mcText, size: 20),
            ),
          ),
        ],
      ),
      body: appsAsync.when(
        data: (apps) {
          final filteredApps = apps.where((app) {
            if (_searchQuery.isEmpty) return true;
            return app.name.toLowerCase().contains(_searchQuery) ||
                app.packageName.toLowerCase().contains(_searchQuery);
          }).toList();

          final isSplitEnabled = settings?.splitTunnelingEnabled ?? true;

          return Column(
            children: [
              // 0. Главный переключатель раздельного туннелирования
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0x1F000000),
                  border: Border(
                    bottom: BorderSide(color: Color(0x22FFFFFF), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alt_route_rounded, color: AppColors.mcGrass, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'РАЗДЕЛЬНОЕ ТУННЕЛИРОВАНИЕ',
                            style: AppTypography.title(Colors.white).copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSplitEnabled
                                ? 'Выбранные приложения работают в обход VPN'
                                : 'Выключено (весь трафик идёт через VPN)',
                            style: AppTypography.caption(
                              isSplitEnabled ? AppColors.mcGrass : AppColors.mcTextDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PixelSwitch(
                      value: isSplitEnabled,
                      onChanged: (val) async {
                        HapticFeedback.lightImpact();
                        await ref.read(settingsNotifierProvider.notifier).updateSplitTunneling(val);
                      },
                    ),
                  ],
                ),
              ),

              // 1. Поисковая строка и быстрые действия
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Color(0x14FFFFFF),
                  border: Border(
                    bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    // Поле поиска
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x22000000),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x28FFFFFF), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppColors.mcTextDim, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: AppTypography.label(Colors.white).copyWith(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Поиск приложений...',
                                hintStyle: AppTypography.caption(AppColors.mcTextDim),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: const Icon(Icons.cancel_rounded, color: AppColors.mcTextDim, size: 18),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Кнопки быстрых действий: Выбрать банки РФ / Снять всё
                    Row(
                      children: [
                        Expanded(
                          child: BlockButton(
                            label: 'БАНКИ И СЕРВИСЫ РФ',
                            icon: const Icon(Icons.account_balance_rounded, size: 14),
                            height: 34,
                            variant: BlockButtonVariant.ender,
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final updated = Set<String>.from(selectedPackages);
                              updated.addAll(AppListService.defaultBypassPackages);
                              await ref.read(settingsNotifierProvider.notifier).setBypassedPackages(updated.toList());
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            if (selectedPackages.isNotEmpty) {
                              await ref.read(settingsNotifierProvider.notifier).setBypassedPackages([]);
                            } else {
                              final all = apps.map((a) => a.packageName).toList();
                              await ref.read(settingsNotifierProvider.notifier).setBypassedPackages(all);
                            }
                          },
                          child: Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0x18FFFFFF),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(color: const Color(0x28FFFFFF), width: 1),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              selectedPackages.isNotEmpty ? 'Сбросить' : 'Все',
                              style: AppTypography.caption(Colors.white).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Информационный счетчик
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0x0AFFFFFF),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: AppColors.mcGrass),
                    const SizedBox(width: 6),
                    Text(
                      'Выбрано: ${selectedPackages.length} из ${apps.length} (идут в обход VPN)',
                      style: AppTypography.caption(AppColors.mcGrass).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Список приложений
              Expanded(
                child: filteredApps.isEmpty
                    ? Center(
                        child: Text(
                          'Приложения не найдены',
                          style: AppTypography.label(AppColors.mcTextDim),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        itemCount: filteredApps.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final app = filteredApps[index];
                          final isSelected = selectedPackages.contains(app.packageName);

                          return GestureDetector(
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              final updated = Set<String>.from(selectedPackages);
                              if (isSelected) {
                                updated.remove(app.packageName);
                              } else {
                                updated.add(app.packageName);
                              }
                              await ref
                                  .read(settingsNotifierProvider.notifier)
                                  .setBypassedPackages(updated.toList());
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0x1F10B981) : const Color(0x12FFFFFF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.mcGrass : const Color(0x1AFFFFFF),
                                  width: isSelected ? 1.2 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Пиксельная иконка приложения Minecraft
                                  ProceduralPixelAppIcon(
                                    name: app.name,
                                    packageName: app.packageName,
                                    iconBytes: app.iconBytes,
                                    size: 38,
                                    isSelected: isSelected,
                                  ),
                                  const SizedBox(width: 12),

                                  // Название и пакет
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          app.name,
                                          style: AppTypography.label(
                                            isSelected ? Colors.white : AppColors.mcText,
                                          ).copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          app.packageName,
                                          style: AppTypography.caption(AppColors.mcTextDim).copyWith(
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Переключатель
                                  PixelSwitch(
                                    value: isSelected,
                                    onChanged: (val) async {
                                      HapticFeedback.selectionClick();
                                      final updated = Set<String>.from(selectedPackages);
                                      if (val) {
                                        updated.add(app.packageName);
                                      } else {
                                        updated.remove(app.packageName);
                                      }
                                      await ref
                                          .read(settingsNotifierProvider.notifier)
                                          .setBypassedPackages(updated.toList());
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: FurnaceLoader(),
        ),
        error: (err, _) => Center(
          child: Text(
            'Ошибка загрузки списка приложений',
            style: AppTypography.label(AppColors.mcRedstone),
          ),
        ),
      ),
    );
  }
}
