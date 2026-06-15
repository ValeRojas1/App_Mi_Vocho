class PromotionModel {
  final String id;
  final int position;
  final String title;
  final String? imageUrl;
  final bool isActive;

  const PromotionModel({
    required this.id,
    required this.position,
    required this.title,
    this.imageUrl,
    required this.isActive,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) => PromotionModel(
    id: json['id'] as String,
    position: json['position'] as int? ?? 0,
    title: json['title'] as String? ?? 'Oferta',
    imageUrl: json['image_url'] as String?,
    isActive: json['is_active'] as bool? ?? true,
  );
}
