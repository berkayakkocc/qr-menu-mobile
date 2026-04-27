class Category {
  final String id;
  final String name;
  final int sortOrder;

  const Category({required this.id, required this.name, required this.sortOrder});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        sortOrder: j['sort_order'] as int? ?? 0,
      );
}
