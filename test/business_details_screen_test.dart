import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/screens/bank_detaile.dart';
import 'package:seller_app/screens/business_details_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/screens/verify_detaile.dart';
import 'package:seller_app/theme/app_colors.dart';

/// Pumps the STEP 03 screen on the 412x917 artboard the design was drawn for.
Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const MaterialApp(home: Step03BusinessDetailsScreen()),
  );
  await tester.pumpAndSettle();
}

Finder _tiles() => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).borderRadius ==
          const BorderRadius.all(Radius.circular(8)) &&
      (w.decoration as BoxDecoration).color != null &&
      (w.decoration as BoxDecoration).color != AppColors.surface,
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
  late List<Map<String, String>> savedProfiles;

  setUp(() {
    savedProfiles = <Map<String, String>>[];
    SellerProfileStore.instance.resetCompletionFlags();
    Step03BusinessDetailsScreen.debugProfileSaver = ({
      required String name,
      required String mobile,
      required String sellerType,
      required String businessName,
      required String businessLocation,
      required String businessAddress,
    }) async {
      savedProfiles.add(<String, String>{
        'name': name,
        'mobile': mobile,
        'seller_type': sellerType,
        'business_name': businessName,
        'location': businessLocation,
        'business_address': businessAddress,
      });
      return '9df39d4b-5d7a-457e-80a9-8f40dd0807e9';
    };
  });

  tearDown(() {
    Step03BusinessDetailsScreen.debugProfileSaver = null;
    SellerProfileStore.instance.resetCompletionFlags();
  });

  testWidgets('renders the STEP 03 content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('STEP 03'), findsOneWidget);
    expect(find.text('Tell us about'), findsOneWidget);
    expect(find.text('your'), findsOneWidget);
    expect(find.text('business'), findsOneWidget);
    expect(find.text("Let's create your profile"), findsOneWidget);
    expect(find.text('Business Details'), findsOneWidget);
    expect(find.text('All fields are required'), findsOneWidget);
    // Field rows.
    expect(find.text('Your name'), findsOneWidget);
    expect(find.text('Enter your name..'), findsOneWidget);
    expect(find.text('Business / Farm Name'), findsOneWidget);
    expect(find.text('Enter Business name'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('+91 12345 67890'), findsOneWidget);
    expect(find.text('Business Location'), findsOneWidget);
    expect(find.text('Salem, Tamil Nadu'), findsOneWidget);
    expect(find.text('Business Address'), findsOneWidget);
    expect(find.text('Enter your full address....'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('layout matches the design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    // Leaves: x 200..412, y 0..560.
    final leaves = rectOf(find.byType(Image).first);
    expect(leaves.left, closeTo(200, 1));
    expect(leaves.top, closeTo(0, 1));
    expect(leaves.width, closeTo(212, 1));
    expect(leaves.height, closeTo(560, 1));

    // Heading: left 24, design glyph tops 165.5 / 200.
    expect(rectOf(find.text('Tell us about')).left, closeTo(22, 1));
    expect(rectOf(find.text('Tell us about')).top, closeTo(162.33, 1));
    expect(rectOf(find.text('your')).top, closeTo(196.83, 1));
    expect(rectOf(find.text('business')).top, closeTo(196.83, 1));

    // Subtitle, section title.
    expect(rectOf(find.text("Let's create your profile")).left, closeTo(22, 1));
    expect(
      rectOf(find.text("Let's create your profile")).top,
      closeTo(248.2, 1),
    );
    expect(rectOf(find.text('Business Details')).left, closeTo(22, 1));
    expect(rectOf(find.text('Business Details')).top, closeTo(330.89, 1));

    // Pill note: fixed box x 261..387.5, y 326..353.
    final pill = rectOf(find.text('All fields are required'));
    expect(pill.center.dx, closeTo((261 + 387.5) / 2, 2));
    expect(pill.top, greaterThanOrEqualTo(326));
    expect(pill.bottom, lessThanOrEqualTo(353));

    // Five field tiles: 40x40, radius 8, left 24, measured tops.
    expect(_tiles(), findsNWidgets(5));
    const tops = [380.5, 457.5, 533.5, 611.5, 688.5];
    for (var i = 0; i < tops.length; i++) {
      final rect = rectOf(_tiles().at(i));
      expect(rect.left, closeTo(22, 1), reason: 'tile $i left');
      expect(rect.top, closeTo(tops[i], 1), reason: 'tile $i top');
      expect(rect.width, closeTo(40, 1), reason: 'tile $i width');
      expect(rect.height, closeTo(40, 1), reason: 'tile $i height');
    }

    // Continue button: x 24..388, y 847..901, radius 18, gradient fill.
    final button = rectOf(_continueButton());
    expect(button.left, closeTo(22, 1));
    expect(button.top, closeTo(847, 1));
    expect(button.width, closeTo(368, 1));
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
      AppColors.continueDisabledGradientStart,
      AppColors.continueDisabledGradientEnd,
    ]);
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('text styles follow the design', (tester) async {
    await pumpScreen(tester);

    final step = tester.widget<Text>(find.text('STEP 03'));
    expect(step.style?.fontSize, 15.5);
    expect(step.style?.color, AppColors.stepLabelMuted);

    final lead = tester.widget<Text>(find.text('Tell us about'));
    expect(lead.style?.fontSize, 35);
    expect(lead.style?.color, AppColors.textPrimary);

    final accent = tester.widget<Text>(find.text('business'));
    expect(accent.style?.fontSize, 35);

    final subtitle = tester.widget<Text>(
      find.text("Let's create your profile"),
    );
    expect(subtitle.style?.fontSize, 16);

    final section = tester.widget<Text>(find.text('Business Details'));
    expect(section.style?.fontSize, 16);
    expect(section.style?.color, AppColors.sectionTitle);

    final note = tester.widget<Text>(find.text('All fields are required'));
    expect(note.style?.fontSize, 11.5);

    final notePill = tester.widget<Container>(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == AppColors.surface &&
            (w.decoration as BoxDecoration).border != null,
      ),
    );
    final noteDecoration = notePill.decoration! as BoxDecoration;
    expect(noteDecoration.gradient, isNull);
    expect(
      (noteDecoration.border! as Border).top.color,
      AppColors.verifyPillBorder,
    );

    final label = tester.widget<Text>(find.text('Your name'));
    expect(label.style?.fontSize, 14);

    final placeholder = tester.widget<Text>(find.text('Enter your name..'));
    expect(placeholder.style?.fontSize, 14);

    // The phone row holds its value in a TextField, so assert the field style.
    final phoneField = tester.widget<TextField>(
      find.byKey(const Key('businessPhone')),
    );
    expect(phoneField.style?.fontSize, 14);

    final verified = tester.widget<Text>(find.text('Verified'));
    expect(verified.style?.fontSize, 11.5);

    final change = tester.widget<Text>(find.text('Change'));
    expect(change.style?.fontSize, 14);
  });

  testWidgets('renders the field icons and tile colors', (tester) async {
    await pumpScreen(tester);

    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    final tileIcons = icons.where((i) => i.size == 22).toList();
    expect(tileIcons.length, 5);
    expect(
      tileIcons.map((i) => i.icon),
      containsAll(<IconData>[
        Icons.person_outline,
        Icons.business,
        Icons.phone_outlined,
        Icons.location_on_outlined,
        Icons.home_outlined,
      ]),
    );

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
      AppColors.fieldTileAddress,
    ]);
  });

  testWidgets('the keyboard scrolls the focused field above the inset', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.byKey(const Key('businessAddress')),
      '12 Main Street',
    );
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    final field = tester.getRect(find.byKey(const Key('businessAddress')));
    expect(field.bottom, lessThanOrEqualTo(917 - 360));
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Step03BusinessDetailsScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Business Details'), findsOneWidget);
  });

  testWidgets('uses the step03 leaves asset', (tester) async {
    await pumpScreen(tester);

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      Step03BusinessDetailsScreen.leavesAsset,
    );
    expect(Step03BusinessDetailsScreen.leavesAsset, 'assets/step03/leaves.png');
  });

  testWidgets('Continue is inert until every field is filled', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Business Details'), findsOneWidget);
    expect(find.text('Verification Details'), findsNothing);

    // Fill name + business only (phone/location start prefilled, address empty).
    await tester.enterText(find.byKey(const Key('businessName')), 'Ravi');
    await tester.enterText(find.byKey(const Key('businessFarm')), 'Green Farm');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Business Details'), findsOneWidget);
    expect(find.text('Verification Details'), findsNothing);
  });

  testWidgets('whitespace-only input does not count as filled', (tester) async {
    await pumpScreen(tester);

    // Spaces-only name / business / address must not enable Continue.
    await tester.enterText(find.byKey(const Key('businessName')), '   ');
    await tester.enterText(find.byKey(const Key('businessFarm')), '  ');
    await tester.enterText(find.byKey(const Key('businessAddress')), '   ');
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Business Details'), findsOneWidget);
    expect(find.text('Verification Details'), findsNothing);

    // Real values on all three rows let the flow continue.
    await tester.enterText(find.byKey(const Key('businessName')), 'Ravi');
    await tester.enterText(
        find.byKey(const Key('businessFarm')), 'Green Farm');
    await tester.enterText(
        find.byKey(const Key('businessAddress')), '12 Main Street');
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Verification Details'), findsOneWidget);
  });

  testWidgets('Continue opens the verify details screen', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(const Key('businessName')), 'Ravi');
    await tester.enterText(find.byKey(const Key('businessFarm')), 'Green Farm');
    await tester.enterText(
      find.byKey(const Key('businessAddress')),
      '12 Main Street',
    );
    await tester.pump();

    final decoration =
        tester.widget<Container>(_continueButton()).decoration!
            as BoxDecoration;
    expect((decoration.gradient! as LinearGradient).colors, const [
      AppColors.continueGradientStart,
      AppColors.continueGradientEnd,
    ]);
    expect(decoration.boxShadow, isNotNull);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your'), findsOneWidget);
    expect(find.text('Verification Details'), findsOneWidget);

    // The profile is saved before the screen moves on.
    expect(savedProfiles, hasLength(1));
    expect(savedProfiles.single, <String, String>{
      'name': 'Ravi',
      'mobile': '+91 12345 67890',
      'seller_type': 'farmer',
      'business_name': 'Green Farm',
      'location': 'Salem, Tamil Nadu',
      'business_address': '12 Main Street',
    });

    // Back arrow returns to STEP 03.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Business Details'), findsOneWidget);
    expect(find.text('Verify your'), findsNothing);
  });

  Future<void> fillAndContinue(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('businessName')), 'Ravi');
    await tester.enterText(find.byKey(const Key('businessFarm')), 'Green Farm');
    await tester.enterText(
      find.byKey(const Key('businessAddress')),
      '12 Main Street',
    );
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('Continue opens Home when verify and bank are already done', (
    tester,
  ) async {
    SellerProfileStore.instance.setCompletion(
      profileComplete: false,
      bankComplete: true,
      verificationComplete: true,
      personalComplete: true,
    );

    await pumpScreen(tester);
    await fillAndContinue(tester);

    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(find.byType(VerifyDetaileScreen), findsNothing);
    expect(find.byType(BankDetaileScreen), findsNothing);
    expect(savedProfiles, hasLength(1));
  });

  testWidgets('Continue skips verify and opens bank when only KYC is done', (
    tester,
  ) async {
    SellerProfileStore.instance.setCompletion(
      profileComplete: false,
      bankComplete: false,
      verificationComplete: true,
      personalComplete: true,
    );

    await pumpScreen(tester);
    await fillAndContinue(tester);

    expect(find.byType(BankDetaileScreen), findsOneWidget);
    expect(find.byType(VerifyDetaileScreen), findsNothing);
    expect(find.byType(SellerHomeScreen), findsNothing);
  });
}

