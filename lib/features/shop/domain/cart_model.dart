import 'product_model.dart';

class CartItem {
  final ProductModel product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  int get subtotal => product.price * quantity;

  String get formattedSubtotal {
    final formatted = subtotal.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}

class CartModel {
  final List<CartItem> items;

  const CartModel({this.items = const []});

  int get totalPrice => items.fold(0, (sum, item) => sum + item.subtotal);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  CartModel addItem(ProductModel product) {
    final index = items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      final updated = List<CartItem>.from(items);
      updated[index] = items[index].copyWith(quantity: items[index].quantity + 1);
      return CartModel(items: updated);
    }
    return CartModel(items: [...items, CartItem(product: product, quantity: 1)]);
  }

  CartModel removeItem(String productId) {
    return CartModel(items: items.where((i) => i.product.id != productId).toList());
  }

  CartModel updateQuantity(String productId, int quantity) {
    if (quantity <= 0) return removeItem(productId);
    final updated = items.map((i) {
      return i.product.id == productId ? i.copyWith(quantity: quantity) : i;
    }).toList();
    return CartModel(items: updated);
  }

  CartModel clear() => const CartModel();

  String get formattedTotal {
    final formatted = totalPrice.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }
}