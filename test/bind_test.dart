import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bind', () {
    testWidgets('rebuilds when notifier changes', (tester) async {
      final notifier = ValueNotifier<int>(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Bind<int>(
            notifier: notifier,
            builder: (value) =>
                Text('$value', textDirection: TextDirection.ltr),
          ),
        ),
      );
      expect(find.text('0'), findsOneWidget);

      notifier.value = 42;
      await tester.pump();
      expect(find.text('42'), findsOneWidget);

      notifier.dispose();
    });

    testWidgets('.child passes through static child', (tester) async {
      final notifier = ValueNotifier<int>(0);
      var childBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Bind<int>.child(
            notifier: notifier,
            child: Builder(
              builder: (context) {
                childBuildCount++;
                return const Icon(Icons.star);
              },
            ),
            builder: (value, child) => Column(
              children: [
                Text('$value', textDirection: TextDirection.ltr),
                child!,
              ],
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      final initialBuildCount = childBuildCount;

      notifier.value = 1;
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      // Child should not have been rebuilt.
      expect(childBuildCount, initialBuildCount);

      notifier.dispose();
    });
  });

  group('Bind2', () {
    testWidgets('rebuilds when either notifier changes', (tester) async {
      final n1 = ValueNotifier<int>(1);
      final n2 = ValueNotifier<String>('a');

      await tester.pumpWidget(
        MaterialApp(
          home: Bind2<int, String>(
            notifier1: n1,
            notifier2: n2,
            builder: (v1, v2) =>
                Text('$v1-$v2', textDirection: TextDirection.ltr),
          ),
        ),
      );
      expect(find.text('1-a'), findsOneWidget);

      n1.value = 2;
      await tester.pump();
      expect(find.text('2-a'), findsOneWidget);

      n2.value = 'b';
      await tester.pump();
      expect(find.text('2-b'), findsOneWidget);

      n1.dispose();
      n2.dispose();
    });
  });

  group('Bind3', () {
    testWidgets('rebuilds with three notifiers', (tester) async {
      final n1 = ValueNotifier<int>(1);
      final n2 = ValueNotifier<int>(2);
      final n3 = ValueNotifier<int>(3);

      await tester.pumpWidget(
        MaterialApp(
          home: Bind3<int, int, int>(
            notifier1: n1,
            notifier2: n2,
            notifier3: n3,
            builder: (v1, v2, v3) =>
                Text('$v1+$v2+$v3', textDirection: TextDirection.ltr),
          ),
        ),
      );
      expect(find.text('1+2+3'), findsOneWidget);

      n3.value = 10;
      await tester.pump();
      expect(find.text('1+2+10'), findsOneWidget);

      n1.dispose();
      n2.dispose();
      n3.dispose();
    });
  });

  group('Bind4', () {
    testWidgets('rebuilds with four notifiers', (tester) async {
      final n1 = ValueNotifier<int>(1);
      final n2 = ValueNotifier<int>(2);
      final n3 = ValueNotifier<int>(3);
      final n4 = ValueNotifier<int>(4);

      await tester.pumpWidget(
        MaterialApp(
          home: Bind4<int, int, int, int>(
            notifier1: n1,
            notifier2: n2,
            notifier3: n3,
            notifier4: n4,
            builder: (v1, v2, v3, v4) =>
                Text('$v1$v2$v3$v4', textDirection: TextDirection.ltr),
          ),
        ),
      );
      expect(find.text('1234'), findsOneWidget);

      n4.value = 9;
      await tester.pump();
      expect(find.text('1239'), findsOneWidget);

      n1.dispose();
      n2.dispose();
      n3.dispose();
      n4.dispose();
    });
  });
}
