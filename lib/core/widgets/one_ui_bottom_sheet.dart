import 'package:flutter/material.dart';

/// One UI standard bottom sheet drag handle pill.
class OneUiDragHandle extends StatelessWidget {
  const OneUiDragHandle({
    super.key,
    this.width = 38,
    this.height = 4,
    this.margin = const EdgeInsets.only(top: 12, bottom: 12),
    this.color,
  });

  final double width;
  final double height;
  final EdgeInsetsGeometry margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: color ?? cs.outlineVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

/// Opens a modal bottom sheet pre-styled according to Aniways's One UI design language:
/// - Rounded top corners (24dp default)
/// - Surface background color
/// - Scoped to the active navigator so back press dismisses the sheet first
/// - Consistent scroll and dismissal behavior
Future<T?> showOneUiBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  Color? backgroundColor,
  double topRadius = 24.0,
}) {
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor ?? cs.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
    ),
    builder: builder,
  );
}
