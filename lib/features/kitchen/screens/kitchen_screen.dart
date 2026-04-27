import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../restaurant/providers/restaurant_provider.dart';
import '../models/kitchen_order.dart';
import '../providers/completed_orders_provider.dart';
import '../providers/kitchen_provider.dart';

class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantProvider);
    return restaurantAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (r) => _KitchenBody(restaurantId: r.id),
    );
  }
}

class _KitchenBody extends ConsumerWidget {
  final String restaurantId;
  const _KitchenBody({required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mutfak Ekranı'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aktif Siparişler'),
              Tab(text: 'Geçmiş'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ActiveOrdersTab(restaurantId: restaurantId),
            _CompletedOrdersTab(restaurantId: restaurantId),
          ],
        ),
      ),
    );
  }
}

class _ActiveOrdersTab extends ConsumerWidget {
  final String restaurantId;
  const _ActiveOrdersTab({required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(kitchenProvider(restaurantId));
    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (orders) {
        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restaurant, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Aktif sipariş yok', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(kitchenProvider(restaurantId).notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (_, i) => _OrderCard(
              order: orders[i],
              onAdvance: () =>
                  ref.read(kitchenProvider(restaurantId).notifier).advance(orders[i].id),
            ),
          ),
        );
      },
    );
  }
}

class _CompletedOrdersTab extends ConsumerWidget {
  final String restaurantId;
  const _CompletedOrdersTab({required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(completedOrdersProvider(restaurantId));
    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (orders) {
        if (orders.isEmpty) {
          return const Center(
            child: Text('Tamamlanan sipariş yok', style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          itemBuilder: (_, i) => _OrderCard(order: orders[i]),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final KitchenOrder order;
  final VoidCallback? onAdvance;

  const _OrderCard({required this.order, this.onAdvance});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusChip(status: order.status),
                const Spacer(),
                if (order.tableNo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.table_restaurant,
                            size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(
                          order.tableNo!,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '#${order.shortId}',
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey, fontFamily: 'monospace'),
            ),
            const Divider(height: 20),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                              fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.itemName)),
                    if (item.note != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          item.note!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange[700], fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (onAdvance != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAdvance,
                  style: FilledButton.styleFrom(
                    backgroundColor: _nextButtonColor(order.status),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(_nextButtonLabel(order.status)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _nextButtonLabel(String status) {
    return switch (status) {
      'pending' => 'Hazırlamaya Başla',
      'preparing' => 'Hazır',
      'ready' => 'Teslim Edildi',
      _ => 'İlerle',
    };
  }

  Color _nextButtonColor(String status) {
    return switch (status) {
      'pending' => const Color(0xFFF59E0B),
      'preparing' => const Color(0xFF10B981),
      'ready' => const Color(0xFF6366F1),
      _ => const Color(0xFF2563EB),
    };
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('Bekliyor', const Color(0xFFF59E0B)),
      'preparing' => ('Hazırlanıyor', const Color(0xFF3B82F6)),
      'ready' => ('Hazır', const Color(0xFF10B981)),
      'done' => ('Teslim Edildi', Colors.grey),
      _ => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
