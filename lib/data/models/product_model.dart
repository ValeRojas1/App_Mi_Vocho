class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? category;
  final String? imageUrl;
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.category,
    this.imageUrl,
    this.isActive = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        price: (json['price'] as num).toDouble(),
        stock: json['stock'],
        category: json['category'],
        imageUrl: json['image_url'],
        isActive: json['is_active'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'category': category,
        'image_url': imageUrl,
        'is_active': isActive,
      };

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? category,
    String? imageUrl,
    bool? isActive,
    bool clearImageUrl = false,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      isActive: isActive ?? this.isActive,
    );
  }
}
