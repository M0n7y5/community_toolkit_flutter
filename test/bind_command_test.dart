import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BindCommand', () {
    testWidgets('provides onPressed when canExecute is true', (tester) async {
      final cmd = RelayCommand<void>.untyped(executeAsync: () async {});

      await tester.pumpWidget(
        MaterialApp(
          home: BindCommand.untyped(
            command: cmd,
            child: const Text('Go'),
            builder: (onPressed, child, isExecuting) =>
                ElevatedButton(onPressed: onPressed, child: child),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
      cmd.dispose();
    });

    testWidgets('onPressed is null when canExecute is false', (tester) async {
      final cmd = RelayCommand<void>.untyped(
        executeAsync: () async {},
        canExecute: () => false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BindCommand.untyped(
            command: cmd,
            child: const Text('Go'),
            builder: (onPressed, child, isExecuting) =>
                ElevatedButton(onPressed: onPressed, child: child),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      cmd.dispose();
    });

    testWidgets('passes isExecuting flag', (tester) async {
      final cmd = RelayCommand<void>.untyped(
        executeAsync: () async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
      );

      bool? capturedIsExecuting;
      await tester.pumpWidget(
        MaterialApp(
          home: BindCommand.untyped(
            command: cmd,
            child: const Text('Go'),
            builder: (onPressed, child, isExecuting) {
              capturedIsExecuting = isExecuting;
              return ElevatedButton(onPressed: onPressed, child: child);
            },
          ),
        ),
      );

      expect(capturedIsExecuting, isFalse);

      // Start execution.
      cmd.invoke();
      await tester.pump();
      expect(capturedIsExecuting, isTrue);

      // Wait for completion.
      await tester.pump(const Duration(milliseconds: 150));
      expect(capturedIsExecuting, isFalse);

      cmd.dispose();
    });

    testWidgets('typed command passes parameter', (tester) async {
      String? received;
      final cmd = RelayCommand<String>(
        executeAsync: (arg) async => received = arg,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BindCommand<String>(
            command: cmd,
            commandParameter: 'hello',
            child: const Text('Go'),
            builder: (onPressed, child, isExecuting) =>
                ElevatedButton(onPressed: onPressed, child: child),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(received, 'hello');

      cmd.dispose();
    });
  });
}
