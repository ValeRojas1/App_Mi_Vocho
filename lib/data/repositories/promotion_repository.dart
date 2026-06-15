import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/promotion_model.dart';

class PromotionSetupRequiredException implements Exception {
  const PromotionSetupRequiredException();

  @override
  String toString() =>
      'Falta aplicar la migración de ofertas y noticias en Supabase.';
}

class PromotionRepository {
  static const String _bucket = 'promotion-images';

  final _client = Supabase.instance.client;

  Future<List<PromotionModel>> getActivePromotions() async {
    try {
      final response = await _client
          .from('promotions')
          .select()
          .eq('is_active', true)
          .order('position')
          .limit(3);
      return (response as List)
          .map((e) => PromotionModel.fromJson(e))
          .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<PromotionModel>> getOwnerPromotions() async {
    try {
      final response = await _client
          .from('promotions')
          .select()
          .order('position');
      return (response as List).map((e) => PromotionModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      if (_isMissingPromotionsTable(e)) {
        throw const PromotionSetupRequiredException();
      }
      rethrow;
    }
  }

  Future<void> updatePromotion({
    required String id,
    required String title,
    required bool isActive,
    String? imageUrl,
  }) async {
    await _client
        .from('promotions')
        .update({
          'title': title,
          'is_active': isActive,
          'image_url': imageUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<String> uploadPromotionImage({
    required int position,
    required Uint8List bytes,
    String fileExtension = 'jpg',
  }) async {
    final ext = fileExtension.replaceAll('.', '').toLowerCase();
    final contentType = _contentTypeFor(ext);
    final path = 'slot_$position/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final storage = _client.storage.from(_bucket);

    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );

    return storage.getPublicUrl(path);
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  bool _isMissingPromotionsTable(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == 'PGRST205' ||
        e.code == '42P01' ||
        (message.contains('promotions') &&
            (message.contains('schema cache') ||
                message.contains('could not find') ||
                message.contains('does not exist')));
  }
}
