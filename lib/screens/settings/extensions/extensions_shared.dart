import 'package:flutter/material.dart';
import 'package:aniways/core/extensions/models/extension_manifest.dart';

/// The official extension repository URL.
const String kOfficialRepoUrl =
    'https://raw.githubusercontent.com/aniwaysofficial/aniways-extensions/main/index.json';

/// Returns true if [url] points to the official Aniways extension repository.
bool isOfficialRepo(String? url) {
  if (url == null) return false;
  final clean = url.trim().toLowerCase();
  return clean == kOfficialRepoUrl.toLowerCase() ||
      clean.contains('aniwaysofficial/aniways-extensions');
}

/// Returns true if [manifest] is from the official repository or official maintainers.
bool isVerifiedExtension(ExtensionManifest manifest) {
  if (isOfficialRepo(manifest.repoUrl)) return true;
  return manifest.author.toLowerCase() == 'aniways community';
}

/// A subtle One UI verified badge displaying `Icons.verified_outlined`.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({
    super.key,
    this.size = 15,
    this.padding = const EdgeInsets.only(left: 4),
  });

  final double size;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Tooltip(
        message: 'Official & Verified',
        child: Icon(
          Icons.verified_outlined,
          size: size,
          color: cs.primary,
        ),
      ),
    );
  }
}

/// A subtle 18+ adult maturity badge for adult extensions.
class AdultBadge extends StatelessWidget {
  const AdultBadge({
    super.key,
    this.padding = const EdgeInsets.only(left: 6),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Tooltip(
        message: '18+ Adult Provider',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: cs.error.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: cs.error.withValues(alpha: 0.40),
              width: 0.8,
            ),
          ),
          child: Text(
            '18+',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: cs.error,
              letterSpacing: 0.2,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Sub", "Dub" or "Sub · Dub" (empty string when neither is available).
String langLabel(ExtensionManifest m) =>
    [if (m.hasSub) 'Sub', if (m.hasDub) 'Dub'].join(' · ');

/// Single quiet metadata line: `v1.2 · Author · Sub · Dub`.
String extensionMetaLine(ExtensionManifest m) => [
  'v${m.version}',
  m.author,
  langLabel(m),
].where((s) => s.isNotEmpty).join(' · ');

/// One UI style grouped-list corner radius: large on the first/last item,
/// small in between, so a run of tiles reads as one block.
BorderRadius groupRadius(int index, int count) {
  const big = Radius.circular(22);
  const small = Radius.circular(6);
  return BorderRadius.vertical(
    top: index == 0 ? big : small,
    bottom: index == count - 1 ? big : small,
  );
}

/// Shared empty state used by Installed, Browse and Repositories.
class ExtensionEmptyState extends StatelessWidget {
  const ExtensionEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.secondaryLabel,
    this.secondaryIcon,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: cs.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onSecondary,
                icon: Icon(secondaryIcon ?? Icons.add_rounded),
                label: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
