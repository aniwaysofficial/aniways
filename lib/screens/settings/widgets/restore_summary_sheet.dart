import 'package:flutter/material.dart';

import 'package:aniways/core/helpers.dart';
import 'package:aniways/core/services/backup_restore_service.dart';
import 'package:aniways/core/theme/category_colors.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';
import 'package:aniways/screens/settings/settings_components.dart';

/// Shows the One UI modal bottom sheet previewing backup contents and options.
///
/// When [hideMergeOption] is `true` (e.g. during Onboarding setup), the
/// "Merge vs Replace" switch is hidden because the local database is fresh.
Future<bool?> showRestoreSummarySheet({
  required BuildContext context,
  required BackupSummary summary,
  bool hideMergeOption = false,
  Future<void> Function()? onRestoreSuccess,
}) {
  var restLibrary =
      summary.collectionEntriesCount > 0 || summary.animeCount > 0;
  var restProgress =
      summary.episodeProgressCount > 0 || summary.watchHistoryCount > 0;
  var restSettings = summary.settingsCount > 0;
  var replaceMode = hideMergeOption ? true : false;
  var isRestoring = false;

  return showOneUiBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final cs = Theme.of(sheetContext).colorScheme;
      final cat = CategoryColors.of(sheetContext);

      final dateFormatted = formatShortDateTime(summary.createdAt);

      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.viewPaddingOf(sheetContext).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cat.accounts.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.file_download_outlined,
                          color: cat.accounts,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Restore Backup',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Created on $dateFormatted',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Data Preview Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RestoreDataChip(
                        icon: Icons.movie_outlined,
                        label: summary.collectionEntriesCount > 0
                            ? '${summary.collectionEntriesCount} Anime'
                            : '${summary.animeCount} Anime',
                        color: cat.accounts,
                      ),
                      _RestoreDataChip(
                        icon: Icons.playlist_play_rounded,
                        label: '${summary.episodeProgressCount} Episodes',
                        color: cat.playback,
                      ),
                      _RestoreDataChip(
                        icon: Icons.tune_rounded,
                        label: '${summary.settingsCount} Settings',
                        color: cat.appearance,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Choose items to restore',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _RestoreCheckboxTile(
                    value: restLibrary,
                    onChanged:
                        summary.animeCount > 0 ||
                            summary.collectionEntriesCount > 0
                        ? (v) => setModalState(() => restLibrary = v ?? false)
                        : null,
                    title: 'Library & Collections',
                    subtitle: summary.collectionEntriesCount > 0
                        ? '${summary.collectionEntriesCount} in collections (${summary.animeCount} metadata)'
                        : '${summary.animeCount} anime metadata',
                    color: cat.backup,
                    isFirst: true,
                    isLast: false,
                  ),
                  const SizedBox(height: 2),
                  _RestoreCheckboxTile(
                    value: restProgress,
                    onChanged:
                        summary.episodeProgressCount > 0 ||
                            summary.watchHistoryCount > 0
                        ? (v) => setModalState(() => restProgress = v ?? false)
                        : null,
                    title: 'Watch Progress & History',
                    subtitle:
                        '${summary.episodeProgressCount} episode marks, ${summary.watchHistoryCount} history entries',
                    color: cat.playback,
                    isFirst: false,
                    isLast: false,
                  ),
                  const SizedBox(height: 2),
                  _RestoreCheckboxTile(
                    value: restSettings,
                    onChanged: summary.settingsCount > 0
                        ? (v) => setModalState(() => restSettings = v ?? false)
                        : null,
                    title: 'Settings & Preferences',
                    subtitle: '${summary.settingsCount} app settings',
                    color: cat.appearance,
                    isFirst: false,
                    isLast: true,
                  ),

                  if (!hideMergeOption) ...[
                    const SizedBox(height: 16),
                    // Merge vs Replace Mode Container
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                replaceMode
                                    ? Icons.warning_amber_rounded
                                    : Icons.merge_type_rounded,
                                size: 20,
                                color: replaceMode
                                    ? Colors.amber.shade700
                                    : cs.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  replaceMode
                                      ? 'Replace Existing Data'
                                      : 'Merge With Existing Data',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: replaceMode
                                        ? Colors.amber.shade700
                                        : cs.onSurface,
                                  ),
                                ),
                              ),
                              Switch.adaptive(
                                value: replaceMode,
                                onChanged: (v) =>
                                    setModalState(() => replaceMode = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            replaceMode
                                ? 'Existing library and progress will be cleared before importing backup data.'
                                : 'Combines backup data with your current data without deleting anything.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed:
                        isRestoring ||
                            (!restLibrary && !restProgress && !restSettings)
                        ? null
                        : () async {
                            setModalState(() => isRestoring = true);
                            try {
                              await BackupRestoreService.instance.restoreBackup(
                                summary.rawData,
                                restoreLibrary: restLibrary,
                                restoreProgress: restProgress,
                                restoreSettings: restSettings,
                                replaceExisting: replaceMode,
                                context: context,
                              );
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext, true);
                              }
                              if (onRestoreSuccess != null) {
                                await onRestoreSuccess();
                              } else if (context.mounted) {
                                AniwaysSnackBar.success(
                                  context,
                                  message: 'Backup restored successfully!',
                                );
                              }
                            } catch (e) {
                              setModalState(() => isRestoring = false);
                              if (context.mounted) {
                                AniwaysSnackBar.error(
                                  context,
                                  message: 'Failed to restore backup: $e',
                                );
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isRestoring
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              strokeCap: StrokeCap.round,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Restore Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _RestoreCheckboxTile extends StatelessWidget {
  const _RestoreCheckboxTile({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isFirst,
    required this.isLast,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String title;
  final String subtitle;
  final Color color;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: settingsTileBorderRadius(
          isFirst: isFirst,
          isLast: isLast,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: color,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}

class _RestoreDataChip extends StatelessWidget {
  const _RestoreDataChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

