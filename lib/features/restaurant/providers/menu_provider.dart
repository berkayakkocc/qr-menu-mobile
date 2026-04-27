import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/menu.dart';

class MenusNotifier extends StateNotifier<AsyncValue<List<Menu>>> {
  final String restaurantId;

  MenusNotifier(this.restaurantId) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final data = await ApiService.get('/restaurants/$restaurantId/menus') as List;
      state = AsyncValue.data(
        data.map((m) => Menu.fromJson(m as Map<String, dynamic>)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(String name) async {
    try {
      await ApiService.post('/restaurants/$restaurantId/menus', {'name': name});
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> rename(Menu menu, String newName) async {
    try {
      await ApiService.put('/menus/${menu.id}', {'name': newName});
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleActive(Menu menu) async {
    try {
      await ApiService.put('/menus/${menu.id}', {'is_active': !menu.isActive});
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String menuId) async {
    try {
      await ApiService.delete('/menus/$menuId');
      await load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final menusProvider = StateNotifierProvider.autoDispose
    .family<MenusNotifier, AsyncValue<List<Menu>>, String>(
  (ref, restaurantId) => MenusNotifier(restaurantId),
);
