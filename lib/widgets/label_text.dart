import 'package:flutter/material.dart';

/// Places a text inside the exact Zeplin text box so the glyphs sit at the
/// same vertical offset as the design.
class LabelText extends StatelessWidget {
  const LabelText(
    this.text,
    this.style, {
    super.key,
    required this.width,
    this.height = 25,
  });

  final String text;
  final TextStyle style;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: style),
      ),
    );
  }
}
