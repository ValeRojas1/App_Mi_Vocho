import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/order_repository.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final double total;
  const CheckoutScreen({super.key, required this.cart, required this.total});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _repo = OrderRepository();
  final _formKey = GlobalKey<FormState>();

  // Datos de pago
  final _cardNumber = TextEditingController();
  final _cardHolder = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  String _pickupType = 'local';
  bool _processing = false;

  @override
  void dispose() {
    _cardNumber.dispose();
    _cardHolder.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  // Simula procesamiento de pago (en producción usar Culqi SDK)
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _processing = true);
    try {
      // Simular delay de pasarela
      await Future.delayed(const Duration(seconds: 2));

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('No autenticado');

      final items = widget.cart.map((item) => {
        'product_id': item['product_id'],
        'quantity': item['quantity'],
        'unit_price': item['unit_price'],
      }).toList();

      final orderId = await _repo.createOrder(
        clientId: user.id,
        pickupType: _pickupType,
        total: widget.total,
        items: items,
      );

      if (!mounted) return;
      _showSuccess(orderId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar: $e'),
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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.2),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pedido #${orderId.substring(0, 8).toUpperCase()}',
                  style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _pickupType == 'local'
                    ? '✅ Tu pedido ha sido registrado. Puedes recoger tu repuesto en tienda cuando esté listo.'
                    : '📦 Tu pedido se enviará por encomienda interprovincial a la brevedad.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
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
                Navigator.pop(context);       // cierra dialog
                Navigator.pop(context);       // vuelve al carrito
                Navigator.pop(context);       // vuelve al catálogo
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('VER MIS PEDIDOS', style: TextStyle(fontWeight: FontWeight.bold)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mi Vocho Repuestos',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                        Text(
                          'S/. ${widget.total.toStringAsFixed(2)}',
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
                      selected: _pickupType == 'local',
                      onTap: () => setState(() => _pickupType = 'local'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DeliveryOption(
                      icon: Icons.local_shipping_outlined,
                      label: 'Envío interprovincial',
                      subtitle: 'Todo el Perú',
                      selected: _pickupType == 'interprovincial',
                      onTap: () => setState(() => _pickupType = 'interprovincial'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Datos de tarjeta
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
                    ? 'Número inválido (mínimo 16 dígitos)' : null,
                onChanged: (v) {
                  final digits = v.replaceAll(' ', '');
                  final formatted = digits.replaceAllMapped(
                      RegExp(r'.{4}'), (m) => '${m.group(0)} ').trim();
                  _cardNumber.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                          offset: formatted.length));
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
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Ingresa el nombre del titular' : null,
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
                      validator: (v) =>
                          (v?.length ?? 0) < 5 ? 'Vencimiento inválido' : null,
                      onChanged: (v) {
                        if (v.length == 2 && !v.contains('/')) {
                          _expiry.text = '$v/';
                          _expiry.selection = TextSelection.collapsed(
                              offset: _expiry.text.length);
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
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Modo Prototipo: Cualquier valor formal de simulación es válido.',
                        style: TextStyle(color: primary.withValues(alpha: 0.8), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _processing
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.lock_outline),
                  label: Text(_processing
                      ? 'Procesando Pago...'
                      : 'PAGAR S/. ${widget.total.toStringAsFixed(2)}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

class _DeliveryOption extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _DeliveryOption({
    required this.icon, required this.label, required this.subtitle,
    required this.selected, required this.onTap,
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
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? primary : Colors.grey, size: 24),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold,
                    color: selected ? primary : Colors.grey.shade700)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}