import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/order_constants.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../data/repositories/order_repository.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final double total;
  final VoidCallback onOrderSuccess;

  const CheckoutScreen({
    super.key,
    required this.cart,
    required this.total,
    required this.onOrderSuccess,
  });
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _customShippingAgency = 'Otra agencia';
  static const _shippingAgencies = [
    'Shalom',
    'Cargo 1',
    'Olva',
    'Serpost',
    _customShippingAgency,
  ];

  final _repo = OrderRepository();
  final _formKey = GlobalKey<FormState>();

  // Datos de pago
  final _cardNumber = TextEditingController();
  final _cardHolder = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  String _pickupType = PickupType.local.value;
  PaymentMethod _paymentMethod = PaymentMethod.card;
  String _shippingAgency = _shippingAgencies.first;
  final _paymentRefCtrl = TextEditingController();
  final _customAgencyCtrl = TextEditingController();
  bool _processing = false;

  bool get _isInterprovincial =>
      _pickupType == PickupType.interprovincial.value;

  String? get _selectedShippingAgency {
    if (!_isInterprovincial) return null;
    if (_shippingAgency != _customShippingAgency) return _shippingAgency;
    final custom = _customAgencyCtrl.text.trim();
    return custom.isEmpty ? null : custom;
  }

  List<PaymentMethod> get _availablePaymentMethods => _isInterprovincial
      ? PaymentMethod.values.where((m) => m != PaymentMethod.inStore).toList()
      : PaymentMethod.values;

  @override
  void dispose() {
    _cardNumber.dispose();
    _cardHolder.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _paymentRefCtrl.dispose();
    _customAgencyCtrl.dispose();
    super.dispose();
  }

  void _selectPickupType(String value) {
    setState(() {
      _pickupType = value;
      if (_isInterprovincial && _paymentMethod == PaymentMethod.inStore) {
        _paymentMethod = PaymentMethod.card;
      }
    });
  }

  // Simula procesamiento de pago (en producción usar Culqi SDK)
  Future<void> _processPayment() async {
    if (_isInterprovincial && _selectedShippingAgency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona o ingresa una agencia de envío.'),
        ),
      );
      return;
    }

    if (_paymentMethod.requiresCardForm) {
      if (!_formKey.currentState!.validate()) return;
    } else if (_paymentMethod == PaymentMethod.yape ||
        _paymentMethod == PaymentMethod.plin) {
      if (_paymentRefCtrl.text.trim().length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingresa el número de operación o celular del pago.'),
          ),
        );
        return;
      }
    }

    setState(() => _processing = true);
    try {
      if (_paymentMethod == PaymentMethod.card) {
        await Future.delayed(const Duration(seconds: 2));
      } else {
        await Future.delayed(const Duration(milliseconds: 800));
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No autenticado');

      final items = widget.cart
          .map(
            (item) => {
              'product_id': item['product_id'],
              'quantity': item['quantity'],
              'unit_price': item['unit_price'],
            },
          )
          .toList();

      final orderId = await _repo.createOrder(
        clientId: user.id,
        pickupType: _pickupType,
        total: widget.total,
        items: items,
        paymentMethod: _paymentMethod.value,
        shippingAgency: _selectedShippingAgency,
      );

      if (!mounted) return;
      _showSuccess(orderId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrors.message(e)),
          backgroundColor: const Color(0xFFC8102E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showSuccess(String orderId) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 54),
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Pago Exitoso!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pedido #${AppFormatters.orderShortId(orderId)}',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _pickupType == PickupType.local.value
                    ? '✅ Tu pedido ha sido registrado. Puedes recoger tu repuesto en tienda cuando esté listo.'
                    : '📦 Tu pedido se enviará por encomienda interprovincial a la brevedad.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                widget.onOrderSuccess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'VER MIS PEDIDOS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Pago Seguro')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen
              Card(
                elevation: 4,
                shadowColor: primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total a pagar',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mi Vocho Repuestos',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          AppFormatters.currency(widget.total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Resumen del pedido',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: widget.cart.map((item) {
                    final qty = item['quantity'] as int;
                    final price = item['unit_price'] as double;
                    return ListTile(
                      dense: true,
                      title: Text(
                        item['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('$qty unidad${qty > 1 ? 'es' : ''}'),
                      trailing: Text(
                        AppFormatters.currency(price * qty),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Tipo de recojo
              Text(
                'Tipo de Entrega',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DeliveryOption(
                      icon: Icons.storefront_outlined,
                      label: 'Recojo en tienda',
                      subtitle: 'Huancayo',
                      selected: _pickupType == PickupType.local.value,
                      onTap: () => _selectPickupType(PickupType.local.value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DeliveryOption(
                      icon: Icons.local_shipping_outlined,
                      label: 'Envío interprovincial',
                      subtitle: 'Todo el Perú',
                      selected: _pickupType == PickupType.interprovincial.value,
                      onTap: () =>
                          _selectPickupType(PickupType.interprovincial.value),
                    ),
                  ),
                ],
              ),
              if (_isInterprovincial) ...[
                const SizedBox(height: 16),
                _ShippingAgencyPanel(
                  agencies: _shippingAgencies,
                  selectedAgency: _shippingAgency,
                  customAgencyLabel: _customShippingAgency,
                  customAgencyController: _customAgencyCtrl,
                  onAgencyChanged: (value) {
                    if (value == null) return;
                    setState(() => _shippingAgency = value);
                  },
                  onCustomAgencyChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Método de pago',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availablePaymentMethods.map((m) {
                  final selected = _paymentMethod == m;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(m.icon, size: 16),
                        const SizedBox(width: 4),
                        Text(m.label),
                      ],
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _paymentMethod = m),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_paymentMethod == PaymentMethod.inStore)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pagarás al recoger en La Casa del Volkswagen. '
                    'Te avisaremos cuando tu pedido esté listo.',
                    style: TextStyle(fontSize: 13, height: 1.35),
                  ),
                ),
              if (_paymentMethod == PaymentMethod.yape ||
                  _paymentMethod == PaymentMethod.plin) ...[
                Text(
                  'Envía el pago por ${_paymentMethod.label} y registra la operación:',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _paymentRefCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nº operación / celular',
                    prefixIcon: Icon(_paymentMethod.icon),
                  ),
                ),
              ],
              if (_paymentMethod.requiresCardForm) ...[
                Text(
                  'Datos de Tarjeta',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cardNumber,
                  decoration: const InputDecoration(
                    labelText: 'Número de tarjeta',
                    prefixIcon: Icon(Icons.credit_card),
                    hintText: '4242 4242 4242 4242',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                  validator: (v) => (v?.replaceAll(' ', '').length ?? 0) < 16
                      ? 'Número inválido (mínimo 16 dígitos)'
                      : null,
                  onChanged: (v) {
                    final digits = v.replaceAll(' ', '');
                    final formatted = digits
                        .replaceAllMapped(
                          RegExp(r'.{4}'),
                          (m) => '${m.group(0)} ',
                        )
                        .trim();
                    _cardNumber.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _cardHolder,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del titular',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Ingresa el nombre del titular'
                      : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiry,
                        decoration: const InputDecoration(
                          labelText: 'Vencimiento',
                          hintText: 'MM/AA',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        maxLength: 5,
                        validator: (v) => (v?.length ?? 0) < 5
                            ? 'Vencimiento inválido'
                            : null,
                        onChanged: (v) {
                          if (v.length == 2 && !v.contains('/')) {
                            _expiry.text = '$v/';
                            _expiry.selection = TextSelection.collapsed(
                              offset: _expiry.text.length,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cvv,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          hintText: '123',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 3,
                        validator: (v) =>
                            (v?.length ?? 0) < 3 ? 'CVV inválido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_paymentMethod == PaymentMethod.card)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Pago con tarjeta en modo demostración. Integración Culqi pendiente.',
                      style: TextStyle(
                        color: primary.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _processing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.lock_outline),
                  label: Text(
                    _processing
                        ? 'Procesando...'
                        : 'CONFIRMAR ${AppFormatters.currency(widget.total)}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _processing ? null : _processPayment,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShippingAgencyPanel extends StatelessWidget {
  final List<String> agencies;
  final String selectedAgency;
  final String customAgencyLabel;
  final TextEditingController customAgencyController;
  final ValueChanged<String?> onAgencyChanged;
  final ValueChanged<String> onCustomAgencyChanged;

  const _ShippingAgencyPanel({
    required this.agencies,
    required this.selectedAgency,
    required this.customAgencyLabel,
    required this.customAgencyController,
    required this.onAgencyChanged,
    required this.onCustomAgencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isCustom = selectedAgency == customAgencyLabel;
    final summary = isCustom && customAgencyController.text.trim().isNotEmpty
        ? customAgencyController.text.trim()
        : selectedAgency;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agencia de envío',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedAgency,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: primary),
                items: agencies
                    .map(
                      (agency) => DropdownMenuItem(
                        value: agency,
                        child: Row(
                          children: [
                            Icon(
                              agency == customAgencyLabel
                                  ? Icons.edit_location_alt_outlined
                                  : Icons.inventory_2_outlined,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              agency,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onAgencyChanged,
              ),
            ),
          ),
          if (isCustom) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: customAgencyController,
              onChanged: onCustomAgencyChanged,
              decoration: const InputDecoration(
                hintText: 'Escribe el nombre de la agencia',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _DeliveryOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? secondary.withValues(alpha: 0.25) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.04 : 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? primary : Colors.grey, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? primary : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
