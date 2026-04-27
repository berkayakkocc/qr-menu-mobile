class Menu {
  final String id;
  final String name;
  final bool isActive;

  const Menu({required this.id, required this.name, required this.isActive});

  factory Menu.fromJson(Map<String, dynamic> j) => Menu(
        id: j['id'] as String,
        name: j['name'] as String,
        isActive: j['is_active'] as bool? ?? false,
      );
}
