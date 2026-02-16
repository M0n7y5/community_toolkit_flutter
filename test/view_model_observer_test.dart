import 'package:community_toolkit/mvvm.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingObserver extends ViewModelObserver {
  final List<String> log = [];
  Duration? lastElapsed;

  @override
  void onViewModelCreated(BaseViewModel vm) {
    log.add('created:${vm.runtimeType}');
  }

  @override
  void onViewModelDisposed(BaseViewModel vm) {
    log.add('disposed:${vm.runtimeType}');
  }

  @override
  void onInitStarted(BaseViewModel vm) {
    log.add('initStarted:${vm.runtimeType}');
  }

  @override
  void onInitCompleted(BaseViewModel vm, Duration elapsed) {
    log.add('initCompleted:${vm.runtimeType}');
    lastElapsed = elapsed;
  }

  @override
  void onInitFailed(BaseViewModel vm, Object error, StackTrace stackTrace) {
    log.add('initFailed:${vm.runtimeType}:$error');
  }
}

class _SimpleViewModel extends BaseViewModel {}

class _FailingViewModel extends BaseViewModel {
  @override
  Future<void> init() async {
    throw StateError('broken');
  }
}

class _SlowViewModel extends BaseViewModel {
  @override
  Future<void> init() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
}

void main() {
  late _RecordingObserver observer;

  setUp(() {
    observer = _RecordingObserver();
    BaseViewModel.observers.add(observer);
  });

  tearDown(() {
    BaseViewModel.observers.clear();
  });

  group('ViewModelObserver', () {
    test('receives created and initStarted/initCompleted', () async {
      // Arrange & Act
      final vm = _SimpleViewModel();
      await vm.initialize();

      // Assert
      expect(observer.log, [
        'created:_SimpleViewModel',
        'initStarted:_SimpleViewModel',
        'initCompleted:_SimpleViewModel',
      ]);

      vm.dispose();
    });

    test('receives disposed event', () async {
      // Arrange
      final vm = _SimpleViewModel();
      await vm.initialize();
      observer.log.clear();

      // Act
      vm.dispose();

      // Assert
      expect(observer.log, ['disposed:_SimpleViewModel']);
    });

    test('receives initFailed on error and rethrows', () async {
      // Arrange
      final vm = _FailingViewModel();

      // Act & Assert
      await expectLater(vm.initialize, throwsStateError);
      expect(
        observer.log,
        contains('initFailed:_FailingViewModel:Bad state: broken'),
      );
      vm.dispose();
    });

    test('loadingNotifier is false after init error', () async {
      // Arrange
      final vm = _FailingViewModel();

      // Act
      try {
        await vm.initialize();
      } on StateError catch (_) {
        // Expected.
      }

      // Assert — loading is false even after failure.
      expect(vm.loadingNotifier.value, isFalse);
      vm.dispose();
    });

    test('elapsed duration is measured', () async {
      // Arrange
      final vm = _SlowViewModel();

      // Act
      await vm.initialize();

      // Assert
      expect(observer.lastElapsed, isNotNull);
      expect(observer.lastElapsed!.inMilliseconds, greaterThanOrEqualTo(20));
      vm.dispose();
    });

    test('multiple observers all receive events', () async {
      // Arrange
      final second = _RecordingObserver();
      BaseViewModel.observers.add(second);

      // Act
      final vm = _SimpleViewModel();
      await vm.initialize();
      vm.dispose();

      // Assert
      expect(observer.log.length, 4); // created, started, completed, disposed
      expect(second.log.length, 4);
    });

    test('empty observer list is a no-op', () async {
      // Arrange
      BaseViewModel.observers.clear();

      // Act & Assert — should not throw.
      final vm = _SimpleViewModel();
      await vm.initialize();
      vm.dispose();
    });
  });
}
