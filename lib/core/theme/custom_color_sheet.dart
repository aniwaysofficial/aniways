import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/core/widgets/one_ui_bottom_sheet.dart';

/// Opens the custom colour picker. Returns the chosen colour, or null if the
/// sheet was dismissed.
Future<Color?> showCustomColorSheet(
  BuildContext context, {
  required Color initial,
}) {
  return showOneUiBottomSheet<Color>(
    context: context,
    showDragHandle: true,
    builder: (_) => _CustomColorSheet(initial: initial),
  );
}

class _CustomColorSheet extends StatefulWidget {
  const _CustomColorSheet({required this.initial});

  final Color initial;

  @override
  State<_CustomColorSheet> createState() => _CustomColorSheetState();
}

class _CustomColorSheetState extends State<_CustomColorSheet> {
  static const _quickColors = [
    Color(0xFFE53935), // red
    Color(0xFFFF7043), // deep orange
    Color(0xFFFFB300), // amber
    Color(0xFF7CB342), // light green
    Color(0xFF00ACC1), // cyan
    Color(0xFF1E88E5), // blue
    Color(0xFF5E35B1), // deep purple
    Color(0xFFD81B60), // pink
    Color(0xFF8D6E63), // brown
    Color(0xFF546E7A), // blue grey
  ];

  late HSVColor _hsv;
  late final TextEditingController _hex;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
    _hex = TextEditingController(text: _hexOf(widget.initial));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  static String _hexOf(Color c) =>
      (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

  /// Update from sliders / quick colours (also rewrites the hex field).
  void _set(HSVColor value) {
    setState(() => _hsv = value);
    _hex.text = _hexOf(value.toColor());
  }

  /// Update from typing in the hex field (leaves the field alone).
  void _onHexChanged(String text) {
    if (text.length != 6) return;
    final n = int.tryParse(text, radix: 16);
    if (n == null) return;
    setState(() => _hsv = HSVColor.fromColor(Color(0xFF000000 | n)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _hsv.toColor();
    final h = _hsv.hue;
    final s = _hsv.saturation;
    final v = _hsv.value;

    // The strip shows the real roles the theme will get from this seed.
    final scheme = ColorScheme.fromSeed(
      seedColor: color,
      brightness: theme.brightness,
    );

    Widget labeled(String label, Widget slider) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          slider,
        ],
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom color',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick any color. The whole app theme is generated from it.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _RoleStrip(scheme: scheme),
          const SizedBox(height: 20),

          labeled(
            'Hue',
            _GradientSlider(
              value: (h / 360).clamp(0.0, 1.0).toDouble(),
              colors: [
                for (var i = 0; i <= 6; i++)
                  HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor(),
              ],
              thumbColor: HSVColor.fromAHSV(1, h, 1, 1).toColor(),
              onChanged: (t) => _set(_hsv.withHue(t * 360)),
            ),
          ),
          labeled(
            'Saturation',
            _GradientSlider(
              value: s,
              colors: [
                HSVColor.fromAHSV(1, h, 0, v).toColor(),
                HSVColor.fromAHSV(1, h, 1, v).toColor(),
              ],
              thumbColor: color,
              onChanged: (t) => _set(_hsv.withSaturation(t)),
            ),
          ),
          labeled(
            'Brightness',
            _GradientSlider(
              value: v,
              colors: [Colors.black, HSVColor.fromAHSV(1, h, s, 1).toColor()],
              thumbColor: color,
              onChanged: (t) => _set(_hsv.withValue(t)),
            ),
          ),
          const SizedBox(height: 6),

          TextField(
            controller: _hex,
            onChanged: _onHexChanged,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: InputDecoration(
              labelText: 'Hex',
              prefixText: '# ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _quickColors)
                GestureDetector(
                  onTap: () => _set(HSVColor.fromColor(c)),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _hexOf(c) == _hexOf(color)
                            ? cs.onSurface
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, color),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A row of the main roles the theme will get from the picked seed.
class _RoleStrip extends StatelessWidget {
  const _RoleStrip({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final roles = <(Color, int)>[
      (scheme.primary, 2),
      (scheme.primaryContainer, 1),
      (scheme.secondary, 1),
      (scheme.tertiary, 1),
      (scheme.surfaceContainerHighest, 1),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            for (final r in roles)
              Expanded(
                flex: r.$2,
                child: ColoredBox(color: r.$1, child: const SizedBox.expand()),
              ),
          ],
        ),
      ),
    );
  }
}

/// A slider whose track is a gradient (used for hue / saturation / brightness).
class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.value,
    required this.colors,
    required this.thumbColor,
    required this.onChanged,
  });

  final double value; // 0..1
  final List<Color> colors;
  final Color thumbColor;
  final ValueChanged<double> onChanged;

  static const double _size = 28;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final travel = width - _size;

        void update(double dx) {
          if (travel <= 0) return;
          onChanged(((dx - _size / 2) / travel).clamp(0.0, 1.0).toDouble());
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => update(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
          child: SizedBox(
            height: _size,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: LinearGradient(colors: colors),
                  ),
                ),
                Positioned(
                  left: value.clamp(0.0, 1.0) * travel,
                  child: Container(
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      color: thumbColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
