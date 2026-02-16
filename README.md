# Community Toolkit for Flutter

A .NET CommunityToolkit.Mvvm-inspired MVVM framework for Flutter. Provides
reactive ViewModels, typed commands, one-shot events, async state management,
field validation, cross-VM messaging, a built-in service locator, and a full
suite of test utilities.

## Installation

```yaml
dependencies:
  community_toolkit:
    path: ../community_toolkit
```

## Entry Points

| Import | Contents |
|--------|----------|
| `package:community_toolkit/community_toolkit.dart` | Everything (MVVM + ServiceLocator) |
| `package:community_toolkit/mvvm.dart` | MVVM primitives only |
| `package:community_toolkit/locator.dart` | ServiceLocator only |
| `package:community_toolkit/testing.dart` | Test utilities (dev only) |

## Architecture Overview

```
ServiceLocator          -- DI container (singleton registry)
BaseViewModel           -- State, commands, events, auto-dispose
  RecipientViewModel    -- Auto-managed Messenger subscriptions
  ValidationMixin       -- Field-level validation
ViewModelStateMixin     -- Widget lifecycle integration
Bind / Bind2 / Bind3    -- Reactive UI builders
BindCommand             -- Command-to-button binding
BindEvent / BindSignalEvent / MultiBindEvent  -- One-shot side effects
Messenger               -- Cross-VM event bus
AsyncStateNotifier      -- Sealed loading/data/error state
```

## Core Concepts

### BaseViewModel

The foundation for all ViewModels. Manages notifier lifecycle, provides
convenience factories, and handles async initialization.

```dart
class CounterViewModel extends BaseViewModel {
  CounterViewModel() {
    countNotifier = notifier<int>(0);
    errorEvent = event<String>();
    factState = asyncNotifier<String>();

    incrementCommand = command.syncUntyped(
      execute: () => countNotifier.value++,
      canExecute: () => countNotifier.value < 10,
      listenables: [countNotifier],
    );
  }

  late final ValueNotifier<int> countNotifier;
  late final ViewModelEvent<String> errorEvent;
  late final AsyncStateNotifier<String> factState;
  late final RelayCommand<void> incrementCommand;

  @override
  Future<void> init() async {
    await factState.execute(() => fetchFact());
  }
}
```

Key helpers on `BaseViewModel`:

| Helper | Creates |
|--------|---------|
| `notifier<T>(value)` | Auto-disposed `ValueNotifier<T>` |
| `asyncNotifier<T>()` | Auto-disposed `AsyncStateNotifier<T>` (starts loading) |
| `asyncNotifierWithData<T>(data)` | Auto-disposed `AsyncStateNotifier<T>` (starts with data) |
| `forceNotifier<T>(value)` | Auto-disposed `ForceValueNotifier<T>` (always notifies) |
| `event<T>()` | Auto-disposed `ViewModelEvent<T>` |
| `signalEvent()` | Auto-disposed `SignalEvent` (no payload) |
| `command<T>(...)` | Auto-disposed typed async `RelayCommand<T>` |
| `command.untyped(...)` | Auto-disposed parameterless async command |
| `command.sync<T>(...)` | Auto-disposed typed sync command |
| `command.syncUntyped(...)` | Auto-disposed parameterless sync command |
| `autoDispose(notifier)` | Register any `ChangeNotifier` for disposal |

### ViewModelStateMixin

Eliminates the `initState`/`dispose` boilerplate in screens. Manages the
ViewModel lifecycle automatically.

```dart
class _DetailScreenState extends State<DetailScreen>
    with ViewModelStateMixin<DetailScreen, DetailViewModel> {
  @override
  DetailViewModel createViewModel() =>
      DetailViewModel(id: widget.id);

  @override
  void onViewModelReady(DetailViewModel vm) {
    // Wire up listeners, fire initial commands, etc.
  }

  @override
  Widget build(BuildContext context) {
    // Access the ViewModel via `vm`.
    return Bind<int>(
      notifier: vm.countNotifier,
      builder: (count) => Text('$count'),
    );
  }
}
```

Lifecycle order:

1. `createViewModel()` -- construct the ViewModel.
2. `onViewModelReady(vm)` -- wire up listeners, fire initial commands.
3. `BaseViewModel.initialize()` -- runs `init()` (loading transitions true to false).
4. Widget `dispose()` -- calls `vm.dispose()` automatically.

