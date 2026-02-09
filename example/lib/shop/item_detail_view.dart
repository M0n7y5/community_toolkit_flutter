import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'shop_view.dart';

class ItemDetailView extends StatelessWidget {
  const ItemDetailView({required this.itemData, super.key});
  final ItemData itemData;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(itemData.name)),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Item Details',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'ID: ${itemData.id}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Price: \$${itemData.price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Icon(
            itemData.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: itemData.isFavorite ? Colors.red : Colors.grey,
            size: 48,
          ),
        ],
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ItemData>('itemData', itemData));
  }
}
