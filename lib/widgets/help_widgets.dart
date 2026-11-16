import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared building blocks for the Help & Support family of screens (the
/// support home, the topic lists and the article pages).
///
/// These replace the per-screen copies of the Zeplin hero card, white list
/// card and "Report a problem" tile so every help screen lays its content out
/// with a normal scroll + flex layout — the same approach as
/// `review_ratings_page.dart` — instead of hard-coded `Positioned` offsets and
/// fixed card heights that overlap as soon as the text grows.

/// Soft drop shadow used by every white help card (the five-stop shadow from
/// the Zeplin design).
const List<BoxShadow> helpCardShadow = <BoxShadow>[
  BoxShadow(color: Color(0x1AB8B8B8), offset: Offset(0, 1), blurRadius: 3),
  BoxShadow(color: Color(0x17B8B8B8), offset: Offset(0, 6), blurRadius: 6),
  BoxShadow(color: Color(0x0DB8B8B8), offset: Offset(0, 13), blurRadius: 8),
  BoxShadow(color: Color(0x03B8B8B8), offset: Offset(0, 23), blurRadius: 9),
  BoxShadow(color: Color(0x00B8B8B8), offset: Offset(0, 36), blurRadius: 10),
];

/// The dark gradient hero card shared by every help screen. Content is laid
/// out in a [Column], so it grows with the text instead of overflowing a
/// fixed-height artboard box.
class HelpHero extends StatelessWidget {
  const HelpHero({
    super.key,
    required this.kicker,
    required this.title,
    this.subtitle,
    this.meta,
    this.children = const <Widget>[],
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 20),
    this.titleStyle = _defaultTitleStyle,
    this.titleSingleLine = false,
    this.glowCenter = const Alignment(0.823, -0.322),
    this.glowRadius = 1.1,
  });

  static const TextStyle _defaultTitleStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 26,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.26,
    color: Color(0xFFC6E96D),
  );
  static const TextStyle _kickerStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    color: Color(0xFFB6C5BC),
  );
  static const TextStyle _subtitleStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    color: Color(0xFFB6C5BC),
  );
  static const TextStyle _metaStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: Color(0xFFB6C5BC),
  );
  static const TextStyle _supportStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 8,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.08,
    color: Color(0xFFCDEB6B),
  );

  /// Small label at the top left ("Help center" / the screen header).
  final String kicker;

  /// Hero headline.
  final String title;

  /// Optional supporting line under the headline.
  final String? subtitle;

  /// Optional bottom meta line ("2 min read").
  final String? meta;

  /// Extra content (search field, buttons, ...) rendered below the text
  /// block. Each widget supplies its own spacing.
  final List<Widget> children;

  /// Inner padding of the banner. Screens can tighten it (the support home
  /// does) to keep the hero card short without touching its content.
  final EdgeInsetsGeometry padding;

  final TextStyle titleStyle;

  /// Keeps the headline on one line: it is laid out unwrapped and scaled down
  /// to the space left of the "Support" pill, so "How can we help?" never
  /// breaks "help?" onto a second line on any screen width.
  final bool titleSingleLine;
  final Alignment glowCenter;
  final double glowRadius;

  @override
  Widget build(BuildContext context) {
    final Widget titleText = titleSingleLine
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(title, style: titleStyle, maxLines: 1, softWrap: false),
          )
        : Text(title, style: titleStyle);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment(-0.704419945067802, -0.5811517293366738),
          end: Alignment(0.4779005750097418, 0.380281631141034),
          colors: <Color>[Color(0xFF0B341B), Color(0xFF135029)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 7),
            blurRadius: 15,
          ),
          BoxShadow(
            color: Color(0x17000000),
            offset: Offset(0, 27),
            blurRadius: 27,
          ),
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 60),
            blurRadius: 36,
          ),
          BoxShadow(
            color: Color(0x03000000),
            offset: Offset(0, 107),
            blurRadius: 43,
          ),
          BoxShadow(
            color: Color(0x00000000),
            offset: Offset(0, 167),
            blurRadius: 47,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: glowCenter,
                    radius: glowRadius,
                    colors: const <Color>[
                      Color(0xD13CA35A),
                      Color(0xA33CA35A),
                      Color(0x6B3CA35A),
                      Color(0x1A3CA35A),
                      Color(0x003CA35A),
                    ],
                    stops: const <double>[0, 0.19, 0.42, 0.56, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(kicker, style: _kickerStyle),
                            const SizedBox(height: 6),
                            titleText,
                            if (subtitle != null) ...<Widget>[
                              const SizedBox(height: 6),
                              Text(subtitle!, style: _subtitleStyle),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _SupportPill(),
                    ],
                  ),
                  ...children,
                  if (meta != null) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(meta!, style: _metaStyle),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportPill extends StatelessWidget {
  const _SupportPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 21,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: const Color(0x63CDEB6B)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            _LimeDot(),
            SizedBox(width: 5),
            Text('Support', style: HelpHero._supportStyle),
          ],
        ),
      ),
    );
  }
}

