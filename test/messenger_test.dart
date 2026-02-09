import 'package:community_toolkit/mvvm.dart';
import 'package:flutter_test/flutter_test.dart';

class _UserLoggedIn {
  final String name;
  _UserLoggedIn(this.name);
}

class _ItemAdded {
  final int id;
  _ItemAdded(this.id);
}

void main() {
  late Messenger messenger;

  setUp(() {
    messenger = Messenger();
  });

  group('Messenger', () {
    test('delivers message to registered listener', () async {
      String? received;
      final recipient = Object();
      messenger.register<_UserLoggedIn>(recipient, (msg) {
        received = msg.name;
      });
      messenger.send(_UserLoggedIn('Alice'));
      // Messages are dispatched asynchronously via Future().
      await Future<void>.delayed(Duration.zero);
      expect(received, 'Alice');
    });

    test('delivers to multiple recipients', () async {
      final names = <String>[];
      final r1 = Object();
      final r2 = Object();
      messenger.register<_UserLoggedIn>(
        r1,
        (msg) => names.add('r1:${msg.name}'),
      );
      messenger.register<_UserLoggedIn>(
        r2,
        (msg) => names.add('r2:${msg.name}'),
      );
      messenger.send(_UserLoggedIn('Bob'));
      await Future<void>.delayed(Duration.zero);
      expect(names, containsAll(['r1:Bob', 'r2:Bob']));
    });

    test('does not deliver to wrong message type', () async {
      var called = false;
      final recipient = Object();
      messenger.register<_ItemAdded>(recipient, (msg) => called = true);
      messenger.send(_UserLoggedIn('Alice'));
      await Future<void>.delayed(Duration.zero);
      expect(called, isFalse);
    });

    test('unregister removes specific subscription', () async {
      final received = <String>[];
      final recipient = Object();
      final token1 = messenger.register<_UserLoggedIn>(
        recipient,
        (msg) => received.add('sub1:${msg.name}'),
      );
      messenger.register<_UserLoggedIn>(
        recipient,
        (msg) => received.add('sub2:${msg.name}'),
      );

      messenger.unregister(recipient, token1);
      messenger.send(_UserLoggedIn('Test'));
      await Future<void>.delayed(Duration.zero);

      expect(received, ['sub2:Test']);
    });

    test('unregisterAll removes all subscriptions for recipient', () async {
      var called = false;
      final recipient = Object();
      messenger.register<_UserLoggedIn>(recipient, (msg) => called = true);
      messenger.register<_ItemAdded>(recipient, (msg) => called = true);

      messenger.unregisterAll(recipient);
      messenger.send(_UserLoggedIn('X'));
      messenger.send(_ItemAdded(1));
      await Future<void>.delayed(Duration.zero);
      expect(called, isFalse);
    });

    test('register returns unique tokens', () {
      final recipient = Object();
      final t1 = messenger.register<_UserLoggedIn>(recipient, (msg) {});
      final t2 = messenger.register<_UserLoggedIn>(recipient, (msg) {});
      expect(t1, isNot(t2));
    });
  });
}
