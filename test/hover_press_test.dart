import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/widgets/hover_press.dart';

const Key _target = Key('hover-target');

double _scale(WidgetTester tester) {
  return tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('rest, hover and press follow the icon preset', (tester) async {
    await _pump(
      tester,
      const HoverPress.icon(
        child: SizedBox(key: _target, width: 44, height: 44),
      ),
    );
    expect(_scale(tester), 1);

    final TestGesture mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byKey(_target)));
    await tester.pumpAndSettle();
    expect(_scale(tester), 1.12);

    await mouse.moveTo(const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(_scale(tester), 1);

    final TestGesture touch = await tester.startGesture(
      tester.getCenter(find.byKey(_target)),
    );
    await tester.pumpAndSettle();
    expect(_scale(tester), 0.88);

    await touch.up();
    await tester.pumpAndSettle();
    expect(_scale(tester), 1);
  });

  testWidgets('dragging past the slop cancels the pressed state', (
    tester,
  ) async {
    await _pump(
      tester,
      const HoverPress.button(
        child: SizedBox(key: _target, width: 120, height: 54),
      ),
    );

    final TestGesture touch = await tester.startGesture(
      tester.getCenter(find.byKey(_target)),
    );
    await tester.pumpAndSettle();
    expect(_scale(tester), 0.97);

    await touch.moveBy(const Offset(20, 0));
    await tester.pumpAndSettle();
    expect(_scale(tester), 1);

    await touch.up();
    await tester.pumpAndSettle();
    expect(_scale(tester), 1);
  });

  testWidgets('does not animate while disabled', (tester) async {
    await _pump(
      tester,
      const HoverPress.button(
        enabled: false,
        child: SizedBox(key: _target, width: 120, height: 54),
      ),
    );

    final TestGesture mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byKey(_target)));
    await tester.pumpAndSettle();
    expect(_scale(tester), 1);

    final TestGesture touch = await tester.startGesture(
      tester.getCenter(find.byKey(_target)),
    );
    await tester.pumpAndSettle();
    expect(_scale(tester), 1);
    await touch.up();
  });

  testWidgets('wrapped control still receives taps', (tester) async {
    int taps = 0;
    await _pump(
      tester,
      GestureDetector(
        onTap: () => taps++,
        child: const HoverPress(
          child: SizedBox(key: _target, width: 120, height: 54),
        ),
      ),
    );

    await tester.tap(find.byType(HoverPress));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('honours reduced-motion settings', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: HoverPress(
              child: const SizedBox(key: _target, width: 120, height: 54),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
      Duration.zero,
    );
  });
}
