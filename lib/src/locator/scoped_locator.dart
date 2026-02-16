import 'package:flutter/widgets.dart';

import 'service_locator.dart';

/// An [InheritedWidget] that provides a scoped [ServiceLocator] to a
/// subtree of the widget tree.
///
/// Use this to override service registrations for specific screens, routes,
/// or widget subtrees — e.g. for multi-tenant UIs, feature-flagged
/// implementations, or test harnesses.
///
/// ### Example
///
/// ```dart
/// ScopedLocator(
///   locator: ServiceLocator.scope()
///     ..register<ApiClient>(MockApiClient()),
///   child: const FeatureScreen(),
/// )
/// ```
///
/// Descendants resolve the locator via [ScopedLocator.of]:
///
/// ```dart
/// final api = ScopedLocator.of(context)<ApiClient>();
/// ```
///
/// If no [ScopedLocator] exists in the widget tree, the global
/// [ServiceLocator.I] is returned.
class ScopedLocator extends InheritedWidget {
  /// The [ServiceLocator] instance provided to this subtree.
  final ServiceLocator locator;

  /// Creates a [ScopedLocator] that provides [locator] to the subtree.
  const ScopedLocator({required this.locator, required super.child, super.key});

  /// Returns the nearest [ServiceLocator] in the widget tree, or the
  /// global [ServiceLocator.I] if no [ScopedLocator] exists above
  /// [context].
  static ServiceLocator of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<ScopedLocator>();
    return widget?.locator ?? ServiceLocator.I;
  }

  @override
  bool updateShouldNotify(ScopedLocator oldWidget) =>
      locator != oldWidget.locator;
}
