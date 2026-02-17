import 'package:community_toolkit/locator.dart';
import 'package:flutter_test/flutter_test.dart';

abstract class _Logger {
  void log(String msg);
}

class _ConsoleLogger implements _Logger {
  final logs = <String>[];

  @override
  void log(String msg) => logs.add(msg);
}

class _ApiClient {
  final String baseUrl;
  _ApiClient(this.baseUrl);
}

void main() {
  late ServiceLocator locator;

  setUp(() {
    locator = ServiceLocator.scope();
  });

  group('ServiceLocator', () {
    // ----- register & resolve -------------------------------------------------

    test('register and resolve a singleton', () {
      final logger = _ConsoleLogger();
      locator.register<_Logger>(logger);

      expect(locator<_Logger>(), same(logger));
    });

    test('throws on duplicate registration', () {
      locator.register<_Logger>(_ConsoleLogger());

      expect(
        () => locator.register<_Logger>(_ConsoleLogger()),
        throwsStateError,
      );
    });

    test('throws when resolving unregistered type', () {
      expect(() => locator<_Logger>(), throwsStateError);
    });

    // ----- registerIfAbsent ---------------------------------------------------

    test('registerIfAbsent registers when absent', () {
      final logger = _ConsoleLogger();
      final result = locator.registerIfAbsent<_Logger>(logger);

      expect(result, isTrue);
      expect(locator<_Logger>(), same(logger));
    });

    test('registerIfAbsent returns false when already registered', () {
      final first = _ConsoleLogger();
      final second = _ConsoleLogger();
      locator.register<_Logger>(first);

      final result = locator.registerIfAbsent<_Logger>(second);

      expect(result, isFalse);
      expect(locator<_Logger>(), same(first));
    });

    // ----- registerLazy -------------------------------------------------------

    test('registerLazy creates instance on first resolve', () {
      var factoryCalled = false;
      locator.registerLazy<_Logger>(() {
        factoryCalled = true;
        return _ConsoleLogger();
      });

      expect(factoryCalled, isFalse);
      final instance = locator<_Logger>();
      expect(factoryCalled, isTrue);
      expect(instance, isA<_ConsoleLogger>());
    });

    test('registerLazy returns same instance on subsequent resolves', () {
      locator.registerLazy<_Logger>(_ConsoleLogger.new);

      final first = locator<_Logger>();
      final second = locator<_Logger>();

      expect(first, same(second));
    });

    test('registerLazy throws on duplicate', () {
      locator.registerLazy<_Logger>(_ConsoleLogger.new);

      expect(
        () => locator.registerLazy<_Logger>(_ConsoleLogger.new),
        throwsStateError,
      );
    });

    // ----- isRegistered -------------------------------------------------------

    test('isRegistered returns true for eager registration', () {
      locator.register<_Logger>(_ConsoleLogger());

      expect(locator.isRegistered<_Logger>(), isTrue);
    });

    test('isRegistered returns true for lazy registration', () {
      locator.registerLazy<_Logger>(_ConsoleLogger.new);

      expect(locator.isRegistered<_Logger>(), isTrue);
    });

    test('isRegistered returns false for unregistered type', () {
      expect(locator.isRegistered<_Logger>(), isFalse);
    });

    // ----- unregister ---------------------------------------------------------

    test('unregister removes registration', () {
      locator.register<_Logger>(_ConsoleLogger());
      locator.unregister<_Logger>();

      expect(locator.isRegistered<_Logger>(), isFalse);
      expect(() => locator<_Logger>(), throwsStateError);
    });

    test('unregister does nothing for unregistered type', () {
      // Should not throw.
      locator.unregister<_Logger>();
    });

    test('unregister calls onDispose callback', () {
      var disposed = false;
      locator.register<_Logger>(
        _ConsoleLogger(),
        onDispose: (_) => disposed = true,
      );

      locator.unregister<_Logger>();

      expect(disposed, isTrue);
    });

    test(
      'unregister does not call onDispose for lazy that was never resolved',
      () {
        var disposed = false;
        locator.registerLazy<_Logger>(
          _ConsoleLogger.new,
          onDispose: (_) => disposed = true,
        );

        locator.unregister<_Logger>();

        // Factory was never called, so no instance to dispose.
        expect(disposed, isFalse);
      },
    );

    // ----- reset --------------------------------------------------------------

    test('reset clears all registrations', () async {
      locator.register<_Logger>(_ConsoleLogger());
      locator.register<_ApiClient>(_ApiClient('https://api.example.com'));

      await locator.reset();

      expect(locator.isRegistered<_Logger>(), isFalse);
      expect(locator.isRegistered<_ApiClient>(), isFalse);
    });

    test('reset calls onDispose for created singletons', () async {
      final disposals = <String>[];
      locator.register<_Logger>(
        _ConsoleLogger(),
        onDispose: (_) => disposals.add('logger'),
      );
      locator.register<_ApiClient>(
        _ApiClient('url'),
        onDispose: (_) => disposals.add('api'),
      );

      await locator.reset();

      expect(disposals, containsAll(['logger', 'api']));
    });

    test('reset calls onDispose for resolved lazy singletons', () async {
      var disposed = false;
      locator.registerLazy<_Logger>(
        _ConsoleLogger.new,
        onDispose: (_) => disposed = true,
      );

      // Resolve to promote from factory to singleton.
      locator<_Logger>();
      await locator.reset();

      expect(disposed, isTrue);
    });

    test(
      'reset does not call onDispose for unresolved lazy registrations',
      () async {
        var disposed = false;
        locator.registerLazy<_Logger>(
          _ConsoleLogger.new,
          onDispose: (_) => disposed = true,
        );

        await locator.reset();

        expect(disposed, isFalse);
      },
    );

    // ----- onDispose typed callback -------------------------------------------

    test('onDispose receives typed instance', () async {
      _ConsoleLogger? disposedLogger;
      final logger = _ConsoleLogger()..log('before-dispose');

      locator.register<_Logger>(
        logger,
        onDispose: (instance) => disposedLogger = instance as _ConsoleLogger,
      );

      await locator.reset();

      expect(disposedLogger, same(logger));
      expect(disposedLogger!.logs, ['before-dispose']);
    });

    // ----- scope() factory ----------------------------------------------------

    test('scope() creates independent container', () {
      final scope = ServiceLocator.scope();
      scope.register<_Logger>(_ConsoleLogger());

      expect(scope.isRegistered<_Logger>(), isTrue);
      expect(locator.isRegistered<_Logger>(), isFalse);
    });

    // ----- re-registration after unregister -----------------------------------

    test('can re-register after unregister', () {
      final first = _ConsoleLogger();
      final second = _ConsoleLogger();

      locator.register<_Logger>(first);
      locator.unregister<_Logger>();
      locator.register<_Logger>(second);

      expect(locator<_Logger>(), same(second));
    });
  });
}
