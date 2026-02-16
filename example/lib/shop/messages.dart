import 'package:flutter/foundation.dart';

import 'shop_view.dart';

/// Message sent via [Messenger] when an item is added to the cart.
@immutable
class ItemAddedToCartMessage {
  const ItemAddedToCartMessage(this.item);
  final ItemData item;
}
