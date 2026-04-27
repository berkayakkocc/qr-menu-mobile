class Item {
  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final int sortOrder;

  const Item({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.sortOrder,
  });

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] as String,
        categoryId: j['category_id'] as String?,
        name: j['name'] as String,
        description: j['description'] as String?,
        price: (j['price'] as num).toDouble(),
        imageUrl: j['image_url'] as String?,
        isAvailable: j['is_available'] as bool? ?? true,
        sortOrder: j['sort_order'] as int? ?? 0,
      );
}
