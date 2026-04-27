import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../models/public_menu_models.dart';

final publicMenuProvider =
    FutureProvider.autoDispose.family<PublicMenuData, String>((ref, slug) async {
  final data = await ApiService.get('/public/$slug/menu') as Map<String, dynamic>;
  return PublicMenuData.fromJson(data);
});
