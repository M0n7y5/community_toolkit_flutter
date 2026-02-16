/// Login example — demonstrates:
///
/// - [ValidationMixin] for field-level validation with [validateField]
/// - [SignalEvent] / [BindSignalEvent] for payloadless events
/// - [ForceValueNotifier] via [forceNotifier] for coarse-equality objects
/// - [Bind2] for combining two notifiers
/// - [command] factory with [canExecute] wired to [isValidNotifier]
library;

import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

/// Represents a logged-in user profile.
@immutable
class UserProfile {
  const UserProfile({required this.email, required this.displayName});
  final String email;
  final String displayName;
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class LoginViewModel extends BaseViewModel with ValidationMixin {
  LoginViewModel() {
    emailNotifier = notifier<String>('');
    passwordNotifier = notifier<String>('');

    // ForceValueNotifier — always notifies listeners even when the new
    // value is "equal" to the old one (useful for objects with coarse
    // equality).
    profileNotifier = forceNotifier<UserProfile?>(null);

    loginSuccessEvent = signalEvent();

    loginCommand = command.untyped(
      executeAsync: _login,
      canExecute: () => isValid && emailNotifier.value.isNotEmpty,
      listenables: [isValidNotifier, emailNotifier],
    );
  }

  late final ValueNotifier<String> emailNotifier;
  late final ValueNotifier<String> passwordNotifier;
  late final ForceValueNotifier<UserProfile?> profileNotifier;
  late final SignalEvent loginSuccessEvent;
  late final RelayCommand<void> loginCommand;

  /// Validates email using the [validateField] helper from [ValidationMixin].
  void onEmailChanged(String value) {
    emailNotifier.value = value;
    validateField<String>('email', value, [
      (v) => v.isEmpty ? 'Email is required' : null,
      (v) => !v.contains('@') ? 'Enter a valid email' : null,
    ]);
  }

  /// Validates password using the [validateField] helper.
  void onPasswordChanged(String value) {
    passwordNotifier.value = value;
    validateField<String>('password', value, [
      (v) => v.isEmpty ? 'Password is required' : null,
      (v) => v.length < 6 ? 'Must be at least 6 characters' : null,
    ]);
  }

  Future<void> _login() async {
    // Simulate a network call.
    await Future<void>.delayed(const Duration(seconds: 2));

    // ForceValueNotifier ensures listeners are notified even if
    // the "same" profile is set (e.g. after a refresh).
    profileNotifier.value = UserProfile(
      email: emailNotifier.value,
      displayName: emailNotifier.value.split('@').first,
    );

    loginSuccessEvent.fire();
  }
}

// ---------------------------------------------------------------------------
// View
// ---------------------------------------------------------------------------

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with ViewModelStateMixin<LoginView, LoginViewModel> {
  @override
  LoginViewModel createViewModel() => LoginViewModel();

  @override
  Widget build(BuildContext context) =>
      // BindSignalEvent — handles the payloadless login-success signal.
      BindSignalEvent(
        event: vm.loginSuccessEvent,
        handler: (ctx) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Profile display (ForceValueNotifier) ---
                Bind<UserProfile?>(
                  notifier: vm.profileNotifier,
                  builder: (profile) {
                    if (profile == null) {
                      return const SizedBox.shrink();
                    }
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Welcome, ${profile.displayName}!',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(profile.email),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // --- Email field with validation ---
                // Bind<bool> on isValidNotifier to reactively show errors.
                Bind<bool>(
                  notifier: vm.isValidNotifier,
                  builder: (_) => TextField(
                    onChanged: vm.onEmailChanged,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: vm.getFieldError('email'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Password field with validation ---
                Bind<bool>(
                  notifier: vm.isValidNotifier,
                  builder: (_) => TextField(
                    onChanged: vm.onPasswordChanged,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: vm.getFieldError('password'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Login button (disabled until valid) ---
                BindCommand<void>.untyped(
                  command: vm.loginCommand,
                  child: const Text('Login'),
                  builder: (onPressed, child, isExecuting) {
                    if (isExecuting) {
                      return const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(onPressed: onPressed, child: child),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
}
