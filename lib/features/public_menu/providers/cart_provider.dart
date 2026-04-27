import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final String itemId;
  final String name;
  final double price;
  final int quantity;

  const CartItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  CartItem copyWith({int? quantity}) => CartItem(
        itemId: itemId,
        name: name,
        price: price,
        quantity: quantity ?? this.quantity,
      );
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void add(String itemId, String name, double price) {
    final idx = state.indexWhere((i) => i.itemId == itemId);
    if (idx >= 0) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == idx) state[i].copyWith(quantity: state[i].quantity + 1) else state[i],
      ];
    } else {
      state = [...state, CartItem(itemId: itemId, name: name, price: price, quantity: 1)];
    }
  }

  void remove(String itemId) {
    final idx = state.indexWhere((i) => i.itemId == itemId);
    if (idx < 0) return;
    if (state[idx].quantity > 1) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == idx) state[i].copyWith(quantity: state[i].quantity - 1) else state[i],
      ];
    } else {
      state = state.where((i) => i.itemId != itemId).toList();
    }
  }

  void clear() => state = [];

  int quantityOf(String itemId) =>
      state.firstWhere((i) => i.itemId == itemId, orElse: () => const CartItem(itemId: '', name: '', price: 0, quantity: 0)).quantity;

  double get total => state.fold(0.0, (sum, i) => sum + i.price * i.quantity);
  int get itemCount => state.fold(0, (sum, i) => sum + i.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (_) => CartNotifier(),
);
