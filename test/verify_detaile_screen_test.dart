import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/verify_detaile.dart';
import 'package:seller_app/theme/app_colors.dart';

/// Pumps the verify screen on the 412x873 artboard (top headroom removed).
Future<void> pumpScreen(WidgetTester tester, {Widget? screen}) async {
  tester.view.physicalSize = const Size(412, 873);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: screen ?? const VerifyDetaileScreen()),
  );
  await tester.pumpAndSettle();
}

Finder _tiles() => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).borderRadius ==
          const BorderRadius.all(Radius.circular(10)) &&
      (w.decoration as BoxDecoration).color != null &&
      (w.decoration as BoxDecoration).color != AppColors.surface,
);

Finder _docCards() => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).border != null &&
      (w.decoration as BoxDecoration).borderRadius ==
          const BorderRadius.all(Radius.circular(14)),
);

Finder _continueButton() => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).gradient != null &&
      (w.decoration as BoxDecoration).borderRadius ==
          const BorderRadius.all(Radius.circular(18)),
);

void main() {
  testWidgets('renders the verify content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('STEP 03'), findsOneWidget);
    expect(find.text('Verify your'), findsOneWidget);
    expect(find.text('details'), findsOneWidget);
    expect(find.text('A quick verification'), findsOneWidget);
    expect(find.text('Profile Completion'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Verification Details'), findsOneWidget);
    expect(find.text('All fields are required'), findsOneWidget);
    expect(find.text('Aadhaar card'), findsOneWidget);
    expect(find.text('For individual farmers'), findsOneWidget);
    expect(find.text('PAN Card'), findsOneWidget);
    expect(find.text('For businesses / traders'), findsOneWidget);
    expect(find.text('Business Registration'), findsOneWidget);
    expect(find.text('FSSAI / Udyam / GST (if available)'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('layout matches the design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    // Illustration: x 200..412, y 0..318.
    final illustration = rectOf(find.byType(Image).first);
    expect(illustration.left, closeTo(200, 1));
    expect(illustration.top, closeTo(0, 1));
    expect(illustration.width, closeTo(212, 1));
    expect(illustration.height, closeTo(318, 1));

    // Back arrow.
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    final back = rectOf(find.byIcon(Icons.arrow_back));
    expect(back.left, closeTo(21, 2));
    expect(back.top, closeTo(30, 2));

    // Heading: left 24, design glyph tops 102 / 138.
    expect(rectOf(find.text('Verify your')).left, closeTo(24, 1));
    expect(rectOf(find.text('Verify your')).top, closeTo(99.15, 1));
    expect(rectOf(find.text('details')).top, closeTo(134.79, 1));

    // Subtitle.
    expect(rectOf(find.text('A quick verification')).left, closeTo(24, 1));
    expect(rectOf(find.text('A quick verification')).top, closeTo(180.74, 1));

    // Profile completion card: x 24..386, y 367..428.
    final pcCard = rectOf(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == AppColors.pcCardBg,
      ),
    );
    expect(pcCard.left, closeTo(24, 1));
    expect(pcCard.top, closeTo(367, 1));
    expect(pcCard.width, closeTo(362, 1));
    expect(pcCard.height, closeTo(61, 1));

    expect(rectOf(find.text('Profile Completion')).left, closeTo(34.5, 1));
    expect(rectOf(find.text('Profile Completion')).top, closeTo(381.4, 1));
    expect(rectOf(find.text('75%')).top, closeTo(384.37, 1));

    // Progress track: left 23, top 209.75; active segment second (w 43).
    final segments = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color != null &&
          (w.decoration as BoxDecoration).borderRadius ==
              const BorderRadius.all(Radius.circular(2.5)),
    );
    expect(segments, findsNWidgets(4));
    Rect rectOfElement(Element e) {
      final box = e.renderObject! as RenderBox;
      return box.localToGlobal(Offset.zero) & box.size;
    }

    final segRects = segments.evaluate().map(rectOfElement).toList();
    expect(segRects.first.left, closeTo(23, 1));
    expect(segRects.first.top, closeTo(209.75, 1));
    final segColors = segments
        .evaluate()
        .map(
          (e) => ((e.widget as Container).decoration! as BoxDecoration).color,
        )
        .toList();
    expect(segColors, const [
      AppColors.progressInactive,
      AppColors.verifyAccent,
      AppColors.progressInactive,
      AppColors.progressInactive,
    ]);

    // Section tick + title + pill + divider.
    expect(rectOf(find.text('Verification Details')).left, closeTo(40.5, 1));
    expect(rectOf(find.text('Verification Details')).top, closeTo(452.07, 1));
    final pill = rectOf(find.text('All fields are required'));
    expect(pill.center.dx, closeTo((260 + 387) / 2, 2));
    expect(pill.top, greaterThanOrEqualTo(447));
    expect(pill.bottom, lessThanOrEqualTo(474));

    // Three document cards: x 23..387, tops 497 / 573 / 650, radius 14.
    expect(_docCards(), findsNWidgets(3));
    const cardTops = [497, 573, 650];
    for (var i = 0; i < cardTops.length; i++) {
      final rect = rectOf(_docCards().at(i));
      expect(rect.left, closeTo(23, 1), reason: 'card $i left');
      expect(rect.top, closeTo(cardTops[i], 1), reason: 'card $i top');
      expect(rect.width, closeTo(364, 1), reason: 'card $i width');
      expect(rect.height, closeTo(62, 1), reason: 'card $i height');
    }

    // Three tiles: 40x40, radius 10, left 34, measured tops.
    expect(_tiles(), findsNWidgets(3));
    const tileTops = [508, 585, 661];
    for (var i = 0; i < tileTops.length; i++) {
      final rect = rectOf(_tiles().at(i));
      expect(rect.left, closeTo(34, 1), reason: 'tile $i left');
      expect(rect.top, closeTo(tileTops[i], 1), reason: 'tile $i top');
      expect(rect.width, closeTo(40, 1), reason: 'tile $i width');
      expect(rect.height, closeTo(40, 1), reason: 'tile $i height');
    }

    // Continue button: x 24..388, y 803..857, radius 18.
    final button = rectOf(_continueButton());
    expect(button.left, closeTo(24, 1));
    expect(button.top, closeTo(803, 1));
    expect(button.width, closeTo(364, 1));
    expect(button.height, closeTo(54, 1));
    final decoration =
        tester.widget<Container>(_continueButton()).decoration!
            as BoxDecoration;
    expect(
      decoration.borderRadius,
      const BorderRadius.all(Radius.circular(18)),
    );
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.colors, const [
      AppColors.continueGradientStart,
      AppColors.continueGradientEnd,
    ]);
  });

  testWidgets('text styles follow the design', (tester) async {
    await pumpScreen(tester);

    final step = tester.widget<Text>(find.text('STEP 03'));
    expect(step.style?.fontSize, 14);
    expect(step.style?.color, AppColors.textPrimary);

    final lead = tester.widget<Text>(find.text('Verify your'));
    expect(lead.style?.fontSize, 35);
    expect(lead.style?.color, AppColors.textPrimary);

    final accent = tester.widget<Text>(find.text('details'));
    expect(accent.style?.fontSize, 35);
    expect(accent.style?.color, AppColors.verifyAccent);

    final subtitle = tester.widget<Text>(find.text('A quick verification'));
    expect(subtitle.style?.fontSize, 14);
    expect(subtitle.style?.color, AppColors.verifySubtitle);

    final pcLabel = tester.widget<Text>(find.text('Profile Completion'));
    expect(pcLabel.style?.fontSize, 14);
    expect(pcLabel.style?.color, AppColors.pcLabel);

    final pcPercent = tester.widget<Text>(find.text('75%'));
    expect(pcPercent.style?.fontSize, 14);
    expect(pcPercent.style?.color, AppColors.pcPercent);

    final section = tester.widget<Text>(find.text('Verification Details'));
    expect(section.style?.fontSize, 16);
    expect(section.style?.color, AppColors.verifyInk);

    final note = tester.widget<Text>(find.text('All fields are required'));
    expect(note.style?.fontSize, 11);

    final title = tester.widget<Text>(find.text('Aadhaar card'));
    expect(title.style?.fontSize, 16);
    expect(title.style?.color, AppColors.verifyInk);

    final sub = tester.widget<Text>(find.text('For individual farmers'));
    expect(sub.style?.fontSize, 14);
    expect(sub.style?.color, AppColors.docCardSubtitle);

    final button = tester.widget<Text>(find.text('Continue'));
    expect(button.style?.fontSize, 18);
  });

  testWidgets('renders the document tiles and icons', (tester) async {
    await pumpScreen(tester);

    // Tile 1 uses Material credit_card; tiles 2 and 3 use custom painters.
    expect(find.byIcon(Icons.credit_card), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNWidgets(3));

    final tileColors = _tiles()
        .evaluate()
        .map(
          (e) => ((e.widget as Container).decoration! as BoxDecoration).color,
        )
        .toList();
    expect(tileColors, const [
      AppColors.fieldTileName,
      AppColors.fieldTileBusiness,
      AppColors.fieldTilePhone,
    ]);
  });

  testWidgets('document cards open the picker and show the selected files', (
    tester,
  ) async {
    final picks = <PickedDocument>[
      const PickedDocument(name: 'aadhaar-card.pdf', path: '/tmp/aadhaar.pdf'),
      const PickedDocument(name: 'pan-card.png', path: '/tmp/pan.png'),
      const PickedDocument(name: 'gst-certificate.pdf'),
    ];
    var calls = 0;

    Future<PickedDocument?> picker() async => picks[calls++];

    await pumpScreen(
      tester,
      screen: VerifyDetaileScreen(documentPicker: picker),
    );

    await tester.tap(find.byKey(const Key('verify-doc-aadhaar')));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('aadhaar-card.pdf'), findsOneWidget);
    expect(find.text('For individual farmers'), findsNothing);

    await tester.tap(find.byKey(const Key('verify-doc-pan')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('pan-card.png'), findsOneWidget);
    expect(find.text('For businesses / traders'), findsNothing);

    await tester.tap(find.byKey(const Key('verify-doc-business')));
    await tester.pumpAndSettle();
    expect(calls, 3);
    expect(find.text('gst-certificate.pdf'), findsOneWidget);
    expect(find.text('FSSAI / Udyam / GST (if available)'), findsNothing);

    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
  });

  testWidgets('cancelling the file picker keeps the card unchanged', (
    tester,
  ) async {
    var calls = 0;
    Future<PickedDocument?> picker() async {
      calls++;
      return null;
    }

    await pumpScreen(
      tester,
      screen: VerifyDetaileScreen(documentPicker: picker),
    );

    await tester.tap(find.byKey(const Key('verify-doc-aadhaar')));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.text('For individual farmers'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNWidgets(3));
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('shows an error when the file picker fails', (tester) async {
    Future<PickedDocument?> picker() async {
      throw Exception('picker unavailable');
    }

    await pumpScreen(
      tester,
      screen: VerifyDetaileScreen(documentPicker: picker),
    );

    await tester.tap(find.byKey(const Key('verify-doc-pan')));
    await tester.pumpAndSettle();

    expect(find.text('Could not open the file picker.'), findsOneWidget);
    expect(find.text('For businesses / traders'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNWidgets(3));
  });

  testWidgets('Continue opens the bank-details screen', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Fill Your Bank Details'), findsOneWidget);
    expect(find.text('Account Holder Name'), findsOneWidget);
  });

  testWidgets('back arrow pops the route', (tester) async {
    tester.view.physicalSize = const Size(412, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const VerifyDetaileScreen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Verification Details'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Verification Details'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: VerifyDetaileScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Verification Details'), findsOneWidget);
  });

  testWidgets('uses the verify illustration asset', (tester) async {
    await pumpScreen(tester);

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      VerifyDetaileScreen.illustrationAsset,
    );
    expect(
      VerifyDetaileScreen.illustrationAsset,
      'assets/verify/illustration.png',
    );
  });
}
