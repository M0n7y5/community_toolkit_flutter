/// Shop example — demonstrates:
///
/// - [RecipientViewModel] for cross-VM messaging (replaces manual Messenger)
/// - [MultiBindEvent] for handling multiple events without nesting
/// - [ViewModelStateMixin] for automatic lifecycle management
/// - [ServiceLocator] for dependency injection (built-in)
/// - [BindSelector] for fine-grained rebuilds
/// - [ValueNotifier.update] extension for read-modify-write
/// - [AsyncStateNotifier] for async data loading
library;

import 'dart:async';

import 'package:community_toolkit/locator.dart';
import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/material.dart';

import 'item_detail_view.dart';
import 'messages.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// Represents a single shop item.
@immutable
class ItemData {
  const ItemData(this.id, this.name, this.price, {this.isFavorite = false});
  final int id;
  final String name;
  final double price;
  final bool isFavorite;

  ItemData copyWith({bool? isFavorite}) =>
      ItemData(id, name, price, isFavorite: isFavorite ?? this.isFavorite);
}

// ---------------------------------------------------------------------------
// Item ViewModel (child)
// ---------------------------------------------------------------------------

class ItemViewModel extends BaseViewModel {
  ItemViewModel(ItemData initialData) {
    itemDataNotifier = notifier<ItemData>(initialData);
    addToCartCommand = command.syncUntyped(execute: _addToCart);
    toggleFavoriteCommand = command.syncUntyped(execute: _toggleFavorite);
  }

  late final ValueNotifier<ItemData> itemDataNotifier;
  late final RelayCommand<void> addToCartCommand;
  late final RelayCommand<void> toggleFavoriteCommand;

  void _addToCart() {
    // Send a message via the global Messenger — the ShopViewModel receives it.
    ServiceLocator.I<Messenger>().send(
      ItemAddedToCartMessage(itemDataNotifier.value),
    );
  }

  void _toggleFavorite() {
    // Use the .update() extension for read-modify-write.
    itemDataNotifier.update(
      (item) => item.copyWith(isFavorite: !item.isFavorite),
    );
  }
}

// ---------------------------------------------------------------------------
// Shop ViewModel — uses RecipientViewModel for automatic Messenger cleanup
// ---------------------------------------------------------------------------

class ShopViewModel extends RecipientViewModel {
  ShopViewModel(super.messenger) {
    itemsState = asyncNotifier<List<ItemViewModel>>();
    cartTotalNotifier = notifier<double>(0);
    itemAddedEvent = event<String>();
  }

  late final AsyncStateNotifier<List<ItemViewModel>> itemsState;
  late final ValueNotifier<double> cartTotalNotifier;

  /// One-shot event fired when an item is added to the cart.
  late final ViewModelEvent<String> itemAddedEvent;

  @override
  Future<void> init() async {
    // RecipientViewModel.receive auto-unregisters on dispose.
    receive<ItemAddedToCartMessage>(_onItemAdded);

    // Load items via AsyncStateNotifier.execute.
    await itemsState.execute(_loadItems);
  }

  Future<List<ItemViewModel>> _loadItems() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return List.generate(
      20,
      (i) => ItemViewModel(ItemData(i, 'Item ${i + 1}', (i + 1) * 2.5)),
    );
  }

  void _onItemAdded(ItemAddedToCartMessage message) {
    cartTotalNotifier.value += message.item.price;
    itemAddedEvent.fire('${message.item.name} added to cart');
  }

  @override
  void dispose() {
    // Dispose child ViewModels.
    for (final item in itemsState.data ?? <ItemViewModel>[]) {
      item.dispose();
    }
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// View
// ---------------------------------------------------------------------------

class ShopView extends StatefulWidget {
  const ShopView({super.key});

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView>
    with ViewModelStateMixin<ShopView, ShopViewModel> {
  @override
  ShopViewModel createViewModel() =>
      ShopViewModel(ServiceLocator.I<Messenger>());

  @override
  Widget build(BuildContext context) =>
      // MultiBindEvent handles multiple one-shot events without nesting.
      MultiBindEvent(
        handlers: [
          EventHandler(vm.itemAddedEvent, (ctx, message) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 1),
              ),
            );
          }),
        ],
        child: Column(
          children: [
            // Cart total header.
            Padding(
              padding: const EdgeInsets.all(16),
              child: Bind<double>(
                notifier: vm.cartTotalNotifier,
                builder: (total) => Text(
                  'Cart Total: \$${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),

            // Items list — uses AsyncState pattern matching.
            Expanded(
              child: Bind<AsyncState<List<ItemViewModel>>>(
                notifier: vm.itemsState,
                builder: (state) => switch (state) {
                  AsyncLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  AsyncError(:final message) => Center(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  AsyncData(:final data) => _ItemList(items: data),
                },
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _ItemList extends StatelessWidget {
  const _ItemList({required this.items});
  final List<ItemViewModel> items;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      final itemVm = items[index];
      return _ItemTile(itemVm: itemVm);
    },
  );
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.itemVm});
  final ItemViewModel itemVm;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(itemVm.itemDataNotifier.value.name),
    subtitle: Text(
      '\$${itemVm.itemDataNotifier.value.price.toStringAsFixed(2)}',
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // BindSelector — only rebuilds when isFavorite changes.
        BindSelector<ItemData, bool>(
          notifier: itemVm.itemDataNotifier,
          selector: (data) => data.isFavorite,
          builder: (isFavorite) => IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: () => itemVm.toggleFavoriteCommand.execute(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
          onPressed: () => itemVm.addToCartCommand.execute(),
        ),
      ],
    ),
    onTap: () {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ItemDetailView(itemData: itemVm.itemDataNotifier.value),
          ),
        ),
      );
    },
  );
}
