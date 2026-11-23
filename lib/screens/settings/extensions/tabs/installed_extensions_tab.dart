import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/extensions/manager/extension_manager.dart';
import 'package:aniways/core/extensions/models/extension_manifest.dart';
import 'package:aniways/core/widgets/extension_icon.dart';
import 'package:aniways/core/widgets/aniways_snackbar.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';
import 'package:aniways/screens/settings/extensions/extensions_shared.dart';
import 'package:url_launcher/url_launcher.dart';

class InstalledExtensionsTab extends StatelessWidget {
  const InstalledExtensionsTab({super.key, required this.onNavigateToBrowse});

  final VoidCallback onNavigateToBrowse;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<ExtensionManifest>>(
      stream: extensionManager.dbRepository.watchInstalledExtensions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final extensions = snapshot.data!;
        if (extensions.isEmpty) {
          return ExtensionEmptyState(
            icon: Icons.extension_off_rounded,
            title: 'No Extensions Installed',
            message: 'Install extensions from the repository catalog.',
            actionLabel: 'Browse Catalog',
            actionIcon: Icons.travel_explore_rounded,
            onAction: onNavigateToBrowse,
          );
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 48),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 20, 8),
              child: Text(
                'Playback priority · hold and drag to reorder',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: extensions.length,
              onReorderItem: (oldIndex, newIndex) async {
                HapticFeedback.mediumImpact();
                final mutable = List<ExtensionManifest>.from(extensions);
                final item = mutable.removeAt(oldIndex);
                mutable.insert(newIndex, item);
                await extensionManager.dbRepository.updatePriorityOrder(
                  mutable.map((e) => e.id).toList(),
                );
              },
              itemBuilder: (context, index) {
                return _ExtensionTile(
                  key: ValueKey(extensions[index].id),
                  extension: extensions[index],
                  index: index,
                  count: extensions.length,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Grouped-list row: icon · name + meta line · switch.
/// Long-press anywhere on the row to drag; tap opens details.
class _ExtensionTile extends StatelessWidget {
  const _ExtensionTile({
    super.key,
    required this.extension,
    required this.index,
    required this.count,
  });

  final ExtensionManifest extension;
  final int index;
  final int count;

  void _showDetailsSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showOneUiBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      builder: (sheetCtx) => _ExtensionDetailsSheet(extension: extension),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = extension.isEnabled;

    return ReorderableDelayedDragStartListener(
      index: index,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
        child: Material(
          color: cs.surfaceContainerHigh,
          borderRadius: groupRadius(index, count),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showDetailsSheet(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Opacity(
                    opacity: enabled ? 1 : 0.5,
                    child: ExtensionIcon(
                      name: extension.name,
                      iconUrl: extension.iconUrl,
                      size: 44,
                      borderRadius: 13,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                extension.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.5,
                                  color: enabled
                                      ? cs.onSurface
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (isVerifiedExtension(extension))
                              const VerifiedBadge(),
                            if (extension.isAdult)
                              const AdultBadge(),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          extensionMetaLine(extension),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.82,
                    child: Switch.adaptive(
                      value: enabled,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        extensionManager.toggleExtension(extension.id, val);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One UI Bottom Sheet presenting detailed extension settings, web link, and uninstall options.
class _ExtensionDetailsSheet extends StatelessWidget {
  const _ExtensionDetailsSheet({required this.extension});

  final ExtensionManifest extension;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final langs = langLabel(extension);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OneUiDragHandle(margin: EdgeInsets.only(bottom: 16)),

          // Header: Icon + Name + Version
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExtensionIcon(
                name: extension.name,
                iconUrl: extension.iconUrl,
                size: 56,
                borderRadius: 16,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            extension.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isVerifiedExtension(extension))
                          const VerifiedBadge(
                            size: 20,
                            padding: EdgeInsets.only(left: 6),
                          ),
                        if (extension.isAdult)
                          const AdultBadge(
                            padding: EdgeInsets.only(left: 6),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v${extension.version} (Code ${extension.versionCode}) · ${extension.author}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          if (extension.description != null &&
              extension.description!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                extension.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          const SizedBox(height: 14),

          // Metadata Info Rows
          if (extension.baseUrl != null && extension.baseUrl!.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language_rounded, size: 20),
              title: const Text('Website'),
              subtitle: Text(
                extension.baseUrl!,
                style: TextStyle(color: cs.primary),
              ),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () async {
                final uri = Uri.tryParse(extension.baseUrl!);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),

          // Sub/Dub info lives here now instead of badges in the list.
          if (langs.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.subtitles_rounded, size: 20),
              title: const Text('Availability'),
              subtitle: Text(langs),
            ),

          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.audiotrack_rounded, size: 20),
            title: const Text('Audio Streams'),
            subtitle: Text(
              extension.audio.map((a) => a.name.toUpperCase()).join(', '),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Action Buttons: Uninstall
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.pop(context);
              _confirmUninstall(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.errorContainer.withValues(alpha: 0.4),
              foregroundColor: cs.error,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Uninstall Extension'),
          ),
        ],
      ),
    );
  }

  void _confirmUninstall(BuildContext context) {
    HapticFeedback.lightImpact();
    showOneUiBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const OneUiDragHandle(margin: EdgeInsets.only(bottom: 20)),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: isDark ? 0.20 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: cs.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Uninstall ${extension.name}?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'This will remove the extension code and disable streaming from this provider.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await extensionManager
                              .uninstallExtension(extension.id);
                          if (context.mounted) {
                            AniwaysSnackBar.success(
                              context,
                              message: '${extension.name} uninstalled.',
                            );
                          }
                        },
                        child: const Text('Uninstall'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
