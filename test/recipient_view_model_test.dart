import 'package:community_toolkit/mvvm.dart';
import 'package:flutter_test/flutter_test.dart';

class _ItemAdded {
  final int id;
  _ItemAdded(this.id);
}

class _ItemRemoved {
  final int id;
  _ItemRemoved(this.id);
}

class _CartVm extends RecipientViewModel {
  _CartVm(super.messenger);

  final received = <int>[];
  final removals = <int>[];

  void startListening() {
    receive<_ItemAdded>((msg) => received.add(msg.id));
  }

  void startListeningRemovals() {
    receive<_ItemRemoved>((msg) => removals.add(msg.id));
  }

  int listenForAdds() => receive<_ItemAdded>((msg) => received.add(msg.id));

  void sendItem(int id) => send(_ItemAdded(id));
}

void main() {
  late Messenger messenger;
  late _CartVm vm;

  setUp(() {
    messenger = Messenger();
    vm = _CartVm(messenger);
  });

  tearDown(() => vm.dispose());

  group('RecipientViewModel', () {
    test('receive registers handler for message type', () async {
      vm.startListening();
      messenger.send(_ItemAdded(42));
      await Future<void>.delayed(Duration.zero);

      expect(vm.received, [42]);
    });

    test('send delivers message to other recipients', () async {
      final otherReceived = <int>[];
      final other = Object();
      messenger.register<_ItemAdded>(other, (msg) => otherReceived.add(msg.id));

      vm.sendItem(7);
      await Future<void>.delayed(Duration.zero);

      expect(otherReceived, [7]);
    });

    test('dispose unregisters all message handlers', () async {
      vm.startListening();
      vm.dispose();

      messenger.send(_ItemAdded(99));
      await Future<void>.delayed(Duration.zero);

      expect(vm.received, isEmpty);
    });

    test('can receive multiple message types', () async {
      vm.startListening();
      vm.startListeningRemovals();

      messenger.send(_ItemAdded(1));
      messenger.send(_ItemRemoved(2));
      await Future<void>.delayed(Duration.zero);

      expect(vm.received, [1]);
      expect(vm.removals, [2]);
    });

    test('receive returns a token for manual unregistration', () async {
      final token = vm.listenForAdds();
      messenger.unregister(vm, token);

      messenger.send(_ItemAdded(5));
      await Future<void>.delayed(Duration.zero);

      expect(vm.received, isEmpty);
    });
  });
}
