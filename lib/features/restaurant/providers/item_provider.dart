import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/item.dart';

class ItemsNotifier extends StateNotifier<AsyncValue<List<Item>>> {
  final String categoryId;

  ItemsNotifier(this.categoryId) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await ApiService.get('/categories/$categoryId/items') as List;
      state = AsyncValue.data(
        data.map((i) => Item.fromJson(i as Map<String, dynamic>)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleAvailable(Item item) async {
    try {
      await ApiService.put('/items/${item.id}', {'is_available': !item.isAvailable});
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String itemId) async {
    try {
      await ApiService.delete('/items/$itemId');
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final itemsProvider = StateNotifierProvider.autoDispose
    .family<ItemsNotifier, AsyncValue<List<Item>>, String>(
  (ref, categoryId) => ItemsNotifier(categoryId),
);
