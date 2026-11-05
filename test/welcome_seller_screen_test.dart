import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/screens/welcome_seller_screen.dart';
import 'package:seller_app/services/auth_flow.dart';
import 'package:seller_app/theme/app_colors.dart';

import 'fake_auth_flow.dart';

/// Pumps the Welcome Seller screen on the 412x917 artboard the design was
/// drawn for.
Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: WelcomeSellerScreen()));
  await tester.pumpAndSettle();
}

void main() {
  late FakeAuthFlow fake;

  setUp(() {
    fake = FakeAuthFlow();
    AuthFlow.debugOverride = fake;
    SellerProfileStore.instance.reset();
  });

  tearDown(() {
    AuthFlow.debugOverride = null;
    SellerProfileStore.instance.reset();
  });
  testWidgets('renders the Welcome Seller content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Welcome Seller!', findRichText: true), findsOneWidget);
    expect(
      find.text(
        'Let\u2019s grow together.\nSell fresh. Reach further.',
      ),
      findsOneWidget,
    );
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Enter your phone number to proceed'),
      findsOneWidget,
    );
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('+91'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
    expect(
      find.text(
        'By continuing, you agree to Terms & Privacy Policy.',
        findRichText: true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('artwork assets load', (tester) async {
    await pumpScreen(tester);

    final assets = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(assets.length, 4);
    expect(
      assets.map((i) => (i.image as AssetImage).assetName).toSet(),
      {
        WelcomeSellerScreen.leafAsset,
        WelcomeSellerScreen.heroAsset,
        WelcomeSellerScreen.flagAsset,
        WelcomeSellerScreen.sendAsset,
      },
    );
  });

  testWidgets('layout matches the design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    // Hero artwork: full bleed, y 225..504; leaf top-left.
    final hero = rectOf(find.byType(Image).at(1));
    expect(hero.left, closeTo(0, 1));
    expect(hero.width, closeTo(412, 1));
    expect(hero.top, closeTo(225, 1));
    expect(hero.height, closeTo(279, 1));

    final leaf = rectOf(find.byType(Image).first);
    expect(leaf.left, closeTo(0, 1));
    expect(leaf.top, closeTo(64, 1));

    // Title and subtitle anchors.
    final title = rectOf(find.text('Welcome Seller!', findRichText: true));
    expect(title.left, closeTo(0, 1));
    expect(title.top, closeTo(127.4, 1.5));

    final subtitle = rectOf(
      find.text('Let\u2019s grow together.\nSell fresh. Reach further.'),
    );
    expect(subtitle.left, closeTo(0, 1));
    expect(subtitle.top, closeTo(168.7, 1.5));

    // Segmented control: track x 24..386 y 506..558, pill 191 wide.
    final track = rectOf(_findTrack(tester));
    expect(track.left, closeTo(22, 1));
    expect(track.top, closeTo(506, 1));
    expect(track.width, closeTo(362, 1));
    expect(track.height, closeTo(52, 1));

    final pill = rectOf(_findPrimaryContainers(tester).first);
    expect(pill.left, closeTo(22, 1));
    expect(pill.top, closeTo(505, 1));
    expect(pill.width, closeTo(191, 1));
    expect(pill.height, closeTo(53, 1));

    expect(
      rectOf(find.text('Login')).left,
      closeTo(22, 1),
    );
    expect(rectOf(find.text('Login')).top, closeTo(522.6, 1.5));
    expect(rectOf(find.text('Sign Up')).left, closeTo(215, 1));

    // Card copy block.
    expect(rectOf(find.text('Welcome back')).left, closeTo(22, 1));
    expect(rectOf(find.text('Welcome back')).top, closeTo(587.8, 1.5));
    expect(
      rectOf(find.text('Enter your phone number to proceed')).left,
      closeTo(22, 1),
    );
    expect(
      rectOf(find.text('Enter your phone number to proceed')).top,
      closeTo(612.3, 2),
    );
    expect(rectOf(find.text('Phone Number')).left, closeTo(22, 1));
    expect(rectOf(find.text('Phone Number')).top, closeTo(656.5, 1.5));

    // Inputs: country box x 24..107, phone box x 112..389, y 684..738.
    final boxes = _findBorderedBoxes(tester);
    expect(boxes.length, 2);
    final country = rectOf(boxes[0]);
    final phone = rectOf(boxes[1]);
    expect(country.left, closeTo(22, 1));
    expect(country.top, closeTo(684, 1));
    expect(country.width, closeTo(83, 1));
    expect(country.height, closeTo(54, 1));
    expect(phone.left, closeTo(112, 1));
    expect(phone.width, closeTo(277, 1));

    // The field shows a resting caret instead of a placeholder.
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
      isNull,
    );

    // Send OTP button: x 24..388, y 749..801.
    final button = rectOf(_findPrimaryContainers(tester).last);
    expect(button.left, closeTo(22, 1));
    expect(button.top, closeTo(749, 1));
    expect(button.width, closeTo(368, 1));
    expect(button.height, closeTo(52, 1));

    // Footer sits at y 859.
    expect(
      rectOf(
        find.text(
          'By continuing, you agree to Terms & Privacy Policy.',
          findRichText: true,
        ),
      ).top,
      closeTo(859, 1.5),
    );
  });

  testWidgets('text styles follow the design', (tester) async {
    await pumpScreen(tester);

    final title = tester.widget<RichText>(
      find.text('Welcome Seller!', findRichText: true),
    );
    expect(title.text.style?.fontSize, 33);
    expect(
      ((title.text as TextSpan).children![1] as TextSpan).style?.color,
      AppColors.sellerGreen,
    );

    final subtitle = tester.widget<Text>(
      find.text('Let\u2019s grow together.\nSell fresh. Reach further.'),
    );
    expect(subtitle.style?.fontSize, 19);
    expect(subtitle.style?.color, AppColors.subtitleGray);

    final login = tester.widget<Text>(find.text('Login'));
    expect(login.style?.color, AppColors.surface);

    final signUp = tester.widget<Text>(find.text('Sign Up'));
    expect(signUp.style?.color, AppColors.textPrimary);

    final back = tester.widget<Text>(find.text('Welcome back'));
    expect(back.style?.color, AppColors.darkGreen);
    expect(back.style?.fontSize, 18);

    final hint = tester.widget<Text>(
      find.text('Enter your phone number to proceed'),
    );
    expect(hint.style?.color, AppColors.hintGray);

    final label = tester.widget<Text>(find.text('Phone Number'));
    expect(label.style?.color, AppColors.labelGray);

    // Both input boxes share the fill and 1px border from the design.
    final borders = _findBorderedBoxes(tester)
        .map(
          (f) =>
              tester.widget<Container>(f).decoration! as BoxDecoration,
        )
        .toList();
    expect(borders.every((b) => b.color == AppColors.fieldFill), isTrue);
    expect(
      borders.every(
        (b) =>
            b.border!.top.color == AppColors.fieldBorder &&
            b.border!.top.width == 1,
      ),
      isTrue,
    );
  });

  testWidgets('phone field focuses on tap and accepts visible digits',
      (tester) async {
    await pumpScreen(tester);

    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
      isNull,
    );

    // Tapping the field opens the input connection (keyboard on device).
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    // Typed digits are painted in the design's text colour, not transparent.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.color, AppColors.textPrimary);
    expect(field.maxLength, 10, reason: 'India is the default country');

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();

    expect(find.text('9876543210'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    expect(find.text('9876543210'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
      isNull,
    );
  });

  testWidgets('phone input is numeric only and the length follows the '
      'selected country', (tester) async {
    await pumpScreen(tester);

    var field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLength, 10);

    await tester.enterText(find.byType(TextField), '1234567890');
    await tester.pump();
    expect(find.text('1234567890'), findsOneWidget);

    // Letters are stripped - digits only.
    await tester.enterText(find.byType(TextField), 'abc123');
    await tester.pump();
    expect(find.text('123'), findsOneWidget);

    // A longer number fits the default (India, 10).
    await tester.enterText(find.byType(TextField), '1234567890');
    await tester.pump();

    // Pick Singapore: 8 digits (search the full country list first).
    await tester.tap(find.byKey(const Key('countryPicker')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('countrySearch')), 'singa');
    await tester.pump();
    await tester.tap(find.text('Singapore'));
    await tester.pumpAndSettle();

    field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLength, 8);
    // Existing 10-digit number was truncated to the new limit.
    expect(find.text('12345678'), findsOneWidget);
    expect(find.text('1234567890'), findsNothing);

    // Typing cannot exceed the country's length.
    await tester.enterText(find.byType(TextField), '123456789');
    await tester.pump();
    expect(find.text('12345678'), findsOneWidget);
  });

  testWidgets('country box opens the searchable picker with all country '
      'codes and updates the dial code', (tester) async {
    await pumpScreen(tester);

    expect(find.text('+91'), findsOneWidget);

    await tester.tap(find.byKey(const Key('countryPicker')));
    await tester.pumpAndSettle();

    // The redesigned popup: title, search field and the full list scrolling.
    expect(find.text('Select country'), findsOneWidget);
    expect(find.byKey(const Key('countrySearch')), findsOneWidget);
    expect(find.text('Afghanistan'), findsOneWidget);
    expect(find.text('Albania'), findsOneWidget);

    // Searching by name filters the list.
    await tester.enterText(find.byKey(const Key('countrySearch')), 'singa');
    await tester.pump();
    expect(find.text('Singapore'), findsOneWidget);
    expect(find.text('Afghanistan'), findsNothing);

    // No matches show an empty state instead of a broken list.
    await tester.enterText(find.byKey(const Key('countrySearch')), 'zzzzz');
    await tester.pump();
    expect(find.text('No country found'), findsOneWidget);

    // Search by dial code also works.
    await tester.enterText(find.byKey(const Key('countrySearch')), '+971');
    await tester.pump();
    expect(find.text('United Arab Emirates'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('countrySearch')), 'singa');
    await tester.pump();
    await tester.tap(find.text('Singapore'));
    await tester.pumpAndSettle();

    expect(find.text('Select country'), findsNothing);
    expect(find.text('+65'), findsOneWidget);
    expect(find.text('+91'), findsNothing);
  });

  testWidgets('send OTP opens the OTP screen and back returns', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byKey(const Key('loginPhone')), '9876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Enter OTP'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Welcome Seller!', findRichText: true), findsNothing);
    // The E.164 number composed from the picked country reached Firebase.
    expect(fake.sentE164, <String>['+919876543210']);
    expect(fake.sentDisplay, <String>['+91 9876543210']);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('Welcome Seller!', findRichText: true), findsOneWidget);
    expect(find.text('Enter OTP'), findsNothing);
  });

  testWidgets('switching to Sign Up swaps the login form for Name, Phone '
      'Number and Password', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('welcomeTabSignUp')));
    await tester.pumpAndSettle();

    expect(find.text('Name', findRichText: true), findsOneWidget);
    expect(find.text('Phone Number', findRichText: true), findsOneWidget);
    expect(find.text('Password', findRichText: true), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);

    // Same chrome as the login state: hero, title and terms footer stay.
    expect(find.text('Welcome Seller!', findRichText: true), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2), reason: 'leaf + hero');
    expect(
      find.text(
        'By continuing, you agree to Terms & Privacy Policy.',
        findRichText: true,
      ),
      findsOneWidget,
    );

    // The login form is gone in this state.
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Send OTP'), findsNothing);
    expect(find.text('+91'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(3));

    // The fields are typeable.
    await tester.enterText(find.byType(TextField).first, 'Ananya');
    await tester.pump();
    expect(find.text('Ananya'), findsOneWidget);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    final green = _findPrimaryContainers(tester);
    expect(green.length, 2, reason: 'pill + Create account button');

    final pill =
        tester.getRect(green.first).translate(-origin.dx, -origin.dy);
    expect(pill.left, closeTo(195, 2));
    expect(pill.top, closeTo(505, 2));
    expect(pill.width, closeTo(191, 2));

    final button =
        tester.getRect(green.last).translate(-origin.dx, -origin.dy);
    expect(button.left, closeTo(22, 2));
    expect(button.top, closeTo(784, 2));
    expect(button.width, closeTo(368, 2));
    expect(button.height, closeTo(52, 2));
  });

  testWidgets('password field eye icon toggles visibility and turns blue '
      'when the password is shown', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('welcomeTabSignUp')));
    await tester.pumpAndSettle();

    Finder passwordBox() => find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.hintText == 'Password',
        );

    // Hidden by default with a gray eye-off icon.
    expect(tester.widget<TextField>(passwordBox()).obscureText, isTrue);
    final hiddenIcon = tester.widget<Icon>(find.byIcon(Icons.visibility_off));
    expect(hiddenIcon.color, AppColors.hintGray);

    // Tap the eye: password is revealed and the icon becomes a blue eye.
    await tester.tap(find.byKey(const Key('passwordToggle')));
    await tester.pump();
    expect(tester.widget<TextField>(passwordBox()).obscureText, isFalse);
    final shownIcon = tester.widget<Icon>(find.byIcon(Icons.visibility));
    expect(shownIcon.color, AppColors.passwordShown);

    // Tap again: hidden again with the gray eye-off icon.
    await tester.tap(find.byKey(const Key('passwordToggle')));
    await tester.pump();
    expect(tester.widget<TextField>(passwordBox()).obscureText, isTrue);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.visibility_off)).color,
      AppColors.hintGray,
    );
  });

  testWidgets('sign-up layout matches the design geometry', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('welcomeTabSignUp')));
    await tester.pumpAndSettle();

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    // Segmented control keeps the login position.
    final track = rectOf(_findTrack(tester));
    expect(track.left, closeTo(22, 1));
    expect(track.top, closeTo(506, 1));
    expect(track.width, closeTo(362, 1));
    expect(track.height, closeTo(52, 1));

    // Hero artwork is still in place (same design as login).
    final hero = rectOf(find.byType(Image).at(1));
    expect(hero.left, closeTo(0, 1));
    expect(hero.top, closeTo(225, 1));

    final boxes = _findBorderedBoxes(tester);
    expect(boxes.length, 3, reason: 'Name, Phone Number and Password fields');
    const tops = [574, 644, 714];
    for (var i = 0; i < 3; i++) {
      final field = rectOf(boxes[i]);
      expect(field.left, closeTo(22, 1));
      expect(field.width, closeTo(368, 1));
      expect(field.height, closeTo(54, 1));
      expect(field.top, closeTo(tops[i], 1));
    }

    // Placeholder sits inside the first field.
    final name = rectOf(find.text('Name', findRichText: true));
    expect(name.left, closeTo(44, 3));
    expect(name.center.dy, closeTo(601, 4));

    // Terms footer stays at the design position.
    expect(
      rectOf(
        find.text(
          'By continuing, you agree to Terms & Privacy Policy.',
          findRichText: true,
        ),
      ).top,
      closeTo(859, 2),
    );
  });

  testWidgets('tabs switch between Login and Sign Up forms', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('welcomeTabSignUp')));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Send OTP'), findsNothing);

    await tester.tap(find.byKey(const Key('welcomeTabLogin')));
    await tester.pumpAndSettle();
    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('Create account'), findsNothing);
    expect(find.text('Phone Number'), findsOneWidget);

    await tester.tap(find.byKey(const Key('welcomeTabSignUp')));
    await tester.pumpAndSettle();
    expect(find.text('Name', findRichText: true), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('Create account with empty fields goes straight to Home',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('welcomeTabSignUp')));
    await tester.pumpAndSettle();

    // Name, Phone Number and Password are all empty.
    expect(fake.sentE164, isEmpty);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    // No validation snackbar, no OTP — goes straight to Home.
    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(find.text('Enter OTP'), findsNothing);
    expect(fake.sentE164, isEmpty, reason: 'Firebase must not be called');
    expect(
      find.text('Enter a valid 10-digit mobile number.'),
      findsNothing,
      reason: 'no validation error for empty demo',
    );
  });

  testWidgets('Create account with demo credentials goes straight to Home',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('welcomeTabSignUp')));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'john');
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone Number'),
      '1234567890',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'vpnesuxe');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.byType(SellerHomeScreen), findsOneWidget);
    expect(find.text('Enter OTP'), findsNothing);
    expect(fake.sentE164, isEmpty, reason: 'demo login must skip Firebase');
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: WelcomeSellerScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Send OTP'), findsOneWidget);
  });
}

/// Containers filled with the segmented track colour but no border.
Finder _findTrack(WidgetTester tester) {
  final containers = tester
      .widgetList<Container>(find.byType(Container))
      .where(
        (w) =>
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == AppColors.fieldFill &&
            (w.decoration as BoxDecoration).border == null,
      )
      .toList();
  return find.byWidget(containers.first);
}

/// Containers painted with the given colour (e.g. the primary green).
List<Finder> _findColorContainers(WidgetTester tester, Color color) {
  return tester
      .widgetList<Container>(find.byType(Container))
      .where(
        (w) =>
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == color,
      )
      .map(find.byWidget)
      .toList();
}

/// Containers painted with the primary green (login pill, send OTP button).
List<Finder> _findPrimaryContainers(WidgetTester tester) {
  return _findColorContainers(tester, AppColors.primary);
}

/// The two bordered input boxes, in stack order (country, phone). Dividers
/// also paint a bottom-only border, so require a full-width top edge.
List<Finder> _findBorderedBoxes(WidgetTester tester) {
  return tester
      .widgetList<Container>(find.byType(Container))
      .where(
        (w) =>
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).border != null &&
            (w.decoration as BoxDecoration).border!.top.width > 0,
      )
      .map(find.byWidget)
      .toList();
}