### AsyncStateNotifier

Replaces the common triple of `isLoadingNotifier` + `errorNotifier` + `dataNotifier`
with a single notifier holding a sealed `AsyncState<T>`.

```dart
// ViewModel
late final entityState = asyncNotifier<Entity>();

@override
Future<void> init() async {
  await entityState.execute(() => api.getEntity(id));
}

// View -- exhaustive pattern matching
Bind<AsyncState<Entity>>(
  notifier: vm.entityState,
  builder: (state) => switch (state) {
    AsyncLoading() => const CircularProgressIndicator(),
    AsyncError(:final message) => Text('Error: $message'),
    AsyncData(:final data) => EntityView(data),
  },
)
```

For progressive/streaming data, use the manual methods:

```dart
entityState.setLoading();
entityState.setData(value);
entityState.setError('Something failed');
```

Convenience getters: `isLoading`, `hasData`, `hasError`, `data`, `error`.

### RelayCommand

Typed command pattern with `canExecute` guards, `isExecuting` state, and
automatic re-evaluation via `listenables`.

```dart
late final saveCommand = command<String>(
  executeAsync: (name) async => await save(name),
  canExecute: (name) => name.isNotEmpty,
  listenables: [nameNotifier],
  errorNotifier: errorNotifier,  // optional: auto-captures exceptions
);

late final refreshCommand = command.untyped(
  executeAsync: () async => await refresh(),
);
```

### ViewModelEvent and SignalEvent

One-shot events for transient UI side effects (snackbars, navigation, dialogs).
Unlike `ValueNotifier`, events fire once and are consumed.

```dart
// ViewModel
late final errorEvent = event<String>();       // carries a payload
late final closeDialog = signalEvent();        // no payload

void onSave() {
  errorEvent.fire('Something went wrong');
  closeDialog.fire();
}
```

### Bind Widgets

Reactive UI builders that rebuild only when their notifier changes.

| Widget | Notifiers | Use Case |
|--------|-----------|----------|
| `Bind<T>` | 1 | Single value |
| `Bind2<A, B>` | 2 | Two combined values |
| `Bind3<A, B, C>` | 3 | Three combined values |
| `Bind4<A, B, C, D>` | 4 | Four combined values |
| `BindSelector<T, S>` | 1 (derived) | Fine-grained: only rebuilds when selector output changes |
| `BindCommand<T>` | 1 (command) | Wires `onPressed`/`isExecuting`/`canExecute` to a button |
| `BindEvent<T>` | 1 (event) | Imperative handler for `ViewModelEvent` |
| `BindSignalEvent` | 1 (signal) | Imperative handler for `SignalEvent` |
| `MultiBindEvent` | N (events) | Multiple event handlers without nesting |

```dart
// BindSelector -- only rebuilds when isFavorite changes, not on every ItemData change.
BindSelector<ItemData, bool>(
  notifier: vm.itemDataNotifier,
  selector: (data) => data.isFavorite,
  builder: (isFavorite) => Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
)

// MultiBindEvent -- handles multiple events without deep nesting.
MultiBindEvent(
  handlers: [
    EventHandler(vm.errorEvent, (ctx, msg) => showSnackBar(ctx, msg)),
    EventHandler(vm.successEvent, (ctx, msg) => showSnackBar(ctx, msg)),
  ],
  signalHandlers: [
    SignalHandler(vm.closeDialog, (ctx) => Navigator.of(ctx).pop()),
  ],
  child: Scaffold(...),
)
```

### ServiceLocator

A minimal, synchronous dependency injection container. Replaces `get_it` for
the common case of singleton service registration and resolution.

```dart
// Register at startup.
ServiceLocator.I.register<DatabaseService>(DatabaseService());
ServiceLocator.I.registerLazy<ApiClient>(() => ApiClient());
ServiceLocator.I.registerIfAbsent<Logger>(Logger());

// Resolve anywhere.
final db = ServiceLocator.I<DatabaseService>();

// In tests.
setUp(() => ServiceLocator.I.register<DatabaseService>(mockDb));
tearDown(() => ServiceLocator.I.reset());
```

### Messenger

A typed event bus for decoupled cross-ViewModel communication.

