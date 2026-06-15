import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class ProductRepository {
  static const String _bucket = 'product-images';

  /// Umbral a partir del cual un repuesto se considera con stock bajo
  /// (se usa tanto en el dashboard como en la lista de inventario).
  static const int lowStockThreshold = 3;

  final _client = Supabase.instance.client;

  Future<List<ProductModel>> searchProducts(String query) async {
    final response = await _client
        .from('products')
        .select()
        .eq('is_active', true)
        .ilike('name', '%$query%')
        .order('name');
    return (response as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<List<ProductModel>> getAllProducts() async {
    final response = await _client
        .from('products')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  /// Stock y precio actuales de los productos del carrito.
  Future<List<ProductModel>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final response = await _client
        .from('products')
        .select()
        .inFilter('id', ids);
    return (response as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<ProductModel> upsertProduct(ProductModel product) async {
    final response = await _client
        .from('products')
        .upsert(product.toJson())
        .select()
        .single();
    return ProductModel.fromJson(response);
  }

  Future<void> updateStock(String productId, int newStock) async {
    await _client
        .from('products')
        .update({'stock': newStock})
        .eq('id', productId);
  }

  Future<void> setProductActive(String productId, bool isActive) async {
    await _client
        .from('products')
        .update({'is_active': isActive})
        .eq('id', productId);
  }

  /// Devuelve estadísticas para el dashboard de la dueña:
  /// - activeCount: repuestos con is_active = true.
  /// - lowStockCount: repuestos activos con stock <= [lowStockThreshold].
  Future<({int activeCount, int lowStockCount})> getInventoryStats() async {
    final activeRes = await _client
        .from('products')
        .select('id')
        .eq('is_active', true)
        .count(CountOption.exact);

    final lowStockRes = await _client
        .from('products')
        .select('id')
        .eq('is_active', true)
        .lte('stock', lowStockThreshold)
        .count(CountOption.exact);

    return (activeCount: activeRes.count, lowStockCount: lowStockRes.count);
  }

  Future<void> updateImageUrl(String productId, String? imageUrl) async {
    await _client
        .from('products')
        .update({'image_url': imageUrl})
        .eq('id', productId);
  }

  /// Sube una imagen al bucket de Supabase Storage y devuelve la URL pública.
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    String fileExtension = 'jpg',
  }) async {
    final ext = fileExtension.replaceAll('.', '').toLowerCase();
    final contentType = _contentTypeFor(ext);
    final path = '$productId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    final storage = _client.storage.from(_bucket);
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );

    return storage.getPublicUrl(path);
  }

  /// Borra una imagen del bucket a partir de su URL pública.
  Future<void> deleteImageByUrl(String imageUrl) async {
    const marker = '/object/public/$_bucket/';
    final idx = imageUrl.indexOf(marker);
    if (idx == -1) return;
    final path = imageUrl.substring(idx + marker.length);
    if (path.isEmpty) return;
    try {
      await _client.storage.from(_bucket).remove([path]);
    } catch (_) {
      // Ignorar errores al borrar (p. ej. archivo ya inexistente)
    }
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
