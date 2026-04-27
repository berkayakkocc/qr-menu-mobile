import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../restaurant/models/menu.dart';
import '../../restaurant/models/restaurant.dart';
import '../../restaurant/providers/menu_provider.dart';
import '../../restaurant/providers/restaurant_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Menü'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'QR Kodu Göster',
            onPressed: () => context.push('/qr'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: restaurantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (restaurant) => _DashboardBody(restaurant: restaurant),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final Restaurant restaurant;
  const _DashboardBody({required this.restaurant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusAsync = ref.watch(menusProvider(restaurant.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RestaurantCard(restaurant: restaurant),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                'Menüler',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Yeni Menü'),
                onPressed: () => _showAddDialog(context, ref),
              ),
            ],
          ),
        ),
        Expanded(
          child: menusAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$e'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.read(menusProvider(restaurant.id).notifier).load(),
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
            data: (menus) => menus.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz menü yok.\nYeni menü eklemek için butona bas.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: menus.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _MenuCard(
                      menu: menus[i],
                      restaurantId: restaurant.id,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Menü'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Menü adı',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(ctx, ctrl, ref),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () => _submit(ctx, ctrl, ref),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext ctx, TextEditingController ctrl, WidgetRef ref) {
    if (ctrl.text.trim().isNotEmpty) {
      ref.read(menusProvider(restaurant.id).notifier).add(ctrl.text.trim());
      Navigator.pop(ctx);
    }
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '/${restaurant.slug}',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends ConsumerWidget {
  final Menu menu;
  final String restaurantId;
  const _MenuCard({required this.menu, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.menu_book,
          color: menu.isActive ? const Color(0xFF2563EB) : Colors.grey,
        ),
        title: Text(menu.name),
        subtitle: Text(
          menu.isActive ? 'Aktif' : 'Pasif',
          style: TextStyle(
            color: menu.isActive ? Colors.green[700] : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: menu.isActive,
              onChanged: (_) =>
                  ref.read(menusProvider(restaurantId).notifier).toggleActive(menu),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
        onTap: () => context.push('/menus/${menu.id}', extra: menu.name),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Menüyü Sil'),
        content: Text(
          '"${menu.name}" menüsünü ve tüm kategorileri ile ürünleri silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(menusProvider(restaurantId).notifier).delete(menu.id);
              Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
