import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../providers/restaurant_provider.dart';

final _qrBytesProvider = FutureProvider.autoDispose.family<Uint8List, String>(
  (ref, restaurantId) => ApiService.getBytes('/qr/$restaurantId/generate'),
);

class QRDisplayScreen extends ConsumerWidget {
  const QRDisplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('QR Kod')),
      body: restaurantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (restaurant) => _QRBody(restaurantId: restaurant.id, slug: restaurant.slug),
      ),
    );
  }
}

class _QRBody extends ConsumerWidget {
  final String restaurantId;
  final String slug;
  const _QRBody({required this.restaurantId, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrAsync = ref.watch(_qrBytesProvider(restaurantId));

    return Center(
      child: qrAsync.when(
        loading: () => const CircularProgressIndicator(),
        error: (e, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('$e', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(_qrBytesProvider(restaurantId)),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
        data: (bytes) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Müşterileriniz bu kodu okutarak menünüze erişebilir.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(bytes, width: 280, height: 280),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '/$slug',
                  style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
