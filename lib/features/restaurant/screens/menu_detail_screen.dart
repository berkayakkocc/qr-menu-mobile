import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/category.dart';
import '../models/item.dart';
import '../providers/category_provider.dart';
import '../providers/item_provider.dart';

class MenuDetailScreen extends ConsumerWidget {
  final String menuId;
  final String? menuName;

  const MenuDetailScreen({super.key, required this.menuId, this.menuName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider(menuId));

    return Scaffold(
      appBar: AppBar(
        title: Text(menuName ?? 'Menü'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Kategori Ekle'),
        onPressed: () => _showAddCategoryDialog(context, ref),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(categoriesProvider(menuId).notifier).load(),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
        data: (categories) => categories.isEmpty
            ? const Center(
                child: Text(
                  'Henüz kategori yok.\nKategori eklemek için butona bas.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _CategorySection(
                  category: categories[i],
                  menuId: menuId,
                ),
              ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Kategori'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Kategori adı',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitCategory(ctx, ctrl, ref),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () => _submitCategory(ctx, ctrl, ref),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _submitCategory(BuildContext ctx, TextEditingController ctrl, WidgetRef ref) {
    if (ctrl.text.trim().isNotEmpty) {
      ref.read(categoriesProvider(menuId).notifier).add(ctrl.text.trim());
      Navigator.pop(ctx);
    }
  }
}

class _CategorySection extends ConsumerWidget {
  final Category category;
  final String menuId;
  const _CategorySection({required this.category, required this.menuId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider(category.id));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Category header
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showRenameDialog(context, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Items
          itemsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('$e', style: const TextStyle(color: Colors.red)),
            ),
            data: (items) => Column(
              children: [
                ...items.map((item) => _ItemTile(
                      item: item,
                      categoryId: category.id,
                    )),
                ListTile(
                  leading: const Icon(Icons.add, color: Color(0xFF2563EB)),
                  title: const Text(
                    'Ürün ekle',
                    style: TextStyle(color: Color(0xFF2563EB)),
                  ),
                  onTap: () async {
                    await context.push(
                      '/items/new?categoryId=${category.id}',
                    );
                    if (context.mounted) {
                      ref.read(itemsProvider(category.id).notifier).load();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategoriyi Düzenle'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Kategori adı',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitRename(ctx, ctrl, ref),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () => _submitRename(ctx, ctrl, ref),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _submitRename(BuildContext ctx, TextEditingController ctrl, WidgetRef ref) {
    if (ctrl.text.trim().isNotEmpty && ctrl.text.trim() != category.name) {
      ref.read(categoriesProvider(menuId).notifier).rename(category.id, ctrl.text.trim());
    }
    Navigator.pop(ctx);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text('"${category.name}" kategorisini ve tüm ürünlerini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(categoriesProvider(menuId).notifier).delete(category.id);
              Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends ConsumerWidget {
  final Item item;
  final String categoryId;
  const _ItemTile({required this.item, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text(
        '₺${item.price.toStringAsFixed(2)}${item.description != null ? ' · ${item.description}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: item.isAvailable,
            onChanged: (_) =>
                ref.read(itemsProvider(categoryId).notifier).toggleAvailable(item),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () async {
              await context.push(
                '/items/${item.id}/edit?categoryId=$categoryId',
              );
              if (context.mounted) {
                ref.read(itemsProvider(categoryId).notifier).load();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text('"${item.name}" ürününü silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(itemsProvider(categoryId).notifier).delete(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
