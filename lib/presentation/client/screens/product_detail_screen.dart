import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../data/models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  final bool Function(Map<String, dynamic>) onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final outOfStock = product.stock == 0;
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Ficha del repuesto')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.directions_car_filled_outlined,
                        size: 72,
                        color: primary.withValues(alpha: 0.5),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (product.category != null)
                    Chip(
                      label: Text(product.category!),
                      backgroundColor: primary.withValues(alpha: 0.1),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppFormatters.currency(product.price),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        outOfStock ? Icons.cancel_outlined : Icons.check_circle,
                        color: outOfStock ? Colors.red : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        outOfStock
                            ? 'Sin stock'
                            : 'Disponible: ${product.stock} unidad(es)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: outOfStock
                              ? Colors.red
                              : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Descripción',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (product.description?.trim().isNotEmpty ?? false)
                        ? product.description!
                        : 'Repuesto original o compatible para tu Volkswagen Vocho. '
                              'Consulta en tienda por compatibilidad exacta.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: outOfStock
                      ? null
                      : () {
                          final added = onAddToCart({
                            'product_id': product.id,
                            'name': product.name,
                            'unit_price': product.price,
                            'stock': product.stock,
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? 'Agregado al carrito'
                                    : 'Stock máximo alcanzado',
                              ),
                            ),
                          );
                          if (added) Navigator.pop(context);
                        },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(outOfStock ? 'AGOTADO' : 'AGREGAR AL CARRITO'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