class _LimeDot extends StatelessWidget {
  const _LimeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFFCDEB6B),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// White rounded list card. Sizing is left to the content, so a longer
/// (or translated) list can never spill outside the card.
class HelpCard extends StatelessWidget {
  const HelpCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 13, 20, 13),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: const Color(0x14000000)),
        boxShadow: helpCardShadow,
      ),
      child: child,
    );
  }
}

/// Small caps section label that sits above a [HelpCard].
class HelpSectionLabel extends StatelessWidget {
  const HelpSectionLabel(this.text, {super.key});

  static const TextStyle _style = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: Colors.black,
  );

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: _style);
  }
}

/// One tappable row inside a [HelpCard]: icon, title/subtitle and a chevron.
/// The middle column is an [Expanded] with ellipsis, so long labels push the
/// chevron instead of painting over it.
class HelpListRow extends StatelessWidget {
  const HelpListRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.onTap,
  });

  static const TextStyle _titleStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: Colors.black,
  );
  static const TextStyle _subtitleStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: Color(0x7A000000),
  );

  final String? icon;
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Image.asset(icon!, width: 34, height: 34),
            const SizedBox(width: 11),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: titleStyle ?? _titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: _subtitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Image(
            image: AssetImage('assets/help/chevron.png'),
            width: 18,
            height: 18,
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: content,
      ),
    );
  }
}

/// Builds a column of [rows] with dividers in between (no more hard-coded
/// divider coordinates).
Widget helpRowList(List<Widget> rows) {
  final List<Widget> children = <Widget>[];
  for (int i = 0; i < rows.length; i++) {
    if (i > 0) {
      children.add(
        const Divider(height: 1, thickness: 1, color: AppColors.listDivider),
      );
    }
    children.add(rows[i]);
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
}

/// The "Still need help? / Report a problem" call to action shown at the
/// bottom of the topic and article screens.

class ReportHelpCard extends StatelessWidget {
  const ReportHelpCard({
    super.key,
    required this.onTap,
    this.title,
    this.subtitle,
  });

  static const TextStyle _titleStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: Colors.black,
  );

  static const TextStyle _subtitleStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: Color(0x7A000000),
  );

  final VoidCallback onTap;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            border: Border.all(
              color: const Color.fromARGB(120, 6, 63, 2),
            ),
            boxShadow: helpCardShadow,
          ),
          child: Row(
            children: <Widget>[
              Image.asset(
                'assets/help/tile_report.png',
                width: 34,
                height: 34,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      title ?? 'Still need help?',
                      style: _titleStyle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle ?? 'Report a problem',
                      style: _subtitleStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Image(
                image: AssetImage('assets/help/chevron.png'),
                width: 18,
                height: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

