import 'package:flutter/material.dart';
import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/models/anime_details.dart';

/// Character poster, name, role badge and voice actor card.
class DetailsCharacterCard extends StatelessWidget {
  const DetailsCharacterCard({super.key, required this.character});

  final AnimeCharacter character;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    final subtitle = character.voiceActor ?? character.roleLabel ?? '';

    return RepaintBoundary(
      child: SizedBox(
        width: 108,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: kPosterAspect,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kPosterRadius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimeImage(
                      character.imageUrl,
                      alignment: Alignment.topCenter,
                      cacheWidth: 250,
                    ),
                    if (character.isMain)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Main',
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: scaler.scale(13.5) * 1.25 * 2,
            child: Text(
              character.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11.5,
              height: 1.25,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
}

