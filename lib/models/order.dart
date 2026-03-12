class OrderItem {
  final int? id;
  final int? productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;

  const OrderItem({
    this.id,
    this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
  });

  double get totalPrice => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int?,
      productId: json['productId'] as int?,
      productName: json['productName'] as String? ?? '',
      productImage: json['productImage'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'productImage': productImage,
        'price': price,
        'quantity': quantity,
      };
}

class Order {
  final int? id;
  final String username;
  final double totalAmount;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final List<OrderItem> items;

  const Order({
    this.id,
    required this.username,
    required this.totalAmount,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return Order(
      id: json['id'] as int?,
      username: json['username'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      items: itemsList
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get formattedDate {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt!);
      return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
    } catch (_) {
      return createdAt!;
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
