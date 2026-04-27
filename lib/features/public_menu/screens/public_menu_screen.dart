import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/public_menu_models.dart';
import '../providers/cart_provider.dart';
import '../providers/public_menu_provider.dart';

class PublicMenuScreen extends ConsumerWidget {
  final String slug;
  const PublicMenuScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(publicMenuProvider(slug));

    return menuAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Menü yükleniyor...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('$e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(publicMenuProvider(slug)),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      ),
      data: (data) => _MenuContent(slug: slug, data: data),
    );
  }
}

class _MenuContent extends ConsumerWidget {
  final String slug;
  final PublicMenuData data;
  const _MenuContent({required this.slug, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menus = data.menus;

    if (menus.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(data.restaurant.name)),
        body: const Center(child: Text('Aktif menü bulunamadı.')),
      );
    }

    if (menus.length == 1) {
      return _SingleMenuScaffold(slug: slug, restaurant: data.restaurant, menu: menus.first);
    }

    return DefaultTabController(
      length: menus.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(data.restaurant.name),
          bottom: TabBar(
            isScrollable: true,
            tabs: menus.map((m) => Tab(text: m.name)).toList(),
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: menus.map((m) => _CategoriesList(categories: m.categories, slug: slug)).toList(),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _CartBar(slug: slug),
            ),
          ],
        ),
      ),
    );
  }
}

class _SingleMenuScaffold extends StatelessWidget {
  final String slug;
  final PublicRestaurant restaurant;
  final PublicMenu menu;
  const _SingleMenuScaffold({required this.slug, required this.restaurant, required this.menu});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(restaurant.name)),
      body: Stack(
        children: [
          _CategoriesList(categories: menu.categories, slug: slug),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _CartBar(slug: slug),
          ),
        ],
      ),
    );
  }
}

class _CategoriesList extends StatelessWidget {
  final List<PublicCategory> categories;
  final String slug;
  const _CategoriesList({required this.categories, required this.slug});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: categories.length,
      itemBuilder: (_, i) => _CategorySection(category: categories[i]),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final PublicCategory category;
  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    if (category.items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            category.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ...category.items.map((item) => _ItemCard(item: item)),
      ],
    );
  }
}

class _ItemCard extends ConsumerWidget {
  final PublicItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(
      cartProvider.select((cart) => cart
          .firstWhere((i) => i.itemId == item.id,
              orElse: () => const CartItem(itemId: '', name: '', price: 0, quantity: 0))
          .quantity),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl != null
                ? Image.network(
                    item.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _itemPlaceholder(),
                  )
                : _itemPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                if (item.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '₺${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF2563EB)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _QtyControl(item: item, qty: qty),
        ],
      ),
    );
  }
}

Widget _itemPlaceholder() => Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fastfood_outlined, color: Color(0xFF2563EB), size: 32),
    );

class _QtyControl extends ConsumerWidget {
  final PublicItem item;
  final int qty;
  const _QtyControl({required this.item, required this.qty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (qty == 0) {
      return FilledButton.tonal(
        style: FilledButton.styleFrom(
          minimumSize: const Size(40, 40),
          padding: EdgeInsets.zero,
        ),
        onPressed: () => ref.read(cartProvider.notifier).add(item.id, item.name, item.price),
        child: const Icon(Icons.add, size: 20),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleBtn(
          icon: Icons.remove,
          onTap: () => ref.read(cartProvider.notifier).remove(item.id),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('$qty',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        _CircleBtn(
          icon: Icons.add,
          onTap: () => ref.read(cartProvider.notifier).add(item.id, item.name, item.price),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2563EB)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
      ),
    );
  }
}

class _CartBar extends ConsumerWidget {
  final String slug;
  const _CartBar({required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) return const SizedBox.shrink();

    final count = cart.fold(0, (sum, i) => sum + i.quantity);
    final total = cart.fold(0.0, (sum, i) => sum + i.price * i.quantity);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: () => context.push('/menu/$slug/confirm'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          '$count ürün · ₺${total.toStringAsFixed(2)}  |  Sipariş Ver',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
