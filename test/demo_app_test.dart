import 'package:flutter_test/flutter_test.dart';
import 'package:l3b_splash/main.dart';
import 'package:l3b_splash/splash/l3b_logo.dart';
import 'package:l3b_splash/splash/l3b_splash_screen.dart';

void main() {
  testWidgets('shows the splash, then the app, and can play it again', (
    tester,
  ) async {
    await tester.pumpWidget(const SplashDemoApp());
    await tester.pump();
    expect(find.byType(L3bSplashScreen), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);

    // The splash, and the page fading in after it.
    await tester.pump(const Duration(milliseconds: 4550));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(L3bSplashScreen), findsNothing);
    expect(find.byType(L3bLogoView), findsOneWidget);

    await tester.tap(find.text('Replay splash'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(L3bSplashScreen), findsOneWidget);

    // Let it finish: nothing is left running.
    await tester.pump(const Duration(milliseconds: 4650));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(HomePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
