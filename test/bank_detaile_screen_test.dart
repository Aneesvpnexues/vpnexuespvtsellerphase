import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/bank_detaile.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/theme/app_colors.dart';

/// Pumps the bank-details screen on the 412x936 artboard the design was drawn
/// for (the design's 44px top headroom removed).
Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 936);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: BankDetaileScreen()));
  await tester.pumpAndSettle();
}

Future<void> enterBankDetails(WidgetTester tester, {bool verify = true}) async {
  await tester.enterText(
    find.byKey(const Key('bank-holder-name-field')),
    'Sita Devi',
  );
  await tester.tap(find.byKey(const Key('bank-selector')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('bank-option-0')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('bank-account-number-field')),
    '987654321098',
  );
  await tester.enterText(
    find.byKey(const Key('bank-ifsc-field')),
    'SBIN0001234',
  );
  await tester.pump();
  if (verify) {
    await tester.tap(find.byKey(const Key('bank-verify-ifsc')));
    await tester.pumpAndSettle();
  }
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
      (w.decoration as BoxDecoration).border?.top.color ==
          AppColors.docCardBorder &&
      (w.decoration as BoxDecoration).borderRadius ==
          const BorderRadius.all(Radius.circular(12)),
);

Finder _inputs() => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).color == AppColors.welcomeBg,
);

Finder _continueButton() => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).gradient != null &&
      (w.decoration as BoxDecoration).borderRadius ==
          const BorderRadius.all(Radius.circular(18)),
);

Finder _pill() => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).border?.top.color ==
          AppColors.verifyPillBorder,
);

Finder _sheet() => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).color == AppColors.surface &&
      (w.decoration as BoxDecoration).borderRadius ==
          const BorderRadius.vertical(top: Radius.circular(40)),
);

Finder _verifyButton() => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).border?.top.color ==
          AppColors.verifiedText &&
      (w.decoration as BoxDecoration).borderRadius ==
          const BorderRadius.all(Radius.circular(7)),
);

Finder _banner() => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).color == AppColors.bankBannerBg,
);

