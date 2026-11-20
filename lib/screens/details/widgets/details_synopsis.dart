import 'package:flutter/material.dart';
import 'package:aniways/core/widgets/anime_states.dart';

/// Collapsible synopsis text with 'Read more' / 'Show less' toggle and skeleton loading.
class DetailsSynopsis extends StatefulWidget {
  const DetailsSynopsis({
    super.key,
    required this.text,
    required this.loading,
  });

  final String? text;
  final bool loading;

  @override
  State<DetailsSynopsis> createState() => _DetailsSynopsisState();
}

class _DetailsSynopsisState extends State<DetailsSynopsis> {
  static const _collapsedLines = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = widget.text;

    if (text == null) {
      if (widget.loading) {
        return const Column(
          children: [
            Skeleton(height: 12, radius: 6),
            SizedBox(height: 8),
            Skeleton(height: 12, radius: 6),
            SizedBox(height: 8),
            Skeleton(height: 12, radius: 6),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Skeleton(width: 180, height: 12, radius: 6),
            ),
          ],
        );
      }
      return Text(
        'No synopsis available.',
        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      );
    }

    final style = theme.textTheme.bodyMedium?.copyWith(
      height: 1.6,
      color: cs.onSurface.withValues(alpha: 0.88),
    );

    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: box.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: style,
              maxLines: _expanded ? null : _collapsedLines,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
            if (overflows)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: InkWell(
                  onTap: () {
                    setState(() => _expanded = !_expanded);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _expanded ? 'Show less' : 'Read more',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: cs.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

