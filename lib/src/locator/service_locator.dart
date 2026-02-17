/// A minimal, synchronous service locator for dependency injection.
///
/// Designed as a lightweight alternative to `get_it` that covers the most
/// common use case: registering and resolving singleton services.
///
/// Typically accessed via the global [ServiceLocator.I] instance.
///
/// ### Example
///
/// ```dart
/// // Register services at startup.
/// ServiceLocator.I.register<DatabaseService>(DatabaseService());
/// ServiceLocator.I.register<ApiClient>(ApiClient(db: ServiceLocator.I<DatabaseService>()));
///
/// // Resolve anywhere.
/// final db = ServiceLocator.I<DatabaseService>();
///
/// // In tests.
/// setUp(() => ServiceLocator.I.register<DatabaseService>(mockDb));
/// tearDown(() => ServiceLocator.I.reset());
/// ```
class ServiceLocator {
  ServiceLocator._();

  /// The global singleton instance.
  static final ServiceLocator I = ServiceLocator._();

  /// Creates a new, independent [ServiceLocator] instance.
  ///
  /// Use this to create scoped containers for subtree-scoped dependency
  /// injection via `ScopedLocator`, or for isolated test containers.
  ///
  /// ```dart
  /// final scope = ServiceLocator.scope()
  ///   ..register<ApiClient>(MockApiClient());
  /// ```
  // ignore: prefer_constructors_over_static_methods
  static ServiceLocator scope() => ServiceLocator._();

  final Map<Type, Object> _singletons = {};
  final Map<Type, Object Function()> _factories = {};
  final Map<Type, void Function(Object)> _disposers = {};

  /// Resolves a registered instance of type [T].
  ///
  /// Throws [StateError] if [T] has not been registered.
  T call<T extends Object>() {
    final instance = _singletons[T];
    if (instance != null) {
      return instance as T;
    }

    final factory = _factories[T];
    if (factory != null) {
      final created = factory() as T;
      _singletons[T] = created;
      _factories.remove(T);
      return created;
    }

    throw StateError(
      '$T is not registered. Call ServiceLocator.I.register<$T>() first.',
    );
  }

  /// Registers a singleton [instance] of type [T].
  ///
  /// If [onDispose] is provided, it will be called with the instance when
  /// [reset] or [unregister] is called.
  ///
  /// Throws [StateError] if [T] is already registered. Use
  /// [registerIfAbsent] for idempotent registration.
  void register<T extends Object>(T instance, {void Function(T)? onDispose}) {
    if (_singletons.containsKey(T) || _factories.containsKey(T)) {
      throw StateError(
        '$T is already registered. '
        'Call unregister<$T>() first or use registerIfAbsent().',
      );
    }
    _singletons[T] = instance;
    if (onDispose != null) {
      _disposers[T] = (obj) => onDispose(obj as T);
    }
  }

  /// Registers [instance] only if [T] is not already registered.
  ///
  /// If [onDispose] is provided, it will be called with the instance when
  /// [reset] or [unregister] is called.
  ///
  /// Returns `true` if the registration was performed, `false` if [T]
  /// was already present.
  bool registerIfAbsent<T extends Object>(
    T instance, {
    void Function(T)? onDispose,
  }) {
    if (_singletons.containsKey(T) || _factories.containsKey(T)) {
      return false;
    }
    _singletons[T] = instance;
    if (onDispose != null) {
      _disposers[T] = (obj) => onDispose(obj as T);
    }
    return true;
  }

  /// Registers a lazy singleton that is created on first resolution.
  ///
  /// The [factory] is called exactly once — on the first [call] for [T].
  /// Subsequent calls return the cached instance.
  ///
  /// If [onDispose] is provided, it will be called with the instance when
  /// [reset] or [unregister] is called (only if the instance was created).
  ///
  /// Throws [StateError] if [T] is already registered.
  void registerLazy<T extends Object>(
    T Function() factory, {
    void Function(T)? onDispose,
  }) {
    if (_singletons.containsKey(T) || _factories.containsKey(T)) {
      throw StateError(
        '$T is already registered. '
        'Call unregister<$T>() first.',
      );
    }
    _factories[T] = factory;
    if (onDispose != null) {
      _disposers[T] = (obj) => onDispose(obj as T);
    }
  }

  /// Returns `true` if [T] has been registered (eager or lazy).
  bool isRegistered<T extends Object>() =>
      _singletons.containsKey(T) || _factories.containsKey(T);

  /// Removes the registration for [T].
  ///
  /// Calls the `onDispose` callback if one was provided during registration
  /// and the instance has been created. Does nothing if [T] is not
  /// registered.
  void unregister<T extends Object>() {
    final instance = _singletons.remove(T);
    _factories.remove(T);
    final disposer = _disposers.remove(T);
    if (disposer != null && instance != null) {
      disposer(instance);
    }
  }

  /// Removes all registrations.
  ///
  /// Calls all `onDispose` callbacks for singletons that have been created.
  ///
  /// Returns a [Future] for drop-in compatibility with `get_it`'s async
  /// `reset()` in test teardowns.
  Future<void> reset() async {
    for (final entry in _singletons.entries) {
      final disposer = _disposers[entry.key];
      if (disposer != null) {
        disposer(entry.value);
      }
    }
    _singletons.clear();
    _factories.clear();
    _disposers.clear();
  }
}
