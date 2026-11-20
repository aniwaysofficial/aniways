import 'package:flutter/material.dart';
import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/models/anime_details.dart';

/// 16:9 trailer thumbnail card with elevated play overlay.
class DetailsTrailerCard extends StatelessWidget {
  const DetailsTrailerCard({
    super.key,
    required this.trailer,
    required this.onTap,
  });

  final AnimeTrailer trailer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: cs.surfaceContainerLow,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimeImage(trailer.thumbnail),
                ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.60),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

