import 'dart:async';

/// A simple messenger (or event bus) for decoupled communication.
///
/// This allows different parts of the application (typically ViewModels) to
/// communicate without holding direct references to each other.
///
/// It is generally used as a singleton, often managed by a service locator
/// like `get_it`.
///
/// ### Example
///
/// 1. **Define a Message:**
///    ```dart
///    class UserLoggedInMessage {
///      final String userName;
///      UserLoggedInMessage(this.userName);
///    }
///    ```
///
/// 2. **Register a Listener (e.g., in a ViewModel's constructor):**
///    ```dart
///    // The token is used to unregister later
///    final token = messenger.register<UserLoggedInMessage>(this, (message) {
///      print('User ${message.userName} logged in!');
///    });
///    ```
///
/// 3. **Send a Message (e.g., from another ViewModel):**
///    ```dart
///    messenger.send(UserLoggedInMessage('Alice'));
///    ```
///
/// 4. **Unregister (e.g., in the ViewModel's dispose method):**
///    ```dart
///    messenger.unregister(this, token);
///    // OR to unregister all for a recipient:
///    messenger.unregisterAll(this);
///    ```
class Messenger {
  final Map<Type, Map<Object, Map<int, Function>>> _subscriptions = {};
  var _tokenCounter = 0;

  /// Registers a recipient to listen for messages of type [T].
  ///
  /// - [recipient]: The object that is listening (e.g., a ViewModel instance).
  ///   Used to track and unregister subscriptions.
  /// - [callback]: The function to execute when a message of type [T] is sent.
  ///
  /// Returns a unique token for this specific subscription, which can be used
  /// with [unregister] to remove only this subscription.
  int register<T>(Object recipient, void Function(T message) callback) {
    final type = T;
    final token = _tokenCounter++;

    _subscriptions.putIfAbsent(type, () => {});
    _subscriptions[type]!.putIfAbsent(recipient, () => {});
    _subscriptions[type]![recipient]![token] = callback;

    return token;
  }

  /// Sends a [message] to all registered listeners of type [T].
  ///
  /// The static type parameter [T] is used to look up subscriptions,
  /// matching the behaviour of [register]. This means `send<Animal>(Dog())`
  /// will deliver to listeners registered with `register<Animal>(...)`.
  void send<T>(T message) {
    final type = T;
    if (_subscriptions.containsKey(type)) {
      final recipients = _subscriptions[type]!;
      // Create a copy of the maps to iterate over, in case a callback
      // modifies the original subscription list while we are iterating.
      for (final recipientSubs in recipients.values.toList()) {
        for (final callback in recipientSubs.values.toList()) {
          // Use a future to dispatch the message asynchronously, preventing
          // a sender from being blocked by a long-running receiver.
          unawaited(Future(() => callback(message)));
        }
      }
    }
  }

  /// Unregisters a specific subscription for a [recipient].
  void unregister(Object recipient, int token) {
    for (final typeSubs in _subscriptions.values) {
      if (typeSubs.containsKey(recipient)) {
        typeSubs[recipient]!.remove(token);
        if (typeSubs[recipient]!.isEmpty) {
          typeSubs.remove(recipient);
        }
      }
    }
  }

  /// Unregisters a [recipient] from all messages it is subscribed to.
  void unregisterAll(Object recipient) {
    for (final typeSubs in _subscriptions.values) {
      typeSubs.remove(recipient);
    }
  }
}
