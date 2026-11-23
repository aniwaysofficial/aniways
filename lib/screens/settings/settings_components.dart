import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';

// ═════════════════════════════════════════════════════════════════════════
// Shared One UI Settings Metrics & Constants
// ═════════════════════════════════════════════════════════════════════════

const kSettingsBigRadius = Radius.circular(20);
const kSettingsSmallRadius = Radius.circular(6);
const kSettingsHorizontalPadding = EdgeInsets.symmetric(horizontal: 16);

/// Creates standard One UI rounded vertical borders for grouped settings cards.
BorderRadius settingsTileBorderRadius({
  required bool isFirst,
  required bool isLast,
}) {
  return BorderRadius.vertical(
    top: isFirst ? kSettingsBigRadius : kSettingsSmallRadius,
    bottom: isLast ? kSettingsBigRadius : kSettingsSmallRadius,
  );
}

// ═════════════════════════════════════════════════════════════════════════
// Reusable Settings Tile Icon
// ═════════════════════════════════════════════════════════════════════════

class SettingsTileIcon extends StatelessWidget {
  const SettingsTileIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 22,
    this.enabled = true,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: enabled ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: enabled ? color : cs.outline, size: size),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Reusable Section Header
// ═════════════════════════════════════════════════════════════════════════

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerText = Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );

    if (trailing != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 0, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [headerText, trailing!],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: headerText,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Reusable Switch Tile
// ═════════════════════════════════════════════════════════════════════════

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isFirst,
    required this.isLast,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
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
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: SettingsTileIcon(icon: icon, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: (subtitle != null && subtitle!.isNotEmpty)
            ? Text(
                subtitle!,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
              )
            : null,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Reusable Action / Navigation Tile
// ═════════════════════════════════════════════════════════════════════════

class SettingsActionTile extends StatelessWidget {
  const SettingsActionTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final Widget? trailing;

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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SettingsTileIcon(icon: icon, color: color),
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
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
        ),
        trailing:
            trailing ??
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Reusable Selector Tile & Option (Bottom Sheet Radio Picker)
// ═════════════════════════════════════════════════════════════════════════

class SettingsOption<T> {
  const SettingsOption(this.value, this.label, this.description);

  final T value;
  final String label;
  final String description;
}

class SettingsSelectorTile<T> extends StatelessWidget {
  const SettingsSelectorTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.currentValue,
    required this.options,
    required this.onSelected,
    required this.isFirst,
    required this.isLast,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final T currentValue;
  final List<SettingsOption<T>> options;
  final ValueChanged<T>? onSelected;
  final bool isFirst;
  final bool isLast;

  void _showSelectionSheet(BuildContext context) {
    if (onSelected == null) return;
    HapticFeedback.selectionClick();

    showOneUiBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      useRootNavigator: false,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OneUiDragHandle(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (_, index) {
                      final opt = options[index];
                      final isSelected = opt.value == currentValue;

                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected ? cs.primary : cs.outline,
                          size: 22,
                        ),
                        title: Text(
                          opt.label,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? cs.primary : cs.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          opt.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onSelected!(opt.value);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEnabled = onSelected != null;

    return Material(
      color: cs.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: settingsTileBorderRadius(
          isFirst: isFirst,
          isLast: isLast,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        enabled: isEnabled,
        leading: SettingsTileIcon(icon: icon, color: color, enabled: isEnabled),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isEnabled
                ? cs.onSurface
                : cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isEnabled
                ? cs.onSurfaceVariant
                : cs.onSurfaceVariant.withValues(alpha: 0.5),
            fontSize: 12.5,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isEnabled ? cs.onSurfaceVariant : cs.outline,
        ),
        onTap: isEnabled ? () => _showSelectionSheet(context) : null,
      ),
    );
  }
}
