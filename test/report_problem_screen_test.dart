import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/report_problem_screen.dart';

final Uint8List _photoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
  'z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==',
);

Future<void> _loadInter() async {
  const List<String> files = <String>[
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
    'assets/fonts/Inter-ExtraBold.ttf',
  ];
  final FontLoader loader = FontLoader('Inter');
  for (final String file in files) {
    loader.addFont(rootBundle.load(file));
  }
  await loader.load();
}

Future<void> pumpScreen(
  WidgetTester tester, {
  ReportPhotoPicker? photoPicker,
}) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: ReportProblemScreen(photoPicker: photoPicker)),
  );
  await tester.pumpAndSettle();
}

/// Pumps a host page and opens the form on top of it so pops are observable.
Future<void> pumpPushed(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              key: const Key('open-report'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ReportProblemScreen(),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open-report')));
  await tester.pumpAndSettle();
}

Color? chipColor(WidgetTester tester, Key key) {
  final Container container = tester.widget<Container>(
    find.descendant(of: find.byKey(key), matching: find.byType(Container)),
  );
  return (container.decoration! as BoxDecoration).color;
}

void main() {
  testWidgets('renders the Report a problem content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('New request'), findsOneWidget);
    expect(find.text('Tell us the issue'), findsOneWidget);
    expect(find.text('We’ll look into it and get back to you'), findsOneWidget);
    expect(find.text('What is this about?'), findsOneWidget);
    expect(find.text('How should we reach you?'), findsOneWidget);
    expect(find.text('Order'), findsOneWidget);
    expect(find.text('Product'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Order ID'), findsOneWidget);
    expect(find.text('e.g. #NX4582'), findsOneWidget);
    expect(find.text('Tell us what happened'), findsOneWidget);
    expect(find.text('Describe the problem in a few words'), findsOneWidget);
    expect(find.text('Add a photo'), findsOneWidget);
    expect(
      find.text('A screenshot or photo helps us fix it faster'),
      findsOneWidget,
    );
    expect(find.text('Call me'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/order/ic_back.png')),
      findsOneWidget,
    );
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Report a problem')).left, closeTo(68, 3));
    expect(rectOf(find.text('Report a problem')).top, closeTo(22, 4));
    expect(rectOf(find.text('Tell us the issue')).left, closeTo(45, 3));
    expect(rectOf(find.text('Tell us the issue')).top, closeTo(124, 5));
    expect(rectOf(find.text('What is this about?')).left, closeTo(45, 3));
    expect(rectOf(find.text('What is this about?')).top, closeTo(223, 4));
    expect(rectOf(find.text('Order')).left, closeTo(62, 3));
    expect(rectOf(find.text('Order')).top, closeTo(256, 4));
    expect(rectOf(find.text('Order ID')).top, closeTo(335, 4));
    expect(rectOf(find.text('e.g. #NX4582')).left, closeTo(86, 3));
    expect(rectOf(find.text('e.g. #NX4582')).top, closeTo(369, 4));
    expect(rectOf(find.text('Tell us what happened')).top, closeTo(413, 4));
    expect(rectOf(find.text('Add a photo')).top, closeTo(551, 4));
    expect(rectOf(find.text('How should we reach you?')).top, closeTo(643, 4));
    expect(rectOf(find.text('Call me')).left, closeTo(62, 3));
    expect(rectOf(find.text('Call me')).top, closeTo(676, 4));
    expect(rectOf(find.text('Submit')).left, closeTo(181, 3));
    expect(rectOf(find.text('Submit')).top, closeTo(815, 4));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ReportProblemScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('topic chips are single select', (tester) async {
    await pumpScreen(tester);

    const Key order = Key('report-topic-order');
    const Key product = Key('report-topic-product');
    const Key payment = Key('report-topic-payment');

    expect(chipColor(tester, order), Colors.white);

    await tester.tap(find.byKey(product));
    await tester.pumpAndSettle();

    expect(chipColor(tester, product), const Color(0xFF0D3B20));
    expect(chipColor(tester, order), Colors.white);

    await tester.tap(find.byKey(payment));
    await tester.pumpAndSettle();

    expect(chipColor(tester, payment), const Color(0xFF0D3B20));
    expect(chipColor(tester, product), Colors.white);
  });

  testWidgets('contact chips are single select', (tester) async {
    await pumpScreen(tester);

    const Key call = Key('report-contact-call');
    const Key whatsapp = Key('report-contact-whatsapp');

    expect(chipColor(tester, call), isNull);

    await tester.tap(find.byKey(whatsapp));
    await tester.pumpAndSettle();

    expect(chipColor(tester, whatsapp), const Color(0xFF0D3B20));
    expect(chipColor(tester, call), isNull);
  });

  testWidgets('the order id and description accept text', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
      find.byKey(const Key('report-order-id-field')),
      '#NX4582',
    );
    await tester.enterText(
      find.byKey(const Key('report-description-field')),
      'Tomatoes arrived damaged',
    );
    await tester.pump();

    expect(find.text('#NX4582'), findsOneWidget);
    expect(find.text('Tomatoes arrived damaged'), findsOneWidget);
  });

  testWidgets('adds and removes a report photo', (tester) async {
    await pumpScreen(tester, photoPicker: () async => _photoBytes);

    expect(
      find.byWidgetPredicate(
        (Widget w) => w is Image && w.image is MemoryImage,
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('report-photo-tile')));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (Widget w) => w is Image && w.image is MemoryImage,
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('report-photo-remove')));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (Widget w) => w is Image && w.image is MemoryImage,
      ),
      findsNothing,
    );
  });

  testWidgets('a cancelled photo pick leaves the tile empty', (tester) async {
    await pumpScreen(tester, photoPicker: () async => null);

    await tester.tap(find.byKey(const Key('report-photo-tile')));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (Widget w) => w is Image && w.image is MemoryImage,
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('submit asks for the missing fields', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('report-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Choose what this is about.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('report-topic-order')));
    await tester.tap(find.byKey(const Key('report-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tell us what happened.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('report-description-field')),
      'Tomatoes arrived damaged',
    );
    await tester.tap(find.byKey(const Key('report-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Choose how we should reach you.'), findsOneWidget);
  });

  testWidgets('a valid submit confirms and closes the form', (tester) async {
    await pumpPushed(tester);

    await tester.tap(find.byKey(const Key('report-topic-product')));
    await tester.enterText(
      find.byKey(const Key('report-order-id-field')),
      '#NX4582',
    );
    await tester.enterText(
      find.byKey(const Key('report-description-field')),
      'The listing photo is wrong',
    );
    await tester.tap(find.byKey(const Key('report-contact-email')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('report-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Request submitted'), findsOneWidget);
    expect(
      find.text(
        'Thanks! We will look into your product issue and '
        'get back to you via Email.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('report-dialog-done')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsNothing);
    expect(find.byKey(const Key('open-report')), findsOneWidget);
  });

  testWidgets('the back circle pops the form', (tester) async {
    await pumpPushed(tester);

    await tester.tap(find.byKey(const Key('report-back')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsNothing);
    expect(find.byKey(const Key('open-report')), findsOneWidget);
  });

  testWidgets('golden: 200 report a problem at 412x917', (tester) async {
    await _loadInter();
    await pumpScreen(tester);

    await expectLater(
      find.byType(ReportProblemScreen),
      matchesGoldenFile('goldens/report_problem_200.png'),
    );
  });

  testWidgets('golden: 200 report a problem filled at 412x917', (tester) async {
    await _loadInter();
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('report-topic-product')));
    await tester.tap(find.byKey(const Key('report-contact-whatsapp')));
    await tester.enterText(
      find.byKey(const Key('report-order-id-field')),
      '#NX4582',
    );
    await tester.enterText(
      find.byKey(const Key('report-description-field')),
      'Tomatoes arrived damaged',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ReportProblemScreen),
      matchesGoldenFile('goldens/report_problem_200_filled.png'),
    );
  });
}