void main() {
  testWidgets('renders the bank-details content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('STEP 05'), findsOneWidget);
    expect(find.text('Add your'), findsOneWidget);
    expect(find.text('bank details'), findsOneWidget);
    expect(find.text('To receive your earnings'), findsOneWidget);
    expect(find.text('Fill Your Bank Details'), findsOneWidget);
    expect(find.text('All fields are required'), findsOneWidget);
    expect(find.text('Account Holder Name'), findsOneWidget);
    expect(find.text('Bank Name'), findsOneWidget);
    expect(find.text('Account Number'), findsOneWidget);
    expect(find.text('IFSC Code'), findsOneWidget);
    expect(find.text('Name should match your bank account'), findsOneWidget);
    expect(find.text('Select your bank'), findsOneWidget);
    expect(find.text('1234 5678 9012'), findsOneWidget);
    expect(find.text('Enter 11-digit code'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Your information is safe with us.'), findsOneWidget);
    expect(
      find.text('We use bank-grade security to protect your details.'),
      findsOneWidget,
    );
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('layout matches the design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    // Illustration: x 190..412, y 26..288 (STEP 04 is baked into the crop).
    final illustration = rectOf(find.byType(Image).first);
    expect(illustration.left, closeTo(190, 1));
    expect(illustration.top, closeTo(26, 1));
    expect(illustration.width, closeTo(222, 1));
    expect(illustration.height, closeTo(262, 1));

    // Back arrow.
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    final back = rectOf(find.byIcon(Icons.arrow_back));
    expect(back.left, closeTo(21, 2));
    expect(back.top, closeTo(30, 2));

    // Step label + headings + subtitle.
    expect(rectOf(find.text('STEP 05')).left, closeTo(25, 1));
    expect(rectOf(find.text('STEP 05')).top, closeTo(89.13, 1));
    expect(rectOf(find.text('Add your')).left, closeTo(24, 1));
    expect(rectOf(find.text('Add your')).top, closeTo(141.79, 1));
    expect(rectOf(find.text('bank details')).left, closeTo(24, 1));
    expect(rectOf(find.text('bank details')).top, closeTo(175.80, 1));
    expect(rectOf(find.text('To receive your earnings')).left, closeTo(25, 1));
    expect(
      rectOf(find.text('To receive your earnings')).top,
      closeTo(218.12, 1),
    );

    // Progress track: left 25, top 118.75; three segments, middle active.
    final segments = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color != null &&
          (w.decoration as BoxDecoration).borderRadius ==
              const BorderRadius.all(Radius.circular(2.5)),
    );
    expect(segments, findsNWidgets(3));
    Rect rectOfElement(Element e) {
      final box = e.renderObject! as RenderBox;
      return box.localToGlobal(Offset.zero) & box.size;
    }

    final segRects = segments.evaluate().map(rectOfElement).toList();
    expect(segRects.first.left, closeTo(25, 1));
    expect(segRects.first.top, closeTo(118.75, 1));
    expect(segRects.first.width, closeTo(29.5, 1));
    expect(segRects[1].width, closeTo(42.5, 1));
    expect(segRects[2].width, closeTo(29.5, 1));
    final segColors = segments
        .evaluate()
        .map(
          (e) => ((e.widget as Container).decoration! as BoxDecoration).color,
        )
        .toList();
    expect(segColors, const [
      AppColors.progressTrack,
      AppColors.progressActive,
      AppColors.progressTrack,
    ]);

    // Sheet: top 287.5, full width, radius 40.
    final sheet = rectOf(_sheet());
    expect(sheet.left, closeTo(0, 1));
    expect(sheet.top, closeTo(287.5, 1));
    expect(sheet.height, closeTo(648.5, 1));

    // Section row: tick, title, pill, divider.
    expect(rectOf(find.text('Fill Your Bank Details')).left, closeTo(41, 1));
    expect(rectOf(find.text('Fill Your Bank Details')).top, closeTo(319.45, 1));
    final pill = rectOf(_pill());
    expect(pill.left, closeTo(261, 1));
    expect(pill.top, closeTo(313, 1));
    expect(pill.width, closeTo(126.5, 1));
    expect(pill.height, closeTo(27.5, 1));
    final divider = rectOf(
      find.byWidgetPredicate(
        (w) => w is Container && w.color == AppColors.docDivider,
      ),
    );
    expect(divider.left, closeTo(26, 1));
    expect(divider.top, closeTo(350, 1));

    // Four cards: x 25..389, tops 363 / 467 / 571 / 675, radius 12.
    expect(_docCards(), findsNWidgets(4));
    const cardTops = [363, 467, 571, 675];
    for (var i = 0; i < cardTops.length; i++) {
      final rect = rectOf(_docCards().at(i));
      expect(rect.left, closeTo(25, 1), reason: 'card $i left');
      expect(rect.top, closeTo(cardTops[i], 1), reason: 'card $i top');
      expect(rect.width, closeTo(364, 1), reason: 'card $i width');
      expect(rect.height, closeTo(93, 1), reason: 'card $i height');
    }

    // Four tiles: 32x32, radius 10, left 36, measured tops.
    expect(_tiles(), findsNWidgets(4));
    const tileTops = [378, 482, 586, 690];
    for (var i = 0; i < tileTops.length; i++) {
      final rect = rectOf(_tiles().at(i));
      expect(rect.left, closeTo(36, 1), reason: 'tile $i left');
      expect(rect.top, closeTo(tileTops[i], 1), reason: 'tile $i top');
      expect(rect.width, closeTo(32, 1), reason: 'tile $i width');
      expect(rect.height, closeTo(32, 1), reason: 'tile $i height');
    }

    // Labels.
    const labelTops = [381.81, 485.81, 589.81, 692.81];
    const labelTexts = [
      'Account Holder Name',
      'Bank Name',
      'Account Number',
      'IFSC Code',
    ];
    for (var i = 0; i < labelTexts.length; i++) {
      final rect = rectOf(find.text(labelTexts[i]));
      expect(rect.left, closeTo(81, 1), reason: '${labelTexts[i]} left');
      expect(
        rect.top,
        closeTo(labelTops[i], 1),
        reason: '${labelTexts[i]} top',
      );
    }

    // Inputs: left 81, tops 402 / 506 / 610 / 714; first three full width,
    // IFSC input narrower.
    expect(_inputs(), findsNWidgets(4));
    const inputTops = [402, 506, 610, 714];
    const inputWidths = [291.5, 291.5, 291.5, 212.5];
    for (var i = 0; i < inputTops.length; i++) {
      final rect = rectOf(_inputs().at(i));
      expect(rect.left, closeTo(81, 1), reason: 'input $i left');
      expect(rect.top, closeTo(inputTops[i], 1), reason: 'input $i top');
      expect(rect.width, closeTo(inputWidths[i], 1), reason: 'input $i width');
      expect(rect.height, closeTo(35.5, 1), reason: 'input $i height');
    }

    // Input texts.
    const inputTopTexts = [415.99, 520.10, 623.67, 727.99];
    const inputLabels = [
      'Name should match your bank account',
      'Select your bank',
      '1234 5678 9012',
      'Enter 11-digit code',
    ];
    for (var i = 0; i < inputLabels.length; i++) {
      final rect = rectOf(find.text(inputLabels[i]));
      expect(rect.left, closeTo(90.5, 1), reason: '${inputLabels[i]} left');
      expect(
        rect.top,
        closeTo(inputTopTexts[i], 1),
        reason: '${inputLabels[i]} top',
      );
    }

    // Verify button: x 301..374.5, y 713.5..750.5.
    final verify = rectOf(_verifyButton());
    expect(verify.left, closeTo(301, 1));
    expect(verify.top, closeTo(713.5, 1));
    expect(verify.width, closeTo(73.5, 1));
    expect(verify.height, closeTo(37, 1));

    // Security banner: x 25..389, y 793..854.
    final banner = rectOf(_banner());
    expect(banner.left, closeTo(25, 1));
    expect(banner.top, closeTo(793, 1));
    expect(banner.width, closeTo(364, 1));
    expect(banner.height, closeTo(61, 1));
    expect(
      rectOf(find.text('Your information is safe with us.')).left,
      closeTo(80.5, 1),
    );
    expect(
      rectOf(find.text('Your information is safe with us.')).top,
      closeTo(808.94, 1),
    );
    expect(
      rectOf(find.text('We use bank-grade security to protect your details.'))
          .top,
      closeTo(827.99, 1),
    );

    // Continue button: bottom-anchored, x 10..402, y 866..920 on the 936
    // artboard, radius 18, gradient fill.
    final button = rectOf(_continueButton());
    expect(button.left, closeTo(10, 1));
    expect(button.top, closeTo(866, 1));
    expect(button.width, closeTo(392, 1));
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

    final step = tester.widget<Text>(find.text('STEP 05'));
    expect(step.style?.fontSize, 15.5);
    expect(step.style?.color, AppColors.stepLabelMuted);

    final lead = tester.widget<Text>(find.text('Add your'));
    expect(lead.style?.fontSize, 35);
    expect(lead.style?.color, AppColors.textPrimary);

    // The gradient accent keeps the base heading style; ShaderMask paints it.
    final accent = tester.widget<Text>(find.text('bank details'));
    expect(accent.style?.fontSize, 35);

    final subtitle = tester.widget<Text>(find.text('To receive your earnings'));
    expect(subtitle.style?.fontSize, 14);
    expect(subtitle.style?.color, AppColors.bankSubtitle);

    final section = tester.widget<Text>(find.text('Fill Your Bank Details'));
    expect(section.style?.fontSize, 16);
    expect(section.style?.color, AppColors.bankSectionTitle);

    final note = tester.widget<Text>(find.text('All fields are required'));
    expect(note.style?.fontSize, 11);

    final label = tester.widget<Text>(find.text('Account Holder Name'));
    expect(label.style?.fontSize, 13);
    expect(label.style?.color, AppColors.verifyInk);

    final input = tester.widget<Text>(find.text('Select your bank'));
    expect(input.style?.fontSize, 11);
    expect(input.style?.color, AppColors.bankInputText);

    final verify = tester.widget<Text>(find.text('Verify'));
    expect(verify.style?.fontSize, 10);
    expect(verify.style?.color, AppColors.verifiedText);

    final bannerTitle = tester.widget<Text>(
      find.text('Your information is safe with us.'),
    );
    expect(bannerTitle.style?.fontSize, 13);
    expect(bannerTitle.style?.color, AppColors.verifiedText);

    final bannerBody = tester.widget<Text>(
      find.text('We use bank-grade security to protect your details.'),
    );
    expect(bannerBody.style?.fontSize, 11);
    expect(bannerBody.style?.color, AppColors.bankBannerSub);

    final button = tester.widget<Text>(find.text('Continue'));
    expect(button.style?.fontSize, 18);
  });

  testWidgets('renders the field tiles, chevron and shield', (tester) async {
    await pumpScreen(tester);

    // All four tile icons are custom painters (person / bank / cards).
    expect(find.byType(CustomPaint), findsWidgets);

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
      AppColors.fieldTileLocation,
    ]);

    // The active card's shadow must not show through its interior.
    final cardColors = _docCards()
        .evaluate()
        .map(
          (e) => ((e.widget as Container).decoration! as BoxDecoration).color,
        )
        .toList();
    expect(cardColors, List.filled(4, AppColors.surface));

    // Dropdown chevron is a custom painter, not a Material icon.
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);

    // Shield sits in a light-green circle.
    final shield = tester.widget<Container>(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == AppColors.bankShieldCircle,
      ),
    );
    expect((shield.decoration! as BoxDecoration).shape, BoxShape.circle);
  });

  testWidgets('fields accept input and the bank can be changed', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.byKey(const Key('bank-holder-name-field')),
      'Sita Devi',
    );
    await tester.enterText(
      find.byKey(const Key('bank-account-number-field')),
      '987654321098',
    );
    await tester.enterText(
      find.byKey(const Key('bank-ifsc-field')),
      'sbin0001234',
    );
    await tester.pump();

    expect(find.text('Sita Devi'), findsOneWidget);
    expect(find.text('9876 5432 1098'), findsOneWidget);
    expect(find.text('SBIN0001234'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bank-selector')));
    await tester.pumpAndSettle();
    expect(find.text('Select bank'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bank-option-1')));
    await tester.pumpAndSettle();
    expect(find.text('HDFC Bank'), findsOneWidget);
    expect(find.text('Select bank'), findsNothing);
  });

  testWidgets('Verify validates and resets the IFSC state', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.byKey(const Key('bank-ifsc-field')),
      'SBIN1234',
    );
    await tester.tap(find.byKey(const Key('bank-verify-ifsc')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid 11-character IFSC code.'), findsOneWidget);
    expect(find.text('Verified'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('bank-ifsc-field')),
      'SBIN0001234',
    );
    await tester.tap(find.byKey(const Key('bank-verify-ifsc')));
    await tester.pumpAndSettle();
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Verify'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('bank-ifsc-field')),
      'HDFC0001234',
    );
    await tester.pump();
    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Verified'), findsNothing);
  });

  testWidgets('Continue validates the details in order before opening home', (
    tester,
  ) async {
    await pumpScreen(tester);

    // Snackbar messages are matched inside the SnackBar itself so the
    // identical placeholder text in the bank input does not match.
    Finder snackbarText(String message) => find.descendant(
      of: find.byType(SnackBar),
      matching: find.text(message),
    );

    Future<void> tapContinue() async {
      await tester.tap(find.byKey(const Key('bank-continue')));
      await tester.pumpAndSettle();
    }

    // 1. Account holder name is missing.
    await tapContinue();
    expect(snackbarText('Enter your account holder name'), findsOneWidget);
    expect(find.byType(SellerHomeScreen), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // 2. No bank picked yet.
    await tester.enterText(
      find.byKey(const Key('bank-holder-name-field')),
      'Sita Devi',
    );
    await tester.pump();
    await tapContinue();
    expect(snackbarText('Select your bank'), findsOneWidget);
    expect(find.byType(SellerHomeScreen), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // 3. Account number too short.
    await tester.tap(find.byKey(const Key('bank-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bank-option-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('bank-account-number-field')),
      '123',
    );
    await tester.pump();
    await tapContinue();
    expect(
      snackbarText('Account number must be at least 9 digits'),
      findsOneWidget,
    );
    expect(find.byType(SellerHomeScreen), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // 4. IFSC not verified yet.
    await tester.enterText(
      find.byKey(const Key('bank-account-number-field')),
      '987654321098',
    );
    await tester.enterText(
      find.byKey(const Key('bank-ifsc-field')),
      'SBIN0001234',
    );
    await tester.pump();
    await tapContinue();
    expect(
      snackbarText('Verify your IFSC code to continue'),
      findsOneWidget,
    );
    expect(find.byType(SellerHomeScreen), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // 5. Everything filled in: the home page opens.
    await tester.tap(find.byKey(const Key('bank-verify-ifsc')));
    await tester.pumpAndSettle();
    await tapContinue();

    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(find.byType(BankDetaileScreen), findsNothing);
  });

  testWidgets('back arrow pops the route', (tester) async {
    tester.view.physicalSize = const Size(412, 936);
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
                    builder: (_) => const BankDetaileScreen(),
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
    expect(find.text('Fill Your Bank Details'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Fill Your Bank Details'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('Continue opens the home page once the details are valid', (
    tester,
  ) async {
    await pumpScreen(tester);
    await enterBankDetails(tester);

    await tester.tap(find.byKey(const Key('bank-continue')));
    await tester.pumpAndSettle();

    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(find.text('Hello,'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('ACTIVE ORDERS'), findsOneWidget);
    // Onboarding is cleared from the stack.
    expect(find.text('Fill Your Bank Details'), findsNothing);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: BankDetaileScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Fill Your Bank Details'), findsOneWidget);
  });

  testWidgets('uses the bank illustration asset', (tester) async {
    await pumpScreen(tester);

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      BankDetaileScreen.illustrationAsset,
    );
    expect(BankDetaileScreen.illustrationAsset, 'assets/bank/illustration.png');
  });
}
