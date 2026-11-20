import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Clean, rounded One UI icon widget for streaming extensions.
///
/// Displays the remote website logo with automatic caching and falls back
/// to a stylized initial avatar on error or empty URL.
class ExtensionIcon extends StatelessWidget {
  const ExtensionIcon({
    super.key,
    required this.name,
    this.iconUrl,
    this.size = 44,
    this.borderRadius = 12,
  });

  final String name;
  final String? iconUrl;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(borderRadius);

    Widget fallback() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: radius,
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'E',
            style: TextStyle(
              fontSize: size * 0.44,
              fontWeight: FontWeight.bold,
              color: cs.onPrimaryContainer,
            ),
          ),
        ),
      );
    }

    if (iconUrl == null || iconUrl!.trim().isEmpty) {
      return fallback();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: radius,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: iconUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => fallback(),
          errorWidget: (context, url, error) => fallback(),
        ),
      ),
    );
  }
}

