import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BindEvent', () {
    testWidgets('calls handler when event fires', (tester) async {
      final event = ViewModelEvent<String>();
      String? received;

      await tester.pumpWidget(
        MaterialApp(
          home: BindEvent<String>(
            event: event,
            handler: (context, value) => received = value,
            child: const Text('content', textDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(find.text('content'), findsOneWidget);
      expect(received, isNull);

      event.fire('hello');
      expect(received, 'hello');

      event.dispose();
    });

    testWidgets('renders child without rebuilding', (tester) async {
      final event = ViewModelEvent<int>();
      var childBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: BindEvent<int>(
            event: event,
            handler: (context, value) {},
            child: Builder(
              builder: (context) {
                childBuildCount++;
                return const Text('static', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      final initialBuildCount = childBuildCount;
      event.fire(1);
      event.fire(2);
      await tester.pump();
      expect(childBuildCount, initialBuildCount);

      event.dispose();
    });

    testWidgets('re-wires when event identity changes', (tester) async {
      final event1 = ViewModelEvent<String>();
      final event2 = ViewModelEvent<String>();
      String? received;

      Widget build(ViewModelEvent<String> event) => MaterialApp(
        home: BindEvent<String>(
          event: event,
          handler: (context, value) => received = value,
          child: const SizedBox(),
        ),
      );

      await tester.pumpWidget(build(event1));
      event1.fire('from1');
      expect(received, 'from1');

      await tester.pumpWidget(build(event2));
      received = null;

      event1.fire('should-not-receive');
      expect(received, isNull);

      event2.fire('from2');
      expect(received, 'from2');

      event1.dispose();
      event2.dispose();
    });
  });

  group('BindSignalEvent', () {
    testWidgets('calls handler when signal fires', (tester) async {
      final signal = SignalEvent();
      var callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: BindSignalEvent(
            event: signal,
            handler: (context) => callCount++,
            child: const Text('content', textDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(callCount, 0);
      signal.fire();
      expect(callCount, 1);
      signal.fire();
      expect(callCount, 2);

      signal.dispose();
    });

    testWidgets('re-wires when event identity changes', (tester) async {
      final signal1 = SignalEvent();
      final signal2 = SignalEvent();
      var callCount = 0;

      Widget build(SignalEvent signal) => MaterialApp(
        home: BindSignalEvent(
          event: signal,
          handler: (context) => callCount++,
          child: const SizedBox(),
        ),
      );

      await tester.pumpWidget(build(signal1));
      signal1.fire();
      expect(callCount, 1);

      await tester.pumpWidget(build(signal2));
      callCount = 0;

      signal1.fire();
      expect(callCount, 0); // Old signal should not trigger.

      signal2.fire();
      expect(callCount, 1);

      signal1.dispose();
      signal2.dispose();
    });
  });
}
