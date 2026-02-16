import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mvvm/async_state.dart';
import '../mvvm/relay_command.dart';

// ---------------------------------------------------------------------------
// ValueNotifier / ValueListenable matchers
// ---------------------------------------------------------------------------

/// Matches a [ValueListenable] whose current `.value` satisfies [matcher].
///
/// ```dart
/// expect(vm.countNotifier, hasValue(42));
/// expect(vm.itemsNotifier, hasValue(hasLength(3)));
/// expect(vm.loadingNotifier, hasValue(isFalse));
/// ```
Matcher hasValue<T>(Object? matcher) =>
    _HasValueMatcher<T>(wrapMatcher(matcher));

class _HasValueMatcher<T> extends Matcher {
  final Matcher _inner;
  const _HasValueMatcher(this._inner);

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is ValueListenable<T>) {
      return _inner.matches(item.value, matchState);
    }
    return false;
  }

  @override
  Description describe(Description description) => description
      .add('a ValueListenable whose value ')
      .addDescriptionOf(_inner);

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is ValueListenable<T>) {
      return mismatchDescription.add('has value ').addDescriptionOf(item.value);
    }
    return mismatchDescription.add('is not a ValueListenable<$T>');
  }
}

// ---------------------------------------------------------------------------
// RelayCommand matchers
// ---------------------------------------------------------------------------

/// Matches a [RelayCommand] whose [RelayCommand.isExecuting] is `true`.
///
/// ```dart
/// expect(vm.saveCommand, isExecuting);
/// ```
const Matcher isExecuting = _IsExecutingMatcher(true);

/// Matches a [RelayCommand] whose [RelayCommand.isExecuting] is `false`.
///
/// ```dart
/// expect(vm.saveCommand, isNotExecuting);
/// ```
const Matcher isNotExecuting = _IsExecutingMatcher(false);

class _IsExecutingMatcher extends Matcher {
  final bool _expected;
  const _IsExecutingMatcher(this._expected);

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is RelayCommand) {
      return item.isExecuting == _expected;
    }
    return false;
  }

  @override
  Description describe(Description description) => description.add(
    _expected
        ? 'a RelayCommand that is executing'
        : 'a RelayCommand that is not executing',
  );

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is RelayCommand) {
      return mismatchDescription.add('isExecuting is ${item.isExecuting}');
    }
    return mismatchDescription.add('is not a RelayCommand');
  }
}

/// Matches a [RelayCommand] whose [RelayCommand.canExecute] returns `true`.
///
/// ```dart
/// expect(vm.submitCommand, canExecuteCommand);
/// ```
const Matcher canExecuteCommand = _CanExecuteMatcher(true);

/// Matches a [RelayCommand] whose [RelayCommand.canExecute] returns `false`.
///
/// ```dart
/// expect(vm.submitCommand, cannotExecuteCommand);
/// ```
const Matcher cannotExecuteCommand = _CanExecuteMatcher(false);

class _CanExecuteMatcher extends Matcher {
  final bool _expected;
  const _CanExecuteMatcher(this._expected);

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is RelayCommand) {
      return item.canExecute() == _expected;
    }
    return false;
  }

  @override
  Description describe(Description description) => description.add(
    _expected
        ? 'a RelayCommand that can execute'
        : 'a RelayCommand that cannot execute',
  );

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is RelayCommand) {
      return mismatchDescription.add('canExecute() is ${item.canExecute()}');
    }
    return mismatchDescription.add('is not a RelayCommand');
  }
}

// ---------------------------------------------------------------------------
// AsyncState matchers
// ---------------------------------------------------------------------------

/// Matches an [AsyncStateNotifier] in the [AsyncLoading] state.
///
/// ```dart
/// expect(vm.entityState, isAsyncLoading);
/// ```
const Matcher isAsyncLoading = _AsyncStateMatcher(_AsyncStateKind.loading);

/// Matches an [AsyncStateNotifier] in the [AsyncData] state.
///
/// ```dart
/// expect(vm.entityState, isAsyncData);
/// ```
const Matcher isAsyncData = _AsyncStateMatcher(_AsyncStateKind.data);

/// Matches an [AsyncStateNotifier] in the [AsyncError] state.
///
/// ```dart
/// expect(vm.entityState, isAsyncError);
/// ```
const Matcher isAsyncError = _AsyncStateMatcher(_AsyncStateKind.error);

enum _AsyncStateKind { loading, data, error }

class _AsyncStateMatcher extends Matcher {
  final _AsyncStateKind _expected;
  const _AsyncStateMatcher(this._expected);

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is ValueListenable<AsyncState<dynamic>>) {
      return switch (_expected) {
        _AsyncStateKind.loading => item.value is AsyncLoading,
        _AsyncStateKind.data => item.value is AsyncData,
        _AsyncStateKind.error => item.value is AsyncError,
      };
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('an AsyncStateNotifier in the ${_expected.name} state');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is ValueListenable<AsyncState<dynamic>>) {
      return mismatchDescription.add('has state ${item.value}');
    }
    return mismatchDescription.add('is not an AsyncStateNotifier');
  }
}

/// Matches an [AsyncStateNotifier] whose data satisfies [matcher].
///
/// ```dart
/// expect(vm.entityState, hasAsyncData<User>(isNotNull));
/// expect(vm.entityState, hasAsyncData<int>(42));
/// ```
Matcher hasAsyncData<T>(Object? matcher) =>
    _HasAsyncDataMatcher<T>(wrapMatcher(matcher));

class _HasAsyncDataMatcher<T> extends Matcher {
  final Matcher _inner;
  const _HasAsyncDataMatcher(this._inner);

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is ValueListenable<AsyncState<dynamic>>) {
      final state = item.value;
      if (state is AsyncData<dynamic>) {
        return _inner.matches(state.data, matchState);
      }
    }
    return false;
  }

  @override
  Description describe(Description description) => description
      .add('an AsyncStateNotifier with data ')
      .addDescriptionOf(_inner);

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is ValueListenable<AsyncState<dynamic>>) {
      final state = item.value;
      if (state is AsyncData<dynamic>) {
        return mismatchDescription
            .add('has data ')
            .addDescriptionOf(state.data);
      }
      return mismatchDescription.add('has state $state (not AsyncData)');
    }
    return mismatchDescription.add('is not an AsyncStateNotifier');
  }
}

/// Matches an [AsyncStateNotifier] whose error message satisfies [matcher].
///
/// ```dart
/// expect(vm.entityState, hasAsyncError(contains('timeout')));
/// ```
Matcher hasAsyncError(Object? matcher) =>
    _HasAsyncErrorMatcher(wrapMatcher(matcher));

class _HasAsyncErrorMatcher extends Matcher {
  final Matcher _inner;
  const _HasAsyncErrorMatcher(this._inner);

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is ValueListenable<AsyncState<dynamic>>) {
      final state = item.value;
      if (state is AsyncError<dynamic>) {
        return _inner.matches(state.message, matchState);
      }
    }
    return false;
  }

  @override
  Description describe(Description description) => description
      .add('an AsyncStateNotifier with error ')
      .addDescriptionOf(_inner);

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is ValueListenable<AsyncState<dynamic>>) {
      final state = item.value;
      if (state is AsyncError<dynamic>) {
        return mismatchDescription
            .add('has error ')
            .addDescriptionOf(state.message);
      }
      return mismatchDescription.add('has state $state (not AsyncError)');
    }
    return mismatchDescription.add('is not an AsyncStateNotifier');
  }
}
