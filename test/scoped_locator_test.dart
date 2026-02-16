import 'package:community_toolkit/locator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

abstract class _Greeter {
  String greet();
}

class _EnglishGreeter implements _Greeter {
  @override
  String greet() => 'Hello';
}

class _FrenchGreeter implements _Greeter {
  @override
  String greet() => 'Bonjour';
}

void main() {
  tearDown(() async {
    await ServiceLocator.I.reset();
  });

  group('ServiceLocator.scope()', () {
    test('creates an independent instance', () {
      // Arrange
      final scope = ServiceLocator.scope()
        ..register<_Greeter>(_FrenchGreeter());

      // Assert
      expect(scope<_Greeter>().greet(), 'Bonjour');
      expect(ServiceLocator.I.isRegistered<_Greeter>(), isFalse);
    });
  });

  group('ScopedLocator', () {
    testWidgets('of() returns scoped locator', (tester) async {
      // Arrange
      final scope = ServiceLocator.scope()
        ..register<_Greeter>(_FrenchGreeter());
      late ServiceLocator resolved;

      // Act
      await tester.pumpWidget(
        ScopedLocator(
          locator: scope,
          child: Builder(
            builder: (context) {
              resolved = ScopedLocator.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // Assert
      expect(identical(resolved, scope), isTrue);
      expect(resolved<_Greeter>().greet(), 'Bonjour');
    });

    testWidgets('of() falls back to ServiceLocator.I', (tester) async {
      // Arrange
      ServiceLocator.I.register<_Greeter>(_EnglishGreeter());
      late ServiceLocator resolved;

      // Act — no ScopedLocator in the tree.
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            resolved = ScopedLocator.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      // Assert
      expect(identical(resolved, ServiceLocator.I), isTrue);
      expect(resolved<_Greeter>().greet(), 'Hello');
    });

    testWidgets('nested scopes resolve to innermost', (tester) async {
      // Arrange
      final outer = ServiceLocator.scope()
        ..register<_Greeter>(_EnglishGreeter());
      final inner = ServiceLocator.scope()
        ..register<_Greeter>(_FrenchGreeter());
      late String outerGreeting;
      late String innerGreeting;

      // Act
      await tester.pumpWidget(
        ScopedLocator(
          locator: outer,
          child: Column(
            children: [
              Builder(
                builder: (context) {
                  outerGreeting = ScopedLocator.of(context)<_Greeter>().greet();
                  return const SizedBox.shrink();
                },
              ),
              ScopedLocator(
                locator: inner,
                child: Builder(
                  builder: (context) {
                    innerGreeting = ScopedLocator.of(
                      context,
                    )<_Greeter>().greet();
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      );

      // Assert
      expect(outerGreeting, 'Hello');
      expect(innerGreeting, 'Bonjour');
    });
  });
}
