import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/models/cart_line_model.dart';

class PosCartNotifier extends StateNotifier<List<CartLine>> {
  PosCartNotifier() : super([]);

  void add(CartLine item) {
    state = [...state, item];
  }

  void updateQuantity(int index, int qty) {
    if(qty <= 0) {
      removeAt(index);
      return;
    }
    final newState = [...state];
    newState[index].quantity = qty;
    state = newState;
  }

  void removeAt(int index) {
    final newState = [...state];
    newState.removeAt(index);
    state = newState;
  }

  void clear() {
    state = [];
  }

  double get subtotal => state.fold(0, (sum, item) => sum + item.lineSubtotal);
  double get discountTotal => state.fold(0, (sum, item) => sum + item.discount);
  double get vatTotal => state.fold(0, (sum, item) => sum + item.vatAmount);
  double get grandTotal => state.fold(0, (sum, item) => sum + item.lineTotalWithVat);
}

final posCartProvider = StateNotifierProvider<PosCartNotifier, List<CartLine>>((ref) {
  return PosCartNotifier();
});
