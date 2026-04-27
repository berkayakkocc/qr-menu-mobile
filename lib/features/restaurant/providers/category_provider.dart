import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/category.dart';

class CategoriesNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final String menuId;

  CategoriesNotifier(this.menuId) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await ApiService.get('/menus/$menuId/categories') as List;
      state = AsyncValue.data(
        data.map((c) => Category.fromJson(c as Map<String, dynamic>)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(String name) async {
    try {
      await ApiService.post('/menus/$menuId/categories', {'name': name});
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rename(String categoryId, String newName) async {
    try {
      await ApiService.put('/categories/$categoryId', {'name': newName});
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String categoryId) async {
    try {
      await ApiService.delete('/categories/$categoryId');
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final categoriesProvider = StateNotifierProvider.autoDispose
    .family<CategoriesNotifier, AsyncValue<List<Category>>, String>(
  (ref, menuId) => CategoriesNotifier(menuId),
);