```dart
// Define a message.
class ItemAddedMessage {
  const ItemAddedMessage(this.item);
  final Item item;
}

// Register (typically in a ViewModel constructor or init).
messenger.register<ItemAddedMessage>(this, (msg) {
  cartTotal.value += msg.item.price;
});

// Send from anywhere.
messenger.send(ItemAddedMessage(item));

// Unregister on dispose.
messenger.unregisterAll(this);
```

### RecipientViewModel

A `BaseViewModel` that auto-manages `Messenger` subscriptions. All handlers
registered via `receive<T>()` are cleaned up on dispose.

```dart
class CartViewModel extends RecipientViewModel {
  CartViewModel(super.messenger);

  late final totalNotifier = notifier<double>(0);

  @override
  Future<void> init() async {
    receive<ItemAddedMessage>((msg) {
      totalNotifier.value += msg.item.price;
    });
  }
}
```

### ValidationMixin

Field-level validation with reactive `isValidNotifier` for automatic button
enable/disable.

```dart
class LoginViewModel extends BaseViewModel with ValidationMixin {
  late final emailNotifier = notifier<String>('');

  late final loginCommand = command.untyped(
    executeAsync: _login,
    canExecute: () => isValid,
    listenables: [isValidNotifier],
  );

  void onEmailChanged(String value) {
    emailNotifier.value = value;
    validateField<String>('email', value, [
      (v) => v.isEmpty ? 'Required' : null,
      (v) => !v.contains('@') ? 'Invalid email' : null,
    ]);
  }
}

// In the view:
Bind<bool>(
  notifier: vm.isValidNotifier,
  builder: (_) => TextField(
    onChanged: vm.onEmailChanged,
    decoration: InputDecoration(
      errorText: vm.getFieldError('email'),
    ),
  ),
)
```

### ForceValueNotifier

A `ValueNotifier` that always notifies listeners on set, even when the new
value equals the old one. Useful for objects with coarse equality.

```dart
late final entityNotifier = forceNotifier<Entity?>(null);

// This always notifies, even if entity.id == old.id:
entityNotifier.value = enrichedEntity;
```

### ValueNotifier.update() Extension

A convenience for read-modify-write operations on `ValueNotifier`.

```dart
// Before:
itemsNotifier.value = [...itemsNotifier.value, newItem];

// After:
itemsNotifier.update((items) => [...items, newItem]);
```

## Testing

Import `package:community_toolkit/testing.dart` for test utilities.

### ViewModelHarness

Manages ViewModel lifecycle in tests. Eliminates the manual
`await Future.delayed(Duration.zero)` + `vm.dispose()` boilerplate.

```dart
late final harness = ViewModelHarness<MyViewModel>();

tearDown(() => harness.dispose());

test('loads data on init', () async {
  final vm = await harness.create(() => MyViewModel());
  expect(vm.dataNotifier.value, isNotNull);
});
```

### NotifierHistory

Records all value transitions on a `ValueNotifier` for asserting on
intermediate states and transition sequences.

```dart
final history = NotifierHistory(vm.stepNotifier);
await vm.performMultiStepOperation();

expect(history.values, [Step.validating, Step.downloading, Step.complete]);
expect(history.latest, Step.complete);

history.dispose();
```

### EventRecorder and SignalRecorder

Records all firings of `ViewModelEvent` and `SignalEvent` for test assertions.

```dart
final recorder = EventRecorder(vm.errorEvent);
await vm.performAction();

expect(recorder.fired, isTrue);
expect(recorder.latest, 'Something went wrong');
expect(recorder.count, 1);

recorder.dispose();
```

### Custom Matchers

```dart
// ValueNotifier matchers
expect(vm.countNotifier, hasValue(42));
expect(vm.loadingNotifier, hasValue(isFalse));

// RelayCommand matchers
expect(vm.saveCommand, isExecuting);
expect(vm.saveCommand, isNotExecuting);
expect(vm.submitCommand, canExecuteCommand);
expect(vm.submitCommand, cannotExecuteCommand);
```

## Example

Run the example app from `example/` for working demonstrations of all features
across three tabs: Counter, Shop, and Login.

```bash
cd example
flutter run
```

## Requirements

- Dart SDK >= 3.8.0
- Flutter >= 3.35.0
