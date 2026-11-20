import 'package:flutter/material.dart';

/// Max width of onboarding content on tablets / desktop.
const double kOnboardingMaxWidth = 560;

// Same shape language as the Settings screens.
const Radius _bigRadius = Radius.circular(20);
const Radius _smallRadius = Radius.circular(6);

/// Gap between rows inside a group (same as Settings).
const double kOnboardingTileGap = 2;

/// One onboarding step: a large title, a short subtitle, then the content.
///
/// There is no card chrome. The page sits directly on the scaffold and
/// scrolls as a whole. The progress bar, back and skip live in the screen
/// shell, so steps don't repeat them.
///
/// Pass [body] for normal content, or [slivers] when the content contains a
/// long lazy list/grid (e.g. the anime picker).
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.body,
    this.slivers,
  }) : assert(body != null || slivers != null, 'Provide a body or slivers');

  final String title;
  final String subtitle;
  final Widget? body;
  final List<Widget>? slivers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 16 on phones, like Settings. Centered column on wide screens.
        final side = constraints.maxWidth > kOnboardingMaxWidth + 32
            ? (constraints.maxWidth - kOnboardingMaxWidth) / 2
            : 16.0;

        final content = <Widget>[
          if (body != null) SliverToBoxAdapter(child: body),
          ...?slivers,
        ];

        return CustomScrollView(
          slivers: [
            SliverPadding(
              // Header text sits 4px in from the tiles, like a large app bar.
              padding: EdgeInsets.fromLTRB(side + 4, 8, side + 4, 28),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.1,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 0, side, 32),
              sliver: SliverMainAxisGroup(slivers: content),
            ),
          ],
        );
      },
    );
  }
}

/// Section label in the Settings style: small, bold, primary colored, with a
/// little letter spacing. Optional action on the right (e.g. "Clear").
class OnboardingSectionHeader extends StatelessWidget {
  const OnboardingSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// A titled block of content with consistent spacing below it.
class OnboardingSection extends StatelessWidget {
  const OnboardingSection({
    super.key,
    this.title,
    required this.child,
    this.trailing,
  });

  /// Leave null for a block without a label.
  final String? title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            OnboardingSectionHeader(title: title!, trailing: trailing),
          child,
        ],
      ),
    );
  }
}

/// Compact text action used in section headers.
class OnboardingTextAction extends StatelessWidget {
  const OnboardingTextAction({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}

/// Small helper line with an icon, used for reassurance notes.
class OnboardingNote extends StatelessWidget {
  const OnboardingNote({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stacks [OnboardingTile]s with a big radius on the group's outer corners
/// and a small one where rows meet, matching the Settings list.
class OnboardingGroup extends StatelessWidget {
  const OnboardingGroup({super.key, required this.tiles});

  final List<OnboardingTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == tiles.length - 1 ? 0 : kOnboardingTileGap,
            ),
            child: tiles[i].withRadius(
              BorderRadius.vertical(
                top: i == 0 ? _bigRadius : _smallRadius,
                bottom: i == tiles.length - 1 ? _bigRadius : _smallRadius,
              ),
            ),
          ),
      ],
    );
  }
}

/// A single Settings-style row: optional tinted icon badge, title, subtitle
/// and trailing widget.
///
/// Pass [selected] to make it a radio-style choice. Leave it null for plain
/// rows, switches and navigation rows. [color] tints the icon badge (use a
/// `CategoryColors` value to match Settings).
class OnboardingTile extends StatelessWidget {
  const OnboardingTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.selected,
    this.trailing,
    this.onTap,
    this.radius = const BorderRadius.all(_bigRadius),
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final bool? selected;
  final Widget? trailing;
  final VoidCallback? onTap;
  final BorderRadius radius;

  OnboardingTile withRadius(BorderRadius r) => OnboardingTile(
    key: key,
    title: title,
    subtitle: subtitle,
    icon: icon,
    color: color,
    selected: selected,
    trailing: trailing,
    onTap: onTap,
    radius: r,
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = selected ?? false;
    final tint = color ?? cs.primary;

    final Widget? end =
        trailing ??
        (selected == null
            ? null
            : Icon(
                active
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: active ? cs.primary : cs.outline,
                size: 22,
              ));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: ShapeDecoration(
        color: active
            ? Color.alphaBlend(
                cs.primaryContainer.withValues(alpha: 0.55),
                cs.surfaceContainerHigh,
              )
            : cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          onTap: onTap,
          leading: icon == null
              ? null
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: tint, size: 22),
                ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              fontSize: 15,
              color: active ? cs.primary : cs.onSurface,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
                ),
          trailing: end,
        ),
      ),
    );
  }
}

/// Rounded pill used for multi-choice and single-choice chips
/// (languages, genres).
class OnboardingPill extends StatelessWidget {
  const OnboardingPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: selected ? cs.primaryContainer : cs.surfaceContainerHigh,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? cs.primary.withValues(alpha: 0.6)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
