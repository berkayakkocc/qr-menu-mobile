class Restaurant {
  final String id;
  final String slug;
  final String name;
  final String? logoUrl;

  const Restaurant({
    required this.id,
    required this.slug,
    required this.name,
    this.logoUrl,
  });

  factory Restaurant.fromJson(Map<String, dynamic> j) => Restaurant(
        id: j['id'] as String,
        slug: j['slug'] as String,
        name: j['name'] as String,
        logoUrl: j['logo_url'] as String?,
      );
}
