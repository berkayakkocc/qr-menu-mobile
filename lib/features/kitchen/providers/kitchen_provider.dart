import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/api_service.dart';
import '../models/kitchen_order.dart';

class KitchenNotifier
    extends StateNotifier<AsyncValue<List<KitchenOrder>>> {
  final String restaurantId;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  KitchenNotifier(this.restaurantId) : super(const AsyncValue.loading()) {
    load();
    _sub = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('restaurant_id', restaurantId)
        .listen((_) => load());
  }

  Future<void> load() async {
    try {
      final data = await ApiService.get(
        '/restaurants/$restaurantId/orders?status=pending&status=preparing&status=ready',
      ) as List<dynamic>;
      if (!mounted) return;
      state = AsyncValue.data(
        data
            .map((e) => KitchenOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> advance(String orderId, String currentStatus) async {
    const nextStatus = {
      'pending': 'preparing',
      'preparing': 'ready',
      'ready': 'done',
    };
    final next = nextStatus[currentStatus];
    if (next == null) return;
    await ApiService.patch('/orders/$orderId/status', {'status': next});
    await load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final kitchenProvider = StateNotifierProvider.autoDispose
    .family<KitchenNotifier, AsyncValue<List<KitchenOrder>>, String>(
  (ref, restaurantId) => KitchenNotifier(restaurantId),
);
