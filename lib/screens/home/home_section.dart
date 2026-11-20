import 'package:flutter/material.dart';

import 'package:aniways/core/responsive.dart';
import 'package:aniways/core/widgets/anime_card.dart';
import 'package:aniways/core/widgets/anime_states.dart';
import 'package:aniways/providers/anime_lists.dart';
import 'package:aniways/providers/home_provider.dart';

/// Poster width in the horizontal rows: grows with the page area.
double _cardWidthFor(BuildContext context) => switch (context.layoutSize) {
  WindowSize.compact => 128,
  WindowSize.medium => 148,
  WindowSize.expanded => 160,
  WindowSize.large => 172,
};

/// Title row: tinted icon, bold title and an optional "View all" link.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.onViewAll,
    this.trailing,
    this.inset,
    this.leftInset,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onViewAll;
  final Widget? trailing;
  final double? inset;
  final double? leftInset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Lines up with the (centred) page content on wide screens.
    final pageIn = pageInset(context);
    final effectiveLeft = leftInset ?? inset ?? pageIn;
    final effectiveRight = inset ?? pageIn;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        effectiveLeft,
        0,
        effectiveRight > 16 ? effectiveRight - 6 : 10,
        0,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onViewAll != null)
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: cs.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One horizontal row on the home screen: header (with "View all") + posters,
/// or skeletons / an error card.
class HomeSection extends StatefulWidget {
  const HomeSection({
    super.key,
    required this.type,
    required this.state,
    required this.color,
    required this.onRetry,
    required this.onViewAll,
  });

  final AnimeListType type;
  final HomeSectionState state;
  final Color color;
  final VoidCallback onRetry;
  final ValueChanged<int> onViewAll;

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _handleViewAll(double cardWidth) {
    var index = 0;
    if (_scroll.hasClients && widget.state.items.isNotEmpty) {
      final stride = cardWidth + 12.0;
      index = (_scroll.offset / stride)
          .round()
          .clamp(0, widget.state.items.length - 1);
    }
    widget.onViewAll(index);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    // Nothing to show for this section (e.g. no upcoming anime).
    if (!state.isLoading && !state.hasError && state.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final cardWidth = _cardWidthFor(context);
    final inset = pageInset(context);
    final posterHeight = cardWidth / kPosterAspect;
    // Enough skeletons to fill the row on any width.
    final skeletons = (context.contentWidth / (cardWidth + 12)).ceil() + 1;
    final rowHeight = posterHeight + animeCardTextHeight(context);

    final Widget body;
    if (state.items.isNotEmpty) {
      body = SizedBox(
        height: rowHeight,
        child: ListView.separated(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          clipBehavior:
              Clip.none, // let cards scale past the row without being cut
          padding: EdgeInsets.symmetric(horizontal: inset),
          itemCount: state.items.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) => AnimeCard(
            anime: state.items[index],
            width: cardWidth,
            heroPrefix: 'home-${widget.type.name}',
          ),
        ),
      );
    } else if (state.hasError) {
      body = Padding(
        padding: EdgeInsets.symmetric(horizontal: inset),
        child: ErrorCard(
          message: describeError(state.error),
          onRetry: widget.onRetry,
        ),
      );
    } else {
      body = SizedBox(
        height: rowHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: inset),
          itemCount: skeletons,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) => AnimeCardSkeleton(width: cardWidth),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: widget.type.title,
            icon: widget.type.icon,
            color: widget.color,
            onViewAll: () => _handleViewAll(cardWidth),
          ),
          const SizedBox(height: 14),
          body,
        ],
      ),
    );
  }
}
