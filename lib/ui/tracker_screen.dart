import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'note_pad.dart';
import 'pattern_grid.dart';
import 'transport_bar.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final notifier = ref.read(projectProvider.notifier);
    try {
      notifier.samplePath = await _extractSample();
    } catch (_) {
      notifier.samplePath = '';
    }
    try {
      await notifier.restartEngine();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  /// Copies the bundled kick to a real file path so Csound's GEN01 can read it.
  Future<String> _extractSample() async {
    final data = await rootBundle.load('assets/kick.wav');
    final file = File('${Directory.systemTemp.path}/trackest_kick.wav');
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TransportBar(),
            if (_error != null)
              MaterialBanner(
                content: Text(
                  _error!,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _error = null),
                    child: const Text('OK'),
                  ),
                ],
              ),
            const Expanded(child: PatternGrid()),
            const NotePad(),
          ],
        ),
      ),
    );
  }
}
