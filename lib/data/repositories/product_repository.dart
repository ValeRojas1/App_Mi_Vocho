import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class ProductRepository {
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

  Future<void> upsertProduct(ProductModel product) async {
    await _client.from('products').upsert(product.toJson());
  }

  Future<void> updateStock(String productId, int newStock) async {
    await _client
        .from('products')
        .update({'stock': newStock})
        .eq('id', productId);
  }
}