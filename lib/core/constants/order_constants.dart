import 'package:flutter/material.dart';

/// Estados del ciclo de vida de un pedido.
enum OrderStatus {
  pending('pending'),
  confirmed('confirmed'),
  ready('ready'),
  shipped('shipped'),
  completed('completed');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus? fromValue(String? v) {
    if (v == null) return null;
    for (final s in OrderStatus.values) {
      if (s.value == v) return s;
    }
    return null;
  }

  String get clientLabel => switch (this) {
    OrderStatus.pending => 'Pendiente de aprobación',
    OrderStatus.confirmed => 'Pedido confirmado',
    OrderStatus.ready => 'Listo para recojo',
    OrderStatus.shipped => 'En camino por encomienda',
    OrderStatus.completed => 'Pedido entregado',
  };

  String get ownerLabel => switch (this) {
    OrderStatus.pending => 'Pendiente',
    OrderStatus.confirmed => 'Confirmado',
    OrderStatus.ready => 'Listo',
    OrderStatus.shipped => 'Enviado',
    OrderStatus.completed => 'Completado',
  };

  IconData get icon => switch (this) {
    OrderStatus.pending => Icons.pending_actions,
    OrderStatus.confirmed => Icons.check_circle_outline,
    OrderStatus.ready => Icons.inventory_2_outlined,
    OrderStatus.shipped => Icons.local_shipping_outlined,
    OrderStatus.completed => Icons.done_all_outlined,
  };

  Color get color => switch (this) {
    OrderStatus.pending => Colors.orange,
    OrderStatus.confirmed => const Color(0xFF1976D2),
    OrderStatus.ready => Colors.teal,
    OrderStatus.shipped => const Color(0xFF7B1FA2),
    OrderStatus.completed => Colors.green,
  };
}

enum PickupType {
  local('local'),
  interprovincial('interprovincial');

  const PickupType(this.value);
  final String value;

  static PickupType fromValue(String? v) => v == interprovincial.value
      ? PickupType.interprovincial
      : PickupType.local;

  String get label => switch (this) {
    PickupType.local => 'Recojo en tienda',
    PickupType.interprovincial => 'Envío interprovincial',
  };

  IconData get icon => switch (this) {
    PickupType.local => Icons.storefront_outlined,
    PickupType.interprovincial => Icons.local_shipping_outlined,
  };
}

enum AppRole {
  client('client'),
  owner('owner'),
  admin('admin');

  const AppRole(this.value);
  final String value;

  static AppRole fromValue(String? v) {
    for (final role in AppRole.values) {
      if (role.value == v) return role;
    }
    return AppRole.client;
  }

  String get label => switch (this) {
    AppRole.client => 'Cliente',
    AppRole.owner => 'Dueña',
    AppRole.admin => 'Administrador',
  };
}

/// Email legado de la dueña (fallback si aún no existe fila en profiles).
const kLegacyOwnerEmail = 'duena@lavolkswagen.com';

enum PaymentMethod {
  card('card'),
  yape('yape'),
  plin('plin'),
  inStore('in_store');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod fromValue(String? v) {
    for (final m in PaymentMethod.values) {
      if (m.value == v) return m;
    }
    return PaymentMethod.card;
  }

  String get label => switch (this) {
    PaymentMethod.card => 'Tarjeta',
    PaymentMethod.yape => 'Yape',
    PaymentMethod.plin => 'Plin',
    PaymentMethod.inStore => 'Pago en tienda',
  };

  IconData get icon => switch (this) {
    PaymentMethod.card => Icons.credit_card,
    PaymentMethod.yape => Icons.account_balance_wallet_outlined,
    PaymentMethod.plin => Icons.phone_android_outlined,
    PaymentMethod.inStore => Icons.storefront_outlined,
  };

  bool get requiresCardForm => this == PaymentMethod.card;
}
