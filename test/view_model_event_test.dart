import 'package:community_toolkit/mvvm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViewModelEvent', () {
    test('fire notifies listeners with value', () {
      final event = ViewModelEvent<String>();
      String? received;
      event.addListener(() {
        received = event.value;
      });
      event.fire('hello');
      expect(received, 'hello');
    });

    test('value is null before any fire', () {
      final event = ViewModelEvent<int>();
      expect(event.value, isNull);
    });

    test('value is reset to null after fire', () {
      final event = ViewModelEvent<String>();
      event.fire('test');
      expect(event.value, isNull);
    });

    test('fires multiple times independently', () {
      final event = ViewModelEvent<int>();
      final values = <int?>[];
      event.addListener(() => values.add(event.value));
      event.fire(1);
      event.fire(2);
      event.fire(3);
      expect(values, [1, 2, 3]);
    });
  });

  group('SignalEvent', () {
    test('fire notifies listeners', () {
      final event = SignalEvent();
      var notified = false;
      event.addListener(() {
        if (event.fired) notified = true;
      });
      event.fire();
      expect(notified, isTrue);
    });

    test('fired is false before fire', () {
      final event = SignalEvent();
      expect(event.fired, isFalse);
    });

    test('fired is reset to false after fire', () {
      final event = SignalEvent();
      event.fire();
      expect(event.fired, isFalse);
    });

    test('fires multiple times', () {
      final event = SignalEvent();
      var count = 0;
      event.addListener(() {
        if (event.fired) count++;
      });
      event.fire();
      event.fire();
      event.fire();
      expect(count, 3);
    });
  });
}
