import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BindAsync', () {
    testWidgets('shows loading widget in loading state', (tester) async {
      // Arrange
      final notifier = AsyncStateNotifier<String>();

      // Act
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindAsync<String>(
            notifier: notifier,
            loading: (_) => const Text('Loading'),
            data: Text.new,
            error: (m) => Text('Error: $m'),
          ),
        ),
      );

      // Assert
      expect(find.text('Loading'), findsOneWidget);
      notifier.dispose();
    });

    testWidgets('shows data widget in data state', (tester) async {
      // Arrange
      final notifier = AsyncStateNotifier<String>.withData('hello');

      // Act
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindAsync<String>(
            notifier: notifier,
            loading: (_) => const Text('Loading'),
            data: Text.new,
            error: (m) => Text('Error: $m'),
          ),
        ),
      );

      // Assert
      expect(find.text('hello'), findsOneWidget);
      notifier.dispose();
    });

    testWidgets('shows error widget in error state', (tester) async {
      // Arrange
      final notifier = AsyncStateNotifier<String>()..setError('boom');

      // Act
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindAsync<String>(
            notifier: notifier,
            loading: (_) => const Text('Loading'),
            data: Text.new,
            error: (m) => Text('Error: $m'),
          ),
        ),
      );

      // Assert
      expect(find.text('Error: boom'), findsOneWidget);
      notifier.dispose();
    });

    testWidgets('passes progress to loading builder', (tester) async {
      // Arrange
      final notifier = AsyncStateNotifier<String>()..setProgress(0.42);

      // Act
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindAsync<String>(
            notifier: notifier,
            loading: (p) => Text('progress:$p'),
            data: Text.new,
            error: (m) => Text('Error: $m'),
          ),
        ),
      );

      // Assert
      expect(find.text('progress:0.42'), findsOneWidget);
      notifier.dispose();
    });

    testWidgets('rebuilds when state changes', (tester) async {
      // Arrange
      final notifier = AsyncStateNotifier<String>();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BindAsync<String>(
            notifier: notifier,
            loading: (_) => const Text('Loading'),
            data: Text.new,
            error: (m) => Text('Error: $m'),
          ),
        ),
      );
      expect(find.text('Loading'), findsOneWidget);

      // Act — transition to data.
      notifier.setData('world');
      await tester.pump();

      // Assert
      expect(find.text('Loading'), findsNothing);
      expect(find.text('world'), findsOneWidget);
      notifier.dispose();
    });
  });
}
