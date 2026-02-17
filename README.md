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
ServiceLocator          -- DI container (singleton registry, dispose callbacks)
ScopedLocator           -- Subtree-scoped DI via InheritedWidget
BaseViewModel           -- State, commands, events, auto-dispose
  RecipientViewModel    -- Auto-managed Messenger subscriptions
  ValidationMixin       -- Field-level validation
ViewModelStateMixin     -- Widget lifecycle integration
ViewModelObserver       -- Lifecycle hooks for debugging / monitoring
Bind / Bind2 / Bind3    -- Reactive UI builders
BindAsync               -- Dedicated async state builder
BindPauseable           -- Visibility-aware subscriptions
BindCommand             -- Command-to-button binding
BindEvent / BindSignalEvent / MultiBindEvent  -- One-shot side effects
Messenger               -- Cross-VM event bus
AsyncStateNotifier      -- Sealed loading/data/error state
ComputedNotifier        -- Sync derived state with auto-recompute
AsyncComputedNotifier   -- Async derived state with auto-recompute + debounce
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
| `computed<T>(watch:, compute:)` | Auto-disposed `ComputedNotifier<T>` (sync derived state) |
| `asyncComputed<T>(watch:, compute:)` | Auto-disposed `AsyncComputedNotifier<T>` (async derived state) |
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
| `BindAsync<T>` | 1 (async) | Exhaustive loading/data/error builders for `AsyncStateNotifier` |
| `BindPauseable<T>` | 1 | Visibility-aware: pauses subscription when offscreen |
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

### ComputedNotifier

A `ValueNotifier` whose value is derived from one or more source `Listenable`s
and automatically recomputed when any source changes. The synchronous
counterpart to Riverpod's `ref.watch` chaining.

```dart
class CartViewModel extends BaseViewModel {
  late final items = notifier<List<Item>>([]);
  late final taxRate = notifier<double>(0.08);

  late final total = computed<double>(
    watch: [items, taxRate],
    compute: () {
      final subtotal = items.value.fold(0.0, (s, i) => s + i.price);
      return subtotal * (1 + taxRate.value);
    },
  );
}
```

Listeners are only notified when the computed value changes by `==`. Use
`recompute()` to force notification even when the value is equal.

### AsyncComputedNotifier

The async counterpart to `ComputedNotifier`. Watches source `Listenable`s,
re-runs an async computation when any source changes, and manages
`AsyncState<T>` transitions (loading/data/error) automatically.

Features:
- **Last-write-wins**: If a source changes while a computation is in-flight,
  the stale result is discarded.
- **Debounce**: Optional `debounce` duration coalesces rapid source changes.
- **Refresh**: `refresh()` re-runs the computation without entering the
  loading state (useful for pull-to-refresh).

```dart
class SearchViewModel extends BaseViewModel {
  late final query = notifier<String>('');
  late final filters = notifier<Filters>(Filters.defaults);

  late final results = asyncComputed<List<Item>>(
    watch: [query, filters],
    compute: () => api.search(query.value, filters.value),
    debounce: const Duration(milliseconds: 300),
  );
}

// View
BindAsync<List<Item>>(
  notifier: vm.results,
  loading: (_) => const CircularProgressIndicator(),
  data: (items) => ItemList(items),
  error: (message) => Text('Error: $message'),
)
```

Use `AsyncComputedNotifier.withData(data: cachedValue, ...)` to start with
a cached value and only compute on the first source change.

### BindAsync

A dedicated widget for `AsyncStateNotifier` (and `AsyncComputedNotifier`)
that eliminates the boilerplate of writing `Bind<AsyncState<T>>` with a
manual `switch` expression.

```dart
BindAsync<User>(
  notifier: vm.userState,
  loading: (progress) => CircularProgressIndicator(value: progress),
  data: (user) => Text(user.name),
  error: (message) => Text('Error: $message'),
)
```

### BindPauseable

A visibility-aware `Bind` that automatically pauses its subscription when
the widget is offscreen (e.g., in a background tab). Prevents unnecessary
rebuilds for widgets that are not visible.

```dart
BindPauseable<int>(
  notifier: vm.tickNotifier,
  builder: (value) => Text('$value'),
)
```

### ViewModelObserver

Lifecycle hooks for monitoring all ViewModels globally. Add observers at app
startup for logging, performance monitoring, or debugging.

```dart
class DebugObserver extends ViewModelObserver {
  @override
  void onViewModelCreated(BaseViewModel vm) =>
      debugPrint('Created: ${vm.runtimeType}');

  @override
  void onInitCompleted(BaseViewModel vm, Duration elapsed) =>
      debugPrint('${vm.runtimeType}.init() took ${elapsed.inMilliseconds}ms');

  @override
  void onInitFailed(BaseViewModel vm, Object error, StackTrace stack) =>
      debugPrint('${vm.runtimeType}.init() failed: $error');

  @override
  void onViewModelDisposed(BaseViewModel vm) =>
      debugPrint('Disposed: ${vm.runtimeType}');
}

// At app startup:
BaseViewModel.observers.add(DebugObserver());
```

### ScopedLocator

An `InheritedWidget`-based DI scope for subtree-specific service overrides.
Falls back to `ServiceLocator.I` when no scoped registration exists.

```dart
// Provide a scoped service.
ScopedLocator(
  configure: (locator) {
    locator.register<AnalyticsService>(ScreenAnalytics('home'));
  },
  child: HomeScreen(),
)

// Resolve in a descendant widget.
final analytics = ScopedLocator.of(context)<AnalyticsService>();
```

### ServiceLocator Dispose Callbacks

Register cleanup callbacks for singletons so they are automatically disposed
when `reset()` or `unregister()` is called.

```dart
ServiceLocator.I.register<DatabaseService>(
  DatabaseService(),
  onDispose: (db) => db.close(),
);

// Later, during teardown or tests:
ServiceLocator.I.reset(); // calls db.close() automatically
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
