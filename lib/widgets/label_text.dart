import 'package:flutter/material.dart';

/// Places a text inside the exact Zeplin text box so the glyphs sit at the
/// same vertical offset as the design.
///
/// The box height is the line height Zeplin reports for the layer, so the
/// style gets an explicit `height` (box / font size) with even leading
/// distribution. That reproduces the design's half-leading placement; without
/// it Flutter clamps the paragraph to the box for tall lines (e.g. the 28px
/// hero title: natural line box 34px > 27px box) and top aligns the glyphs a
/// few pixels lower than Zeplin.
///
/// Zeplin boxes hug the text, so the Inter advance plus Flutter's trailing
/// letter spacing can be a hair wider than the box (e.g. 'ORDER #NX4582':
/// 108.8px in a 107px box). Every label in the design is single line, so
/// wrapping is disabled instead of widening the box.
class LabelText extends StatelessWidget {
  const LabelText(
    this.text,
    this.style, {
    super.key,
    this.width,
    this.height = 25,
  });

  final String text;
  final TextStyle style;

  /// Fixed Zeplin box width. When `null` the box hugs the text, which is
  /// what inline label rows (e.g. "Email (optional)") need so a trailing
  /// sibling can sit a real gap after the glyphs instead of overlapping a
  /// pre-measured box.
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double? fontSize = style.fontSize;
    final TextStyle effective = fontSize == null || fontSize == 0
        ? style
        : style.copyWith(
            height: height / fontSize,
            leadingDistribution: TextLeadingDistribution.even,
          );
    return SizedBox(
      width: width,
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: effective,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}
