import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _User {
  final String name;
  final int age;
  _User(this.name, this.age);
}

void main() {
  group('BindSelector', () {
    testWidgets('rebuilds only when selected value changes', (tester) async {
      final userNotifier = ValueNotifier(_User('Alice', 30));
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: BindSelector<_User, String>(
            notifier: userNotifier,
            selector: (user) => user.name,
            builder: (name) {
              buildCount++;
              return Text(name, textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      final initialBuildCount = buildCount;

      // Change age only (name stays the same) — should NOT rebuild.
      userNotifier.value = _User('Alice', 31);
      await tester.pump();
      expect(buildCount, initialBuildCount);

      // Change name — should rebuild.
      userNotifier.value = _User('Bob', 31);
      await tester.pump();
      expect(find.text('Bob'), findsOneWidget);
      expect(buildCount, initialBuildCount + 1);

      userNotifier.dispose();
    });

    testWidgets('handles notifier identity change via didUpdateWidget', (
      tester,
    ) async {
      final notifier1 = ValueNotifier(_User('Alice', 30));
      final notifier2 = ValueNotifier(_User('Bob', 25));

      Widget buildWidget(ValueNotifier<_User> notifier) {
        return MaterialApp(
          home: BindSelector<_User, String>(
            notifier: notifier,
            selector: (user) => user.name,
            builder: (name) => Text(name, textDirection: TextDirection.ltr),
          ),
        );
      }

      await tester.pumpWidget(buildWidget(notifier1));
      expect(find.text('Alice'), findsOneWidget);

      await tester.pumpWidget(buildWidget(notifier2));
      expect(find.text('Bob'), findsOneWidget);

      notifier1.dispose();
      notifier2.dispose();
    });
  });
}
