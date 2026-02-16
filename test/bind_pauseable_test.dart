import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BindPauseable', () {
    testWidgets('renders initial value', (tester) async {
      // Arrange
      final notifier = ValueNotifier(0);

      // Act
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindPauseable<int>(
            notifier: notifier,
            builder: (v) => Text('$v'),
          ),
        ),
      );

      // Assert
      expect(find.text('0'), findsOneWidget);
      notifier.dispose();
    });

    testWidgets('updates when notifier changes while visible', (tester) async {
      // Arrange
      final notifier = ValueNotifier(0);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindPauseable<int>(
            notifier: notifier,
            builder: (v) => Text('$v'),
          ),
        ),
      );

      // Act
      notifier.value = 42;
      await tester.pump();

      // Assert
      expect(find.text('42'), findsOneWidget);
      notifier.dispose();
    });

    testWidgets('defers updates when TickerMode is disabled', (tester) async {
      // Arrange
      final notifier = ValueNotifier(0);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TickerMode(
            enabled: false,
            child: BindPauseable<int>(
              notifier: notifier,
              builder: (v) => Text('$v'),
            ),
          ),
        ),
      );
      expect(find.text('0'), findsOneWidget);

      // Act — change while paused.
      notifier.value = 99;
      await tester.pump();

      // Assert — still shows old value.
      expect(find.text('0'), findsOneWidget);
      expect(find.text('99'), findsNothing);
      notifier.dispose();
    });

    testWidgets('catches up when becoming visible again', (tester) async {
      // Arrange
      final notifier = ValueNotifier(0);

      // Start paused.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TickerMode(
            enabled: false,
            child: BindPauseable<int>(
              notifier: notifier,
              builder: (v) => Text('$v'),
            ),
          ),
        ),
      );
      notifier.value = 50;
      await tester.pump();
      expect(find.text('0'), findsOneWidget);

      // Act — re-enable tickers.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TickerMode(
            enabled: true,
            child: BindPauseable<int>(
              notifier: notifier,
              builder: (v) => Text('$v'),
            ),
          ),
        ),
      );

      // Assert — caught up to latest value.
      expect(find.text('50'), findsOneWidget);
      notifier.dispose();
    });

    testWidgets('handles notifier identity change', (tester) async {
      // Arrange
      final a = ValueNotifier(1);
      final b = ValueNotifier(2);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindPauseable<int>(notifier: a, builder: (v) => Text('$v')),
        ),
      );
      expect(find.text('1'), findsOneWidget);

      // Act — swap notifier.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindPauseable<int>(notifier: b, builder: (v) => Text('$v')),
        ),
      );

      // Assert
      expect(find.text('2'), findsOneWidget);

      // Old notifier changes should not affect the widget.
      a.value = 100;
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      a.dispose();
      b.dispose();
    });
  });
}
