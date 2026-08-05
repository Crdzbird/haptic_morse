import 'package:flutter/material.dart';
import 'package:haptic_morse/haptic_morse.dart';
import 'package:haptic_morse/haptic_morse_vibration.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HapticMorse Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'HapticMorse'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _haptics = HapticVibration();

  final _controller = TextEditingController(text: 'HOLA');
  HapticModel _message = const HapticModel();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final message = _controller.text.toMorseModel();
    setState(() => _message = message);
    await _haptics.vibrateEvents(message.events);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 24),
            Text('Morse', style: theme.textTheme.labelLarge),
            SelectableText(
              _message.morseCode.isEmpty ? '—' : _message.morseCode,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${_message.events.length} events · '
              '${_message.totalDuration}ms',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Expanded(child: _EventList(events: _message.events)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _play,
        icon: const Icon(Icons.vibration),
        label: const Text('Play'),
      ),
    );
  }
}

/// Renders the sequence as a strip, vibrations filled and gaps hollow.
class _EventList extends StatelessWidget {
  const _EventList({required this.events});

  final List<HapticEvent> events;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final event in events)
            Tooltip(
              // Exhaustive: adding a variant to the sealed type breaks this
              // switch at compile time rather than silently falling through.
              message: switch (event) {
                HapticDot() => 'dot',
                HapticDash() => 'dash',
                HapticSymbolGap() => 'symbol gap',
                HapticLetterGap() => 'letter gap',
                HapticWordGap() => 'word gap',
              },
              child: Container(
                width: event.duration / 8,
                height: event.isVibration ? 40 : 8,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: event.isVibration
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
