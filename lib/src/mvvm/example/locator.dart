import '../messenger.dart';

// its just an example
// ignore: avoid_classes_with_only_static_members
/// A simple service locator. In a real app, you would use a package
/// like `get_it`.
class ServiceLocator {
  static final messenger = Messenger();
}
