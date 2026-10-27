import 'package:flutter/material.dart';

import 'splash/l3b_logo.dart';
import 'splash/l3b_splash_screen.dart';

void main() => runApp(const SplashDemoApp());

class SplashDemoApp extends StatelessWidget {
  const SplashDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '5L3B',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0A2B60),
      ),
      home: const SplashGate(),
    );
  }
}

/// Shows the splash, then the app.
class SplashGate extends StatelessWidget {
  const SplashGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: L3bSplashScreen(
        onFinished: () => Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, _, _) => const HomePage(),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
      ),
    );
  }
}

/// Stands for the app: the logo at rest and a way to see the splash again.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const L3bLogoView(width: 260),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const SplashGate()),
              ),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Replay splash'),
            ),
          ],
        ),
      ),
    );
  }
}
