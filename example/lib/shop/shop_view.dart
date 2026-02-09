import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:community_toolkit/mvvm.dart';

import '../locator.dart';
import 'item_detail_view.dart';
import 'messages.dart';

// Represents the data for a single item. In a real app, this would be a model.
class ItemData {
  final int id;

  final String name;

  final double price;

  final bool isFavorite;

  ItemData(this.id, this.name, this.price, {this.isFavorite = false});
}

// ViewModel for a single item in the list
class ItemViewModel extends BaseViewModel {
  late final ValueNotifier<ItemData> itemDataNotifier;

  late final RelayCommand<void> addToCartCommand;

  late final RelayCommand<void> toggleFavoriteCommand;

  ItemViewModel(ItemData initialData) {
    itemDataNotifier = autoDispose(ValueNotifier(initialData));

    addToCartCommand = autoDispose(
      RelayCommand.syncUntyped(execute: _addToCart),
    );

    toggleFavoriteCommand = autoDispose(
      RelayCommand.syncUntyped(execute: _toggleFavorite),
    );
  }

  void _addToCart() {
    // Send a message to anyone who is listening that this item was added.
    ServiceLocator.messenger.send(
      ItemAddedToCartMessage(itemDataNotifier.value),
    );
  }

  void _toggleFavorite() {
    final current = itemDataNotifier.value;
    itemDataNotifier.value = ItemData(
      current.id,
      current.name,
      current.price,
      isFavorite: !current.isFavorite,
    );
  }
}

// ViewModel for the Shop screen
class ShopViewModel extends BaseViewModel {
  late final ValueNotifier<List<ItemViewModel>> items = autoDispose(
    ValueNotifier([]),
  );

  late final ValueNotifier<double> cartTotal = autoDispose(ValueNotifier(0));

  ShopViewModel() {
    // Register to listen for ItemAddedToCartMessage messages
    ServiceLocator.messenger.register<ItemAddedToCartMessage>(
      this,
      _onItemAdded,
    );
  }

  void _onItemAdded(ItemAddedToCartMessage message) {
    cartTotal.value += message.item.price;
  }

  @override
  Future<void> init() async {
    // Simulate a network call to fetch shop items
    await Future<void>.delayed(const Duration(seconds: 2));
    items.value = List.generate(
      20,
      (i) => ItemViewModel(ItemData(i, 'Item ${i + 1}', (i + 1) * 2.5)),
    );
  }

  @override
  void dispose() {
    // Unregister from the messenger to prevent memory leaks
    ServiceLocator.messenger.unregisterAll(this);
    // Manually dispose of the child ViewModels
    for (final item in items.value) {
      item.dispose();
    }
    super.dispose();
  }
}

class ShopView extends StatefulWidget {
  const ShopView({super.key});

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  late final ShopViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = ShopViewModel();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Bind<bool>(
    notifier: vm.loadingNotifier,
    builder: (isLoading) {
      if (isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Bind<double>(
              notifier: vm.cartTotal,
              builder: (total) => Text(
                'Cart Total: \$${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          Expanded(
            child: Bind<List<ItemViewModel>>(
              notifier: vm.items,
              builder: (items) => ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final itemVm = items[index];
                  return ListTile(
                    title: Text(itemVm.itemDataNotifier.value.name),
                    subtitle: Text(
                      '\$${itemVm.itemDataNotifier.value.price.toStringAsFixed(2)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // This IconButton only rebuilds when isFavorite changes
                        BindSelector<ItemData, bool>(
                          notifier: itemVm.itemDataNotifier,
                          selector: (data) => data.isFavorite,
                          builder: (isFavorite) => IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                            ),
                            onPressed: () =>
                                itemVm.toggleFavoriteCommand.execute(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.green,
                          ),
                          onPressed: () => itemVm.addToCartCommand.execute(),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ItemDetailView(
                            itemData: itemVm.itemDataNotifier.value,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      );
    },
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ShopViewModel>('vm', vm));
  }
}
