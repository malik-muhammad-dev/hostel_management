import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/theme/app_colors.dart';

// =============================================================================
// SHIMMER LOADING PLACEHOLDERS
//
// Shared building blocks for "still loading" skeletons — used on the
// Dashboard, Students table, and Fees table (the three places explicitly
// asked for). Reused rather than duplicated per screen, same reasoning
// as RealtimeTableSync: one obviously-correct shared piece instead of
// three near-identical ones.
//
// Deliberately only shown on the very first load (nothing fetched yet),
// never on a quiet background refresh (e.g. from real-time sync) that
// already has data to show — see each screen's own isLoading check for
// exactly where that line is drawn.
// =============================================================================

/// One plain rounded rectangle — the basic shape every skeleton below is
/// built from. Solid white by design: the shimmer sweep (see [AppShimmer])
/// is what actually makes it visible, not this box's own color.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height = 12,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Wraps a subtree of [ShimmerBox]es in one shared animated sweep — wrap
/// once around a whole skeleton layout, not around each individual box.
class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: child,
    );
  }
}

/// One skeleton table row: an optional leading avatar-square (matching
/// the Students/Fees tables' own row shape), one shimmer bar per entry
/// in [columnFlexes] (matching that table's real Expanded/flex columns),
/// and a fixed-width trailing bar (matching the real "Status" column).
class TableRowSkeleton extends StatelessWidget {
  final List<int> columnFlexes;
  final bool hasAvatar;
  final double trailingWidth;

  const TableRowSkeleton({
    super.key,
    required this.columnFlexes,
    this.hasAvatar = true,
    this.trailingWidth = 90,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (hasAvatar) ...[
            const ShimmerBox(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            const SizedBox(width: 15),
          ],
          for (final flex in columnFlexes)
            Expanded(
              flex: flex,
              child: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: ShimmerBox(height: 13),
              ),
            ),
          SizedBox(
            width: trailingWidth,
            child: const ShimmerBox(height: 13, width: 60),
          ),
        ],
      ),
    );
  }
}

/// A full skeleton table: [rowCount] [TableRowSkeleton]s, all animating
/// under one shared [AppShimmer] sweep. Meant to stand in for a whole
/// table's rows (header stays real/unchanged — only the rows loading).
class TableSkeleton extends StatelessWidget {
  final List<int> columnFlexes;
  final bool hasAvatar;
  final double trailingWidth;
  final int rowCount;

  const TableSkeleton({
    super.key,
    required this.columnFlexes,
    this.hasAvatar = true,
    this.trailingWidth = 90,
    this.rowCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: List.generate(
          rowCount,
          (_) => TableRowSkeleton(
            columnFlexes: columnFlexes,
            hasAvatar: hasAvatar,
            trailingWidth: trailingWidth,
          ),
        ),
      ),
    );
  }
}