import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultiBindEvent', () {
    testWidgets('calls typed event handler when event fires', (tester) async {
      final event = ViewModelEvent<String>();
      String? received;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBindEvent(
            handlers: [
              EventHandler<String>(event, (ctx, msg) => received = msg),
            ],
            child: const Text('child'),
          ),
        ),
      );

      event.fire('hello');
      expect(received, 'hello');

      event.dispose();
    });

    testWidgets('calls signal handler when signal fires', (tester) async {
      final signal = SignalEvent();
      var signalCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBindEvent(
            handlers: const [],
            signalHandlers: [SignalHandler(signal, (ctx) => signalCount++)],
            child: const Text('child'),
          ),
        ),
      );

      signal.fire();
      expect(signalCount, 1);

      signal.dispose();
    });

    testWidgets('handles multiple events of different types', (tester) async {
      final errorEvent = ViewModelEvent<String>();
      final successEvent = ViewModelEvent<String>();
      final closeSignal = SignalEvent();

      final messages = <String>[];
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBindEvent(
            handlers: [
              EventHandler<String>(
                errorEvent,
                (ctx, msg) => messages.add('error:$msg'),
              ),
              EventHandler<String>(
                successEvent,
                (ctx, msg) => messages.add('success:$msg'),
              ),
            ],
            signalHandlers: [
              SignalHandler(closeSignal, (ctx) => closed = true),
            ],
            child: const Text('child'),
          ),
        ),
      );

      errorEvent.fire('fail');
      successEvent.fire('ok');
      closeSignal.fire();

      expect(messages, ['error:fail', 'success:ok']);
      expect(closed, isTrue);

      errorEvent.dispose();
      successEvent.dispose();
      closeSignal.dispose();
    });

    testWidgets('renders child without rebuilding it', (tester) async {
      final event = ViewModelEvent<String>();
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBindEvent(
            handlers: [EventHandler<String>(event, (ctx, msg) {})],
            child: _BuildCounter(onBuild: () => buildCount++),
          ),
        ),
      );

      expect(buildCount, 1);

      // Firing the event should NOT rebuild the child.
      event.fire('test');
      await tester.pump();
      expect(buildCount, 1);

      event.dispose();
    });

    testWidgets('cleans up listeners on dispose', (tester) async {
      final event = ViewModelEvent<String>();
      String? received;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBindEvent(
            handlers: [
              EventHandler<String>(event, (ctx, msg) => received = msg),
            ],
            child: const Text('child'),
          ),
        ),
      );

      // Remove the widget from the tree (triggers dispose).
      await tester.pumpWidget(const MaterialApp(home: Text('replaced')));

      event.fire('after-dispose');
      // Handler should not be called since listeners are cleaned up.
      expect(received, isNull);

      event.dispose();
    });

    testWidgets('re-wires when handler list identity changes', (tester) async {
      final eventA = ViewModelEvent<String>();
      final eventB = ViewModelEvent<String>();
      String? received;

      // Initial: listen to eventA.
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBindEvent(
            handlers: [
              EventHandler<String>(eventA, (ctx, msg) => received = msg),
            ],
            child: const Text('child'),
          ),
        ),
      );

      // Update: listen to eventB instead (new list identity).
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBindEvent(
            handlers: [
              EventHandler<String>(eventB, (ctx, msg) => received = msg),
            ],
            child: const Text('child'),
          ),
        ),
      );

      // eventA should no longer be listened to.
      eventA.fire('from-A');
      expect(received, isNull);

      // eventB should be active.
      eventB.fire('from-B');
      expect(received, 'from-B');

      eventA.dispose();
      eventB.dispose();
    });
  });
}

class _BuildCounter extends StatelessWidget {
  final VoidCallback onBuild;
  const _BuildCounter({required this.onBuild});

  @override
  Widget build(BuildContext context) {
    onBuild();
    return const Text('counter');
  }
}
