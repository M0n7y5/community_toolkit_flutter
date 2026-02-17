import 'package:community_toolkit/mvvm.dart';
import 'package:flutter_test/flutter_test.dart';

class _ValidatedVm extends BaseViewModel with ValidationMixin {
  _ValidatedVm();
}

void main() {
  late _ValidatedVm vm;

  setUp(() {
    vm = _ValidatedVm();
  });

  tearDown(() => vm.dispose());

  group('ValidationMixin', () {
    test('starts valid with no errors', () {
      expect(vm.isValid, isTrue);
      expect(vm.isValidNotifier.value, isTrue);
      expect(vm.fieldErrors, isEmpty);
    });

    test('setFieldError marks invalid', () {
      vm.setFieldError('email', 'Required');

      expect(vm.isValid, isFalse);
      expect(vm.isValidNotifier.value, isFalse);
      expect(vm.getFieldError('email'), 'Required');
    });

    test('clearFieldError restores valid when last error cleared', () {
      vm.setFieldError('email', 'Required');
      vm.clearFieldError('email');

      expect(vm.isValid, isTrue);
      expect(vm.isValidNotifier.value, isTrue);
      expect(vm.getFieldError('email'), isNull);
    });

    test('clearFieldError stays invalid when other errors remain', () {
      vm.setFieldError('email', 'Required');
      vm.setFieldError('password', 'Too short');
      vm.clearFieldError('email');

      expect(vm.isValid, isFalse);
      expect(vm.isValidNotifier.value, isFalse);
      expect(vm.getFieldError('password'), 'Too short');
    });

    test('clearAllErrors restores valid', () {
      vm.setFieldError('email', 'Required');
      vm.setFieldError('password', 'Too short');
      vm.clearAllErrors();

      expect(vm.isValid, isTrue);
      expect(vm.isValidNotifier.value, isTrue);
      expect(vm.fieldErrors, isEmpty);
    });

    test('fieldErrors returns unmodifiable copy', () {
      vm.setFieldError('email', 'Required');
      final errors = vm.fieldErrors;

      expect(() => errors['email'] = 'Modified', throwsUnsupportedError);
    });

    test('setFieldError overwrites existing error', () {
      vm.setFieldError('email', 'Required');
      vm.setFieldError('email', 'Invalid format');

      expect(vm.getFieldError('email'), 'Invalid format');
    });

    test('getFieldError returns null for unknown field', () {
      expect(vm.getFieldError('nonexistent'), isNull);
    });

    test('validateField sets error from first failing validator', () {
      vm.validateField<String>('email', '', [
        (v) => v.isEmpty ? 'Required' : null,
        (v) => !v.contains('@') ? 'Invalid' : null,
      ]);

      expect(vm.getFieldError('email'), 'Required');
      expect(vm.isValid, isFalse);
    });

    test('validateField clears error when all validators pass', () {
      vm.setFieldError('email', 'Required');
      vm.validateField<String>('email', 'user@example.com', [
        (v) => v.isEmpty ? 'Required' : null,
        (v) => !v.contains('@') ? 'Invalid' : null,
      ]);

      expect(vm.getFieldError('email'), isNull);
      expect(vm.isValid, isTrue);
    });

    test('validateField uses first-error-wins strategy', () {
      vm.validateField<String>('password', '', [
        (v) => v.isEmpty ? 'Required' : null,
        (v) => v.length < 6 ? 'Too short' : null,
      ]);

      // Only the first failing validator's error is kept.
      expect(vm.getFieldError('password'), 'Required');
    });

    test('isValidNotifier notifies on state change', () {
      final history = <bool>[];
      vm.isValidNotifier.addListener(() {
        history.add(vm.isValidNotifier.value);
      });

      vm.setFieldError('email', 'Required');
      vm.clearFieldError('email');

      expect(history, [false, true]);
    });
  });
}
