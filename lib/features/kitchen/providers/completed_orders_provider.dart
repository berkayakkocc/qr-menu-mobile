import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/kitchen_order.dart';

final completedOrdersProvider = FutureProvider.autoDispose
    .family<List<KitchenOrder>, String>((ref, restaurantId) async {
  final data = await ApiService.get(
    '/restaurants/$restaurantId/orders?status=done',
  ) as List<dynamic>;
  return data
      .map((e) => KitchenOrder.fromJson(e as Map<String, dynamic>))
      .toList();
});
