import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/restaurant.dart';

final restaurantProvider = FutureProvider<Restaurant>((ref) async {
  final data = await ApiService.get('/auth/me') as Map<String, dynamic>;
  final r = data['restaurant'];
  if (r == null) throw Exception('Restoran bulunamadı');
  return Restaurant.fromJson(r as Map<String, dynamic>);
});
