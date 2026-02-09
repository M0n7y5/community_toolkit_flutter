# Flutter MVVM Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2.svg)](https://dart.dev/)

A lightweight, production-ready MVVM (Model-View-ViewModel) framework for Flutter applications. Inspired by modern C# MVVM patterns, this framework provides clean architecture, reactive state management, and automatic lifecycle handling without external dependencies.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
- [API Reference](#api-reference)
  - [BaseViewModel](#baseviewmodel)
  - [RelayCommand](#relaycommand)
  - [Binding Widgets](#binding-widgets)
  - [Messenger](#messenger)
- [Real-World Examples](#real-world-examples)
  - [User Authentication](#user-authentication)
  - [E-commerce Product List](#e-commerce-product-list)
  - [Settings Management](#settings-management)
- [Best Practices](#best-practices)
- [Performance Considerations](#performance-considerations)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

## Features

- 🚀 **Zero Dependencies**: Pure Flutter/Dart implementation
- 🔄 **Reactive Architecture**: Built on Flutter's `ChangeNotifier`
- 🧹 **Automatic Lifecycle Management**: Prevents memory leaks
- ⚡ **Performance Optimized**: Selective UI updates with `BindSelector`
- 🎯 **Type Safe**: Full generic support throughout
- 🏗️ **Clean Architecture**: Clear separation of concerns
- 🔧 **Flexible**: Works with any dependency injection solution
- 📱 **Production Ready**: Battle-tested patterns and error handling

## Quick Start

### 1. Add to your project

```yaml
dependencies:
  flutter_mvvm_framework:
    path: lib/mvvm  # Adjust path as needed
```

### 2. Create your first ViewModel

```dart
import 'package:flutter/foundation.dart';
import 'mvvm/base_view_model.dart';

class CounterViewModel extends BaseViewModel {
  late final ValueNotifier<int> counter = autoDispose(ValueNotifier(0));

  late final RelayCommand incrementCommand = autoDispose(
    RelayCommand.syncUntyped(
      execute: () => counter.value++,
      canExecute: () => counter.value < 10,
      listenables: [counter],
    ),
  );

  @override
  Future<void> init() async {
    // Initialize your ViewModel here
    await Future.delayed(const Duration(seconds: 1));
  }
}
```

### 3. Use in your View

```dart
import 'package:flutter/material.dart';
import 'mvvm/bind.dart';
import 'mvvm/bind_command.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late final CounterViewModel vm = CounterViewModel();

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Bind<int>(
              notifier: vm.counter,
              builder: (count) => Text(
                'Count: $count',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 20),
            BindCommand.untyped(
              command: vm.incrementCommand,
              child: const Text('Increment'),
              builder: (onPressed, child, isExecuting) => ElevatedButton(
                onPressed: onPressed,
                child: isExecuting
                  ? const CircularProgressIndicator()
                  : child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Core Concepts

### MVVM Pattern

The MVVM (Model-View-ViewModel) pattern separates your application into three distinct layers:

- **Model**: Business logic and data structures
- **View**: UI components that display data
- **ViewModel**: Presentation logic and state management

### Reactive State Management

This framework uses Flutter's built-in `ChangeNotifier` for reactive updates:

```dart
// ViewModel
late final ValueNotifier<String> userName = autoDispose(ValueNotifier(''));

// View
Bind<String>(
  notifier: viewModel.userName,
  builder: (name) => Text('Hello, $name!'),
);
```

### Command Pattern

Commands encapsulate actions and their execution conditions:

```dart
late final RelayCommand saveCommand = autoDispose(
  RelayCommand.untyped(
    executeAsync: _saveData,
    canExecute: () => isFormValid && !isSaving,
    listenables: [formValidationNotifier],
  ),
);
```

### Automatic Resource Management

The `autoDispose` method ensures proper cleanup:

```dart
class MyViewModel extends BaseViewModel {
  // These are automatically disposed when ViewModel is disposed
  late final ValueNotifier<int> counter = autoDispose(ValueNotifier(0));
  late final RelayCommand actionCommand = autoDispose(RelayCommand.syncUntyped(...));
}
```

## API Reference

### BaseViewModel

The foundation class for all ViewModels providing lifecycle management.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `loadingNotifier` | `ValueNotifier<bool>` | Tracks initialization state |
| `_disposables` | `List<ChangeNotifier>` | Internal list of auto-disposed resources |

#### Methods

##### `autoDispose<T extends ChangeNotifier>(T disposable) -> T`

Registers a `ChangeNotifier` for automatic disposal.

**Parameters:**
- `disposable`: The `ChangeNotifier` to register

**Returns:** The same disposable for chaining

**Example:**
```dart
late final myNotifier = autoDispose(ValueNotifier('initial'));
```

##### `setLoading(bool loading) -> void`

Manually sets the loading state.

**Parameters:**
- `loading`: New loading state

##### `init() -> Future<void>`

Override this method for initialization logic. Called automatically on creation.

**Example:**
```dart
@override
Future<void> init() async {
  await loadUserData();
}
```

##### `dispose() -> void`

Disposes the ViewModel and all registered resources. Call this in your View's `dispose()`.

### RelayCommand<T>

Implements the command pattern for action encapsulation.

#### Factory Constructors

##### `RelayCommand<T>()`

Creates a command that accepts a parameter of type `T`.

**Parameters:**
- `executeAsync`: `Future<void> Function(T)` - The async action to execute
- `canExecute`: `bool Function(T)?` - Optional condition for execution
- `listenables`: `List<Listenable>` - Dependencies for `canExecute` re-evaluation
- `errorNotifier`: `ValueNotifier<String?>?` - Optional error reporting

##### `RelayCommand.untyped()`

Creates a command that doesn't accept parameters.

**Parameters:** Same as above but without type parameter

##### `RelayCommand.sync<T>()` and `RelayCommand.syncUntyped()`

Convenience constructors for synchronous actions.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `executingNotifier` | `ValueNotifier<bool>` | Tracks execution state |
| `errorNotifier` | `ValueNotifier<String?>?` | Error reporting (if provided) |

#### Methods

##### `canExecute([T? arg]) -> bool`

Checks if the command can execute.

**Returns:** `true` if executable, `false` otherwise

##### `execute([T? arg]) -> Future<void>`

Executes the command if `canExecute` returns `true`.

##### `requery() -> void`

Manually triggers `canExecute` re-evaluation.

### Binding Widgets

#### Bind<T>

Simple reactive binding widget.

**Parameters:**
- `notifier`: `ValueNotifier<T>` - The notifier to listen to
- `builder`: `Widget Function(T value)` - Builder function for UI

**Example:**
```dart
Bind<String>(
  notifier: viewModel.userName,
  builder: (name) => Text('Hello, $name'),
);
```

#### BindSelector<T, S>

Performance-optimized selective binding.

**Parameters:**
- `notifier`: `ValueNotifier<T>` - The source notifier
- `selector`: `S Function(T value)` - Function to select the watched value
- `builder`: `Widget Function(S value)` - Builder for the selected value

**Example:**
```dart
BindSelector<User, String>(
  notifier: userNotifier,
  selector: (user) => user.name,
  builder: (name) => Text(name),
);
```

#### BindCommand<T>

Connects commands to UI elements.

**Parameters:**
- `command`: `RelayCommand<T>` - The command to bind
- `commandParameter`: `T?` - Parameter for typed commands
- `child`: `Widget` - The child widget
- `builder`: `Widget Function(VoidCallback?, Widget, bool)` - Custom builder

**Example:**
```dart
BindCommand.untyped(
  command: loginCommand,
  child: const Text('Login'),
  builder: (onPressed, child, isExecuting) => ElevatedButton(
    onPressed: onPressed,
    child: isExecuting ? const CircularProgressIndicator() : child,
  ),
);
```

### Messenger

Decoupled communication system for cross-ViewModel messaging.

#### Methods

##### `register<T>(Object recipient, void Function(T message) callback) -> int`

Registers a message listener.

**Parameters:**
- `recipient`: The listening object (usually `this`)
- `callback`: Function to call when message is received

**Returns:** Registration token for unregistration

##### `send<T>(T message) -> void`

Sends a message to all registered listeners.

**Parameters:**
- `message`: The message to send

##### `unregister(Object recipient, int token) -> void`

Unregisters a specific listener.

##### `unregisterAll(Object recipient) -> void`

Unregisters all listeners for a recipient.

**Example:**
```dart
// Define message
class UserLoggedIn { final String userId; UserLoggedIn(this.userId); }

// Register listener
final token = messenger.register<UserLoggedIn>(
  this,
  (message) => print('User ${message.userId} logged in'),
);

// Send message
messenger.send(UserLoggedIn('user123'));

// Cleanup
messenger.unregister(this, token);
```

## Real-World Examples

### User Authentication

Complete authentication flow with form validation, error handling, and reactive UI updates.

#### ViewModel Implementation

```dart
class AuthViewModel extends BaseViewModel {
  final email = autoDispose(ValueNotifier(''));
  final password = autoDispose(ValueNotifier(''));
  final errorMessage = autoDispose(ValueNotifier<String?>(null));
  final isLoading = autoDispose(ValueNotifier(false));

  late final RelayCommand loginCommand;

  AuthViewModel() {
    loginCommand = autoDispose(RelayCommand.untyped(
      executeAsync: _performLogin,
      canExecute: () => _isFormValid() && !isLoading.value,
      listenables: [email, password, isLoading],
      errorNotifier: errorMessage,
    ));
  }

  bool _isFormValid() {
    return email.value.contains('@') && password.value.length >= 6;
  }

  Future<void> _performLogin() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (email.value != 'user@example.com') {
        throw Exception('Invalid credentials');
      }

      // Navigate to home screen
      // navigator.pushReplacementNamed('/home');
    } finally {
      isLoading.value = false;
    }
  }
}
```

#### UI Implementation with Binding Widgets

```dart
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final AuthViewModel vm = AuthViewModel();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Sync text controllers with ViewModel notifiers
    _emailController.addListener(() => vm.email.value = _emailController.text);
    _passwordController.addListener(() => vm.password.value = _passwordController.text);
  }

  @override
  void dispose() {
    vm.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bind to loading state to show loading indicator
            Bind<bool>(
              notifier: vm.isLoading,
              builder: (isLoading) {
                if (isLoading) {
                  return const CircularProgressIndicator();
                }
                return const SizedBox.shrink();
              },
            ),

            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: vm.email.value.isNotEmpty && !vm.email.value.contains('@')
                  ? 'Invalid email format'
                  : null,
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: vm.password.value.isNotEmpty && vm.password.value.length < 6
                  ? 'Password must be at least 6 characters'
                  : null,
              ),
              obscureText: true,
            ),

            const SizedBox(height: 24),

            // Bind to error message
            Bind<String?>(
              notifier: vm.errorMessage,
              builder: (error) => error != null
                ? Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.shade100,
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // BindCommand for login button with loading state
            BindCommand.untyped(
              command: vm.loginCommand,
              child: const Text('Login'),
              builder: (onPressed, child, isExecuting) {
                if (isExecuting) {
                  return const ElevatedButton(
                    onPressed: null,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: child,
                );
              },
            ),

            const SizedBox(height: 16),

            // Show validation status
            Bind<String>(
              notifier: vm.email,
              builder: (email) => Bind<String>(
                notifier: vm.password,
                builder: (password) => Text(
                  vm._isFormValid()
                    ? 'Form is valid'
                    : 'Please fill in all fields correctly',
                  style: TextStyle(
                    color: vm._isFormValid() ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### E-commerce Product List

Complex list with filtering, sorting, cart integration, and performance optimization using `BindSelector`.

#### Data Models

```dart
class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final bool isFavorite;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.isFavorite = false,
  });
}

class CartUpdated {
  final int itemCount;
  CartUpdated(this.itemCount);
}
```

#### ViewModel Implementation

```dart
class ProductListViewModel extends BaseViewModel {
  final products = autoDispose(ValueNotifier<List<Product>>([]));
  final cartItems = autoDispose(ValueNotifier<List<Product>>([]));
  final searchQuery = autoDispose(ValueNotifier(''));
  final selectedCategory = autoDispose(ValueNotifier<String?>(null));
  final categories = autoDispose(ValueNotifier<List<String>>([]));

  late final RelayCommand<Product> addToCartCommand;
  late final RelayCommand<Product> toggleFavoriteCommand;
  late final RelayCommand<String> filterByCategoryCommand;

  ProductListViewModel() {
    addToCartCommand = autoDispose(RelayCommand<Product>(
      executeAsync: (product) async {
        cartItems.value = [...cartItems.value, product];
        // Send message for cart update
        messenger.send(CartUpdated(cartItems.value.length));
      },
    ));

    toggleFavoriteCommand = autoDispose(RelayCommand<Product>(
      executeAsync: (product) async {
        final updatedProducts = products.value.map((p) {
          if (p.id == product.id) {
            return Product(
              id: p.id,
              name: p.name,
              category: p.category,
              price: p.price,
              isFavorite: !p.isFavorite,
            );
          }
          return p;
        }).toList();
        products.value = updatedProducts;
      },
    ));

    filterByCategoryCommand = autoDispose(RelayCommand<String>(
      executeAsync: (category) async {
        selectedCategory.value = category;
        await _loadFilteredProducts();
      },
    ));
  }

  @override
  Future<void> init() async {
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    products.value = [
      Product(id: 1, name: 'Gaming Laptop', category: 'Electronics', price: 1299.99),
      Product(id: 2, name: 'Programming Book', category: 'Education', price: 49.99),
      Product(id: 3, name: 'Wireless Headphones', category: 'Electronics', price: 199.99),
      Product(id: 4, name: 'Coffee Mug', category: 'Lifestyle', price: 12.99),
    ];

    categories.value = ['All', ...products.value.map((p) => p.category).toSet()];
  }

  Future<void> _loadFilteredProducts() async {
    if (selectedCategory.value == null || selectedCategory.value == 'All') {
      await _loadProducts();
      return;
    }

    final filtered = products.value.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(searchQuery.value.toLowerCase());
      final matchesCategory = product.category == selectedCategory.value;
      return matchesSearch && matchesCategory;
    }).toList();

    products.value = filtered;
  }
}
```

#### UI Implementation with Advanced Binding

```dart
class ProductListView extends StatefulWidget {
  const ProductListView({super.key});

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  late final ProductListViewModel vm = ProductListViewModel();

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          // Bind to cart count
          Bind<List<Product>>(
            notifier: vm.cartItems,
            builder: (cartItems) => IconButton(
              icon: Badge(
                label: Text(cartItems.length.toString()),
                child: const Icon(Icons.shopping_cart),
              ),
              onPressed: () {
                // Navigate to cart
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${cartItems.length} items in cart')),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => vm.searchQuery.value = value,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // Category filter
          Bind<List<String>>(
            notifier: vm.categories,
            builder: (categories) => SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Bind<String?>(
                    notifier: vm.selectedCategory,
                    builder: (selected) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FilterChip(
                        label: Text(category),
                        selected: selected == category,
                        onSelected: (selected) {
                          if (selected) {
                            vm.filterByCategoryCommand.execute(category);
                          } else {
                            vm.filterByCategoryCommand.execute('All');
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Products list with BindSelector for performance
          Expanded(
            child: Bind<List<Product>>(
              notifier: vm.products,
              builder: (products) => ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  product.category,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Favorite button with BindSelector (only rebuilds on isFavorite change)
                          BindSelector<Product, bool>(
                            notifier: ValueNotifier(product),
                            selector: (p) => p.isFavorite,
                            builder: (isFavorite) => IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : null,
                              ),
                              onPressed: () => vm.toggleFavoriteCommand.execute(product),
                            ),
                          ),

                          // Add to cart button
                          BindCommand<Product>(
                            command: vm.addToCartCommand,
                            commandParameter: product,
                            child: const Icon(Icons.add_shopping_cart),
                            builder: (onPressed, child, isExecuting) => IconButton(
                              icon: isExecuting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : child,
                              onPressed: onPressed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Settings Management

Settings screen with validation, persistence, and dynamic UI updates using multiple binding widgets.

#### Messages and Data Models

```dart
class SettingsSaved {
  // Message sent when settings are successfully saved
}

class SettingsViewModel extends BaseViewModel {
  final themeMode = autoDispose(ValueNotifier(ThemeMode.system));
  final notificationsEnabled = autoDispose(ValueNotifier(true));
  final language = autoDispose(ValueNotifier('en'));
  final isSaving = autoDispose(ValueNotifier(false));
  final saveStatus = autoDispose(ValueNotifier<String?>(null));

  // Available options
  final availableLanguages = ['en', 'es', 'fr', 'de'];

  late final RelayCommand saveSettingsCommand;
  late final RelayCommand resetSettingsCommand;

  SettingsViewModel() {
    saveSettingsCommand = autoDispose(RelayCommand.untyped(
      executeAsync: _saveSettings,
      canExecute: () => _hasUnsavedChanges() && !isSaving.value,
      listenables: [themeMode, notificationsEnabled, language, isSaving],
    ));

    resetSettingsCommand = autoDispose(RelayCommand.untyped(
      executeAsync: _resetSettings,
      canExecute: () => !isSaving.value,
      listenables: [isSaving],
    ));

    // Load saved settings
    _loadSettings();
  }

  bool _hasUnsavedChanges() {
    // In a real app, compare with original values
    return true; // Simplified for demo
  }

  Future<void> _loadSettings() async {
    // Simulate loading from shared preferences
    await Future.delayed(const Duration(milliseconds: 500));

    // Load saved values (simulated)
    themeMode.value = ThemeMode.light;
    notificationsEnabled.value = true;
    language.value = 'en';
  }

  Future<void> _saveSettings() async {
    isSaving.value = true;
    saveStatus.value = null;

    try {
      // Simulate saving to shared preferences
      await Future.delayed(const Duration(seconds: 1));

      // Simulate successful save
      saveStatus.value = 'Settings saved successfully!';

      // Send success message
      messenger.send(SettingsSaved());
    } catch (e) {
      saveStatus.value = 'Failed to save settings: ${e.toString()}';
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _resetSettings() async {
    isSaving.value = true;

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // Reset to defaults
      themeMode.value = ThemeMode.system;
      notificationsEnabled.value = true;
      language.value = 'en';
      saveStatus.value = 'Settings reset to defaults';
    } finally {
      isSaving.value = false;
    }
  }
}
```

#### UI Implementation with Comprehensive Binding

```dart
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final SettingsViewModel vm = SettingsViewModel();

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          // BindCommand for save button
          BindCommand.untyped(
            command: vm.saveSettingsCommand,
            child: const Text('Save'),
            builder: (onPressed, child, isExecuting) => TextButton(
              onPressed: onPressed,
              child: isExecuting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : child,
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Status message
          Bind<String?>(
            notifier: vm.saveStatus,
            builder: (status) => status != null
              ? Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: status.contains('success')
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status.contains('success')
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          ),

          // Theme Mode Section
          const ListTile(
            title: Text(
              'Appearance',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Bind<ThemeMode>(
            notifier: vm.themeMode,
            builder: (themeMode) => Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (value) {
                    if (value != null) vm.themeMode.value = value;
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (value) {
                    if (value != null) vm.themeMode.value = value;
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('System'),
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (value) {
                    if (value != null) vm.themeMode.value = value;
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Notifications Section
          const ListTile(
            title: Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Bind<bool>(
            notifier: vm.notificationsEnabled,
            builder: (enabled) => SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: Text(enabled ? 'Notifications are enabled' : 'Notifications are disabled'),
              value: enabled,
              onChanged: (value) => vm.notificationsEnabled.value = value,
            ),
          ),

          const Divider(),

          // Language Section
          const ListTile(
            title: Text(
              'Language',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Bind<String>(
            notifier: vm.language,
            builder: (currentLanguage) => Column(
              children: vm.availableLanguages.map((lang) {
                return RadioListTile<String>(
                  title: Text(_getLanguageDisplayName(lang)),
                  subtitle: Text(_getLanguageNativeName(lang)),
                  value: lang,
                  groupValue: currentLanguage,
                  onChanged: (value) {
                    if (value != null) vm.language.value = value;
                  },
                );
              }).toList(),
            ),
          ),

          const Divider(),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Save button with BindCommand
                BindCommand.untyped(
                  command: vm.saveSettingsCommand,
                  child: const Text('Save Settings'),
                  builder: (onPressed, child, isExecuting) => ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: isExecuting
                      ? const CircularProgressIndicator()
                      : child,
                  ),
                ),

                const SizedBox(height: 12),

                // Reset button with BindCommand
                BindCommand.untyped(
                  command: vm.resetSettingsCommand,
                  child: const Text('Reset to Defaults'),
                  builder: (onPressed, child, isExecuting) => OutlinedButton(
                    onPressed: onPressed,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: isExecuting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : child,
                  ),
                ),

                const SizedBox(height: 24),

                // Show if there are unsaved changes
                Bind<ThemeMode>(
                  notifier: vm.themeMode,
                  builder: (theme) => Bind<bool>(
                    notifier: vm.notificationsEnabled,
                    builder: (notifications) => Bind<String>(
                      notifier: vm.language,
                      builder: (language) => Text(
                        vm._hasUnsavedChanges()
                          ? 'You have unsaved changes'
                          : 'All changes saved',
                        style: TextStyle(
                          color: vm._hasUnsavedChanges()
                            ? Colors.orange
                            : Colors.green,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'es': return 'Spanish';
      case 'fr': return 'French';
      case 'de': return 'German';
      default: return code;
    }
  }

  String _getLanguageNativeName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      default: return code;
    }
  }
}
```

## Best Practices

### ViewModel Design

1. **Single Responsibility**: Each ViewModel should handle one screen/feature
2. **Dependency Injection**: Use constructor injection for services
3. **Error Handling**: Always provide error notifiers for async operations
4. **State Management**: Use appropriate notifier types for different data

### Command Usage

1. **Async for Network**: Use async commands for API calls
2. **Validation**: Implement `canExecute` for form validation
3. **Dependencies**: Include all relevant notifiers in `listenables`
4. **Error Propagation**: Use `errorNotifier` for user feedback

### UI Binding

1. **BindSelector**: Use for complex objects to optimize rebuilds
2. **Minimal Builders**: Keep builder functions simple and focused
3. **Loading States**: Always handle loading states in UI
4. **Error Display**: Show errors prominently and clearly

### Resource Management

1. **AutoDispose**: Always wrap notifiers and commands with `autoDispose`
2. **Manual Cleanup**: Call `dispose()` in View's `dispose()` method
3. **Messenger Cleanup**: Unregister messenger listeners in `dispose()`

### Performance

1. **Selective Updates**: Use `BindSelector` for large objects
2. **Command Dependencies**: Minimize `listenables` array size
3. **Builder Optimization**: Avoid expensive operations in builders
4. **List Optimization**: Use `ListView.builder` with proper keys

## Performance Considerations

### Memory Management

- All `autoDispose` resources are automatically cleaned up
- Messenger listeners are properly unregistered
- No memory leaks with proper ViewModel disposal

### UI Optimization

- `BindSelector` prevents unnecessary rebuilds
- Commands automatically manage execution state
- Efficient listener management

### State Updates

- Batch state changes when possible
- Use appropriate notifier types
- Minimize notifier value changes

## Troubleshooting

### Common Issues

**ViewModel not disposing properly:**
```dart
// ❌ Wrong
class MyView extends StatelessWidget {
  final vm = MyViewModel();
  // ViewModel never disposed!
}

// ✅ Correct
class MyView extends StatefulWidget {
  @override
  State<MyView> createState() => _MyViewState();
}

class _MyViewState extends State<MyView> {
  late final vm = MyViewModel();

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }
}
```

**Command not re-evaluating:**
```dart
// ❌ Missing listenables
RelayCommand.untyped(
  executeAsync: _save,
  canExecute: () => formIsValid,
  // Missing: listenables: [validationNotifier]
)

// ✅ Correct
RelayCommand.untyped(
  executeAsync: _save,
  canExecute: () => formIsValid,
  listenables: [validationNotifier],
)
```

**UI not updating:**
```dart
// ❌ Not using autoDispose
class MyViewModel extends BaseViewModel {
  final counter = ValueNotifier(0); // Not auto-disposed!
}

// ✅ Correct
class MyViewModel extends BaseViewModel {
  late final counter = autoDispose(ValueNotifier(0));
}
```

## FAQ

**Q: When should I use `Bind` vs `BindSelector`?**

A: Use `Bind` for simple values. Use `BindSelector` when you only need to watch a specific property of a complex object to optimize rebuilds.

**Q: Can I use this with other state management solutions?**

A: Yes! This framework is designed to be flexible. You can use it alongside Provider, Riverpod, Bloc, or any other solution.

**Q: How do I handle navigation in ViewModels?**

A: Inject a navigation service into your ViewModel and call navigation methods from command execute functions.

**Q: What about testing?**

A: The framework is designed to be easily testable. Mock your services and test ViewModel logic independently of UI.

**Q: Is this production ready?**

A: Yes! This framework follows proven MVVM patterns and includes proper error handling and resource management.

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/flutter-mvvm-framework.git`
3. Install dependencies: `flutter pub get`
4. Run tests: `flutter test`
5. Create a feature branch: `git checkout -b feature/your-feature`
6. Make your changes and add tests
7. Submit a pull request

### Code Style

- Follow Dart's official style guide
- Use meaningful variable and method names
- Add documentation comments for public APIs
- Write comprehensive tests

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Built with ❤️ for the Flutter community