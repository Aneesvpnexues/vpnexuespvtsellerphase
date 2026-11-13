import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';

enum _AboutTab { services, farms, contact }

class AboutVpnexuesScreen extends StatefulWidget {
  const AboutVpnexuesScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double farmsHeight = 1062;
  static const double trimTop = 49;

  @override
  State<AboutVpnexuesScreen> createState() => _AboutVpnexuesScreenState();
}

class _AboutVpnexuesScreenState extends State<AboutVpnexuesScreen> {
  _AboutTab _tab = _AboutTab.services;

  double get _designHeight => _tab == _AboutTab.farms
      ? AboutVpnexuesScreen.farmsHeight
      : AboutVpnexuesScreen.designHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: AboutVpnexuesScreen.designWidth,
          designHeight: _designHeight,
          trimTop: AboutVpnexuesScreen.trimTop,
          child: Stack(
            children: <Widget>[
              const Positioned(left: 22, top: 73, child: _BackCircle()),
              const Positioned(
                left: 68,
                top: 73,
                child: LabelText(
                  'About VP NEXUES',
                  TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: Colors.black,
                  ),
                  width: 165,
                ),
              ),
              const Positioned(left: 22, top: 121, child: _HeroCard()),
              const Positioned(left: 27.5, top: 473, child: _StatsRow()),
              Positioned(
                left: 25,
                top: 541,
                child: _SegmentedTabs(
                  selected: _tab,
                  onChanged: (_AboutTab tab) => setState(() => _tab = tab),
                ),
              ),
              Positioned(
                left: 25,
                top: 596,
                width: 360,
                child: switch (_tab) {
                  _AboutTab.services => const _ServicesPanel(),
                  _AboutTab.farms => const _FarmsPanel(),
                  _AboutTab.contact => const _ContactPanel(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackCircle extends StatelessWidget {
  const _BackCircle();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 25,
        height: 25,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x1A000000), blurRadius: 1),
            BoxShadow(
              color: Color(0x17000000),
              offset: Offset(0, 1),
              blurRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Image.asset('assets/order/ic_back.png', width: 15, height: 15),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 363,
      height: 341,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        gradient: RadialGradient(
          center: Alignment(0.7, -0.88),
          radius: 1,
          colors: <Color>[
            Color(0xFF2E8A4C),
            Color(0xFF0E3F21),
            Color(0xFF0B341B),
          ],
          stops: <double>[0, 0.45, 1],
        ),
        boxShadow: [
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
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 20,
            top: 16,
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 12.5),
              decoration: BoxDecoration(
                color: const Color(0xFF254F26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8FB448), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const <Widget>[
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 10,
                    color: Color(0xFFB7E96D),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Since 2022, Premium Organic',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      color: Color(0xFFB7E96D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 19,
            top: 51.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Rooted in Tamil Nadu.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 30 / 26,
                    leadingDistribution: TextLeadingDistribution.even,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Connected to the world.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 30 / 26,
                    leadingDistribution: TextLeadingDistribution.even,
                    color: AppColors.limeAccent,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 19,
            top: 119.8,
            width: 330,
            child: Text(
              "We connect TamilNadu's finest organic farmers with businesses\nand consumers worldwide.",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.15,
                height: 16.5 / 10,
                leadingDistribution: TextLeadingDistribution.even,
                color: Color(0xFF73A6A7),
              ),
            ),
          ),
          Positioned(
            left: 17,
            top: 170,
            width: 330.5,
            height: 157.5,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Image.asset(
                'assets/business/about_hero.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            left: 28.5,
            top: 291.5,
            child: Container(
              width: 101,
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF3A5233),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFF9CBB5A), width: 0.8),
              ),
              child: Row(
                children: const <Widget>[
                  Icon(Icons.place_outlined, size: 9, color: Color(0xFFCDEB6B)),
                  SizedBox(width: 3),
                  Text(
                    'Tamil Nadu, India',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      height: 1,
                      color: Colors.white,
                    ),
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

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const <Widget>[
        _StatCard(width: 98.5, value: '2022', label: 'Founded'),
        SizedBox(width: 16.5),
        _StatCard(width: 123.5, value: '3', label: 'Core services'),
        SizedBox(width: 16.5),
        _StatCard(width: 102.5, value: 'Global', label: 'Rating'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.value,
    required this.label,
  });

  final double width;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 55.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
              height: 1.1,
              color: Color(0xFF0D3B20),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
              height: 1.1,
              color: Color(0xFF5E5E5E),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.selected, required this.onChanged});

  final _AboutTab selected;
  final ValueChanged<_AboutTab> onChanged;

  static const List<(_AboutTab, String)> _tabs = <(_AboutTab, String)>[
    (_AboutTab.services, 'Services'),
    (_AboutTab.farms, 'Our farms'),
    (_AboutTab.contact, 'Contact'),
  ];
  static const double _segment = 362 / 3;
  static const double _pillWidth = 111;
  static const double _pillInset = 2.5;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 362,
      height: 44,
      child: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE1ECCF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD7E1C6), width: 0.8),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: selected.index * _segment + _pillInset,
            top: 3.5,
            width: _pillWidth,
            height: 37,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(18.5)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x26000000),
                    offset: Offset(0, 4),
                    blurRadius: 9,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: <Widget>[
              for (final (_AboutTab, String) tab in _tabs)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(tab.$1),
                    child: Center(
                      child: Text(
                        tab.$2,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          color: selected == tab.$1
                              ? const Color(0xFF144326)
                              : const Color(0xFF6B7B6F),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServicesPanel extends StatelessWidget {
  const _ServicesPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFEFEFE),
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            offset: Offset(0, 5),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 18, top: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(right: 17.5),
            child: SizedBox(
              height: 58,
              child: _ServiceRow(
                icon: Icons.language,
                title: '100% Organic Products',
                body: 'Serving both businesses and consumers with reliable organic.',
                tag: '100% Pure',
              ),
            ),
          ),
          const _Divider(left: 21),
          const SizedBox(height: 13.5),
          const Padding(
            padding: EdgeInsets.only(right: 17.5),
            child: SizedBox(
              height: 57,
              child: _ServiceRow(
                icon: Icons.eco_outlined,
                title: 'Import & Export',
                body: 'Full-scale import and export operations for organic vegetables, fruits, spices, grains.',
                tag: 'Global',
              ),
            ),
          ),
          const _Divider(left: 21),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.only(right: 17.5),
            child: _ServiceRow(
              icon: Icons.storefront_outlined,
              title: 'B2B & B2C Supply',
              body: 'Serving both businesses and consumers with reliable organic.',
              tag: 'Bulk & Retail',
            ),
          ),
          const SizedBox(height: 20.5),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.tag,
  });

  final IconData icon;
  final String title;
  final String body;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.listIconTile,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Icon(icon, size: 18, color: AppColors.iconDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 15 / 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    height: 17,
                    padding: const EdgeInsets.symmetric(horizontal: 11.5),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.listIconTile,
                      borderRadius: BorderRadius.all(Radius.circular(8.5)),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        height: 1,
                        color: Color(0xFF2E6B34),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 245,
                child: Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.12,
                    height: 12 / 10,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactPanel extends StatelessWidget {
  const _ContactPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFEFEFE),
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            offset: Offset(0, 5),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 20, top: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ContactRow(
            icon: Icons.phone_outlined,
            label: 'PHONE',
            value: '+91 78100 77636',
            action: 'Call',
            actionIcon: Icons.phone_outlined,
            onPressed: () => _launch('tel:+917810077636'),
          ),
          const _Divider(left: 20),
          const SizedBox(height: 11),
          _ContactRow(
            icon: Icons.language,
            label: 'WEBSITE',
            value: 'www.vpnexues.com',
            action: 'Visit',
            actionIcon: Icons.open_in_new,
            onPressed: () => _launch('https://www.vpnexues.com'),
          ),
          const _Divider(left: 20),
          const SizedBox(height: 11),
          _ContactRow(
            icon: Icons.place_outlined,
            label: 'LOCATION',
            value: 'Bengaluru, India',
            action: 'HQ',
            actionIcon: Icons.place_outlined,
            onPressed: () => _launch(
              'https://www.google.com/maps/search/?api=1&query=1st+Main+Road,+Lakshmipathi+Layout,+Lingarajapuram,+Bengaluru,+Karnataka+560084',
            ),
          ),
          const _Divider(left: 20),
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.mail_outline,
            label: 'MAIL',
            value: 'Support@vpnexues.com',
            action: 'Email',
            actionIcon: Icons.mail_outlined,
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(text: 'Support@vpnexues.com'),
              );
              _launch('mailto:Support@vpnexues.com');
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  static Future<void> _launch(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      // canLaunchUrl is unreliable on Android 11+ (package-visibility), so
      // attempt the launch directly and only report genuine failures.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No app available to handle the scheme — nothing else to try.
    }
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.action,
    required this.actionIcon,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String value;
  final String action;
  final IconData actionIcon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.listIconTile,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(icon, size: 18, color: AppColors.iconDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      height: 12 / 9.5,
                      color: Color(0xFFA1A1A1),
                    ),
                  ),
                  const SizedBox(height: 2.5),
                  Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      height: 1.2,
                      color: Color(0xFF0D0D0D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4.5),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPressed,
              child: Container(
                height: 22.5,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: const BoxDecoration(
                  color: AppColors.listIconTile,
                  borderRadius: BorderRadius.all(Radius.circular(11.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      action,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                        color: Color(0xFF2E6B34),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(actionIcon, size: 10, color: const Color(0xFF2E6B34)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
    );
  }
}

class _FarmsPanel extends StatelessWidget {
  const _FarmsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFEFEFE),
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            offset: Offset(0, 5),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 13, 17, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(
            height: 14,
            child: Text(
              'FARM TO TABLE',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                height: 14 / 10,
                color: Color(0xFF708074),
              ),
            ),
          ),
          const SizedBox(height: 7),
          const SizedBox(
            height: 54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'From our Farms.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 26.5 / 23,
                    leadingDistribution: TextLeadingDistribution.even,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'to your Table.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 26.5 / 23,
                    leadingDistribution: TextLeadingDistribution.even,
                    color: Color(0xFF1E7A37),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13.5),
          SizedBox(
            width: 326,
            height: 166,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(11.1271, 78.6569),
                  initialZoom: 7,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.seller_app.seller',
                  ),
                  const MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(11.1271, 78.6569),
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_pin,
                          size: 36,
                          color: Color(0xFF1E7A37),
                        ),
                      ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            height: 58.5,
            child: Text(
              'We follow sustainable farming practices to grow nutritious,\n'
              'chemical-free produce. Our produce is carefully harvested.\n'
              'to ensure maximum natural goodness.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
                height: 19.5 / 10,
                leadingDistribution: TextLeadingDistribution.even,
                color: Color(0xFF8A8A8A),
              ),
            ),
          ),
          const SizedBox(height: 11),
          Container(
            height: 62.5,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[Color(0xFF0B341B), Color(0xFF2B8146)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  offset: Offset(0, 6),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 13,
                  top: 13,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.limeLight,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: const Icon(
                      Icons.eco_outlined,
                      size: 20,
                      color: AppColors.iconDark,
                    ),
                  ),
                ),
                const Positioned(
                  left: 64,
                  top: 13,
                  width: 250,
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: 'Freshness you can trust,',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'quality you',
                          style: TextStyle(color: AppColors.limeLight),
                        ),
                        TextSpan(
                          text: '\ncan rely on.',
                          style: TextStyle(color: AppColors.limeLight),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      height: 18 / 13,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.left});

  final double left;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.only(left: left),
      color: const Color(0xFFECECEC),
    );
  }
}
