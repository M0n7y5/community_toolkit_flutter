import 'package:flutter/foundation.dart';

import 'base_view_model.dart';
import 'messenger.dart';

/// A [BaseViewModel] that automatically manages [Messenger] subscriptions.
///
/// Inspired by .NET CommunityToolkit's `ObservableRecipient`. Use this as
/// the base class for ViewModels that need to receive cross-VM messages.
/// All subscriptions registered via [receive] are automatically cleaned up
/// when the ViewModel is disposed.
///
/// The [Messenger] instance is provided via the constructor, keeping the
/// ViewModel decoupled from the service locator:
///
/// ```dart
/// class CartViewModel extends RecipientViewModel {
///   CartViewModel(super.messenger);
///
///   late final itemCount = notifier(0);
///
///   @override
///   Future<void> init() async {
///     receive<ItemAddedMessage>((msg) {
///       itemCount.value++;
///     });
///   }
/// }
///
/// // In the screen:
/// @override
/// CartViewModel createViewModel() =>
///     CartViewModel(ServiceLocator.I<Messenger>());
/// ```
class RecipientViewModel extends BaseViewModel {
  /// The [Messenger] instance used for cross-VM communication.
  @protected
  final Messenger messenger;

  /// Creates a [RecipientViewModel] with the given [messenger].
  RecipientViewModel(this.messenger);

  /// Registers a handler for messages of type [T].
  ///
  /// The subscription is automatically removed when this ViewModel is
  /// disposed. Returns the registration token in case manual unregistration
  /// is needed before disposal.
  @protected
  int receive<T>(void Function(T message) handler) =>
      messenger.register<T>(this, handler);

  /// Sends a message of type [T] to all registered listeners.
  @protected
  void send<T>(T message) => messenger.send<T>(message);

  @override
  @mustCallSuper
  void dispose() {
    messenger.unregisterAll(this);
    super.dispose();
  }
}
