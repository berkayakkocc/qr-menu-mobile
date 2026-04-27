class KitchenOrderItem {
  final String id;
  final int quantity;
  final String? note;
  final String itemName;
  final double itemPrice;

  const KitchenOrderItem({
    required this.id,
    required this.quantity,
    this.note,
    required this.itemName,
    required this.itemPrice,
  });

  factory KitchenOrderItem.fromJson(Map<String, dynamic> j) {
    final item = j['items'] as Map<String, dynamic>;
    return KitchenOrderItem(
      id: j['id'] as String,
      quantity: j['quantity'] as int,
      note: j['note'] as String?,
      itemName: item['name'] as String,
      itemPrice: (item['price'] as num).toDouble(),
    );
  }
}

class KitchenOrder {
  final String id;
  final String status;
  final String? tableNo;
  final DateTime createdAt;
  final List<KitchenOrderItem> items;

  const KitchenOrder({
    required this.id,
    required this.status,
    this.tableNo,
    required this.createdAt,
    required this.items,
  });

  factory KitchenOrder.fromJson(Map<String, dynamic> j) {
    return KitchenOrder(
      id: j['id'] as String,
      status: j['status'] as String,
      tableNo: j['table_no'] as String?,
      createdAt: DateTime.parse(j['created_at'] as String),
      items: (j['order_items'] as List<dynamic>)
          .map((e) => KitchenOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get shortId => id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
}
