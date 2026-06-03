import 'package:supabase_flutter/supabase_flutter.dart';

class AppErrors {
  static String message(Object error) {
    if (error is PostgrestException) {
      final code = error.code ?? '';
      final msg = error.message.toLowerCase();
      if (code == 'P0001' || msg.contains('insufficient_stock')) {
        return 'No hay stock suficiente para uno o más repuestos.';
      }
      if (msg.contains('product_not_found') || msg.contains('inactive')) {
        return 'Uno de los repuestos ya no está disponible.';
      }
      if (msg.contains('create_order_with_stock')) {
        return 'No se pudo registrar el pedido. Verifica el inventario.';
      }
      return error.message;
    }
    final text = error.toString();
    if (text.contains('insufficient_stock')) {
      return 'No hay stock suficiente para completar el pedido.';
    }
    if (text.contains('SocketException') || text.contains('Failed host')) {
      return 'Sin conexión. Revisa tu internet e intenta de nuevo.';
    }
    return 'Ocurrió un error. Intenta nuevamente.';
  }
}
