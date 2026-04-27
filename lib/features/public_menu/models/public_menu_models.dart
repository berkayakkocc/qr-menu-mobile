class PublicItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;

  const PublicItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
  });

  factory PublicItem.fromJson(Map<String, dynamic> j) => PublicItem(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        price: (j['price'] as num).toDouble(),
        imageUrl: j['image_url'] as String?,
      );
}

class PublicCategory {
  final String id;
  final String name;
  final List<PublicItem> items;

  const PublicCategory({required this.id, required this.name, required this.items});

  factory PublicCategory.fromJson(Map<String, dynamic> j) => PublicCategory(
        id: j['id'] as String,
        name: j['name'] as String,
        items: (j['items'] as List)
            .map((i) => PublicItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class PublicMenu {
  final String id;
  final String name;
  final List<PublicCategory> categories;

  const PublicMenu({required this.id, required this.name, required this.categories});

  factory PublicMenu.fromJson(Map<String, dynamic> j) => PublicMenu(
        id: j['id'] as String,
        name: j['name'] as String,
        categories: (j['categories'] as List)
            .map((c) => PublicCategory.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

class PublicRestaurant {
  final String id;
  final String name;
  final String? logoUrl;

  const PublicRestaurant({required this.id, required this.name, this.logoUrl});

  factory PublicRestaurant.fromJson(Map<String, dynamic> j) => PublicRestaurant(
        id: j['id'] as String,
        name: j['name'] as String,
        logoUrl: j['logo_url'] as String?,
      );
}

class PublicMenuData {
  final PublicRestaurant restaurant;
  final List<PublicMenu> menus;

  const PublicMenuData({required this.restaurant, required this.menus});

  factory PublicMenuData.fromJson(Map<String, dynamic> j) => PublicMenuData(
        restaurant: PublicRestaurant.fromJson(j['restaurant'] as Map<String, dynamic>),
        menus: (j['menus'] as List)
            .map((m) => PublicMenu.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}
