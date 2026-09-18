import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'engine/csound_engine.dart';
import 'engine/engine.dart';
import 'engine/fake_engine.dart';
import 'state/providers.dart';
import 'ui/tracker_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final Engine engine = Platform.isAndroid ? CsoundEngine() : FakeEngine();
  runApp(
    ProviderScope(
      overrides: [engineProvider.overrideWithValue(engine)],
      child: const TrackestApp(),
    ),
  );
}

class TrackestApp extends StatelessWidget {
  const TrackestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trackest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TrackerScreen(),
    );
  }
}
