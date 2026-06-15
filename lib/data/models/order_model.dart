import 'product_model.dart';

class OrderModel {
  final String id;
  final String? clientId;
  final String status;
  final String pickupType;
  final double? total;
  final String? paymentMethod;
  final String? shippingAgency;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    this.clientId,
    required this.status,
    required this.pickupType,
    this.total,
    this.paymentMethod,
    this.shippingAgency,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['id'],
    clientId: json['client_id'],
    status: json['status'] ?? 'pending',
    pickupType: json['pickup_type'] ?? 'local',
    total: json['total'] != null ? (json['total'] as num).toDouble() : null,
    paymentMethod: json['payment_method'] as String?,
    shippingAgency: json['shipping_agency'] as String?,
    createdAt: DateTime.parse(json['created_at']),
    items: (json['order_items'] as List<dynamic>? ?? [])
        .map((e) => OrderItemModel.fromJson(e))
        .toList(),
  );
}

class OrderItemModel {
  final String id;
  final String productId;
  final int quantity;
  final double unitPrice;
  final ProductModel? product; // join opcional

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.product,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
    id: json['id'],
    productId: json['product_id'],
    quantity: json['quantity'],
    unitPrice: (json['unit_price'] as num).toDouble(),
    product: json['products'] != null
        ? ProductModel.fromJson(json['products'])
        : null,
  );
}
