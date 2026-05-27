import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

class OwnerInventoryScreen extends StatefulWidget {
  const OwnerInventoryScreen({super.key});
  @override
  State<OwnerInventoryScreen> createState() => _OwnerInventoryScreenState();
}

class _OwnerInventoryScreenState extends State<OwnerInventoryScreen> {
  final _repo = ProductRepository();
  final _searchCtrl = TextEditingController();
  List<ProductModel> _products = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  Future<void> _load(String query) async {
    setState(() => _loading = true);
    try {
      final result = query.isEmpty
          ? await _repo.getAllProducts()
          : await _repo.searchProducts(query);
      setState(() => _products = result);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario de Repuestos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, null),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Repuesto', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Card(
              elevation: 4,
              shadowColor: primary.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar repuesto para Vocho...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: primary),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _load('');
                            })
                        : null,
                  ),
                  onChanged: (v) => _load(v),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? _EmptyState(onAdd: () => _openForm(context, null))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _products.length,
                        itemBuilder: (_, i) => _ProductTile(
                          product: _products[i],
                          onStockEdit: (p) => _showStockDialog(context, p),
                          onTap: (p) => _openForm(context, p),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, ProductModel? product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProductFormScreen(
          existing: product,
          repository: _repo,
          onSaved: () => _load(_searchCtrl.text),
        ),
      ),
    );
  }

  void _showStockDialog(BuildContext context, ProductModel product) {
    final stockCtrl = TextEditingController(text: product.stock.toString());
    final theme = Theme.of(context);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Actualizar Stock',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nuevo Stock',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa una cantidad';
                  final val = int.tryParse(v);
                  if (val == null || val < 0) return 'Ingresa un número entero válido';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await _repo.updateStock(
                product.id,
                int.parse(stockCtrl.text),
              );
              if (context.mounted) Navigator.pop(context);
              _load(_searchCtrl.text);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final Function(ProductModel) onStockEdit;
  final Function(ProductModel) onTap;

  const _ProductTile({
    required this.product,
    required this.onStockEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowStock = product.stock <= ProductRepository.lowStockThreshold;
    final primary = theme.colorScheme.primary;
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: primary.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      child: ListTile(
        onTap: () => onTap(product),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 56,
            height: 56,
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: primary.withValues(alpha: 0.05),
                      child: const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => _placeholderIcon(primary),
                  )
                : _placeholderIcon(primary),
          ),
        ),
        title: Text(
          product.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            product.category ?? 'Sin categoría',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'S/. ${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: primary,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => onStockEdit(product),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: lowStock
                      ? const Color(0xFFC8102E).withValues(alpha: 0.08)
                      : Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: lowStock
                        ? const Color(0xFFC8102E).withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      lowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      size: 12,
                      color: lowStock ? const Color(0xFFC8102E) : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stock: ${product.stock}',
                      style: TextStyle(
                        color: lowStock ? const Color(0xFFC8102E) : Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon(Color primary) {
    return Container(
      color: primary.withValues(alpha: 0.08),
      child: Icon(Icons.build_circle_outlined, color: primary, size: 28),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay repuestos registrados',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primer repuesto de Volkswagen al inventario.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Repuesto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFormScreen extends StatefulWidget {
  final ProductModel? existing;
  final ProductRepository repository;
  final VoidCallback onSaved;

  const _ProductFormScreen({
    required this.existing,
    required this.repository,
    required this.onSaved,
  });

  @override
  State<_ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<_ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _catCtrl;
  late final TextEditingController _descCtrl;

  bool _saving = false;
  String? _imageUrl; // URL persistida en BD
  XFile? _pickedImage; // imagen seleccionada (todavía no subida)
  Uint8List? _pickedBytes; // bytes para preview (necesario en web)
  bool _removeImage = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _priceCtrl = TextEditingController(
        text: e == null ? '' : e.price.toStringAsFixed(2));
    _stockCtrl = TextEditingController(text: e == null ? '' : e.stock.toString());
    _catCtrl = TextEditingController(text: e?.category ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _imageUrl = e?.imageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _catCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _pickedBytes = bytes;
        _removeImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo seleccionar la imagen: $e')),
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Tomar una foto'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
              if (_pickedImage != null || (_imageUrl != null && !_removeImage))
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Quitar imagen',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedImage = null;
                      _pickedBytes = null;
                      _removeImage = _imageUrl != null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final base = ProductModel(
        id: widget.existing?.id ?? '',
        name: _nameCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        category: _catCtrl.text.trim().isEmpty ? 'General' : _catCtrl.text.trim(),
        price: double.parse(_priceCtrl.text),
        stock: int.parse(_stockCtrl.text),
        imageUrl: _removeImage ? null : _imageUrl,
        isActive: widget.existing?.isActive ?? true,
      );

      // 1) Primero hacemos upsert para asegurar que el producto exista (necesario
      //    para usar su id como carpeta en Storage).
      final saved = await widget.repository.upsertProduct(base);

      // 2) Si seleccionó una imagen nueva, la subimos y actualizamos la URL.
      if (_pickedImage != null) {
        final ext = _extensionFromName(_pickedImage!.name);
        final url = await widget.repository.uploadProductImage(
          productId: saved.id,
          file: kIsWeb ? null : File(_pickedImage!.path),
          bytes: kIsWeb ? _pickedBytes : null,
          fileExtension: ext,
        );
        await widget.repository.updateImageUrl(saved.id, url);

        // Si había una imagen previa distinta, intentamos limpiarla.
        final oldUrl = widget.existing?.imageUrl;
        if (oldUrl != null && oldUrl.isNotEmpty && oldUrl != url) {
          await widget.repository.deleteImageByUrl(oldUrl);
        }
      } else if (_removeImage && widget.existing?.imageUrl != null) {
        await widget.repository.updateImageUrl(saved.id, null);
        await widget.repository.deleteImageByUrl(widget.existing!.imageUrl!);
      }

      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Repuesto actualizado correctamente'
                : 'Repuesto creado correctamente'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _extensionFromName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return 'jpg';
    return name.substring(dot + 1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Repuesto' : 'Nuevo Repuesto'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ImagePickerField(
                imageUrl: _removeImage ? null : _imageUrl,
                pickedBytes: _pickedBytes,
                pickedXFilePath: _pickedImage?.path,
                onTap: _showImageSourceSheet,
              ),
              const SizedBox(height: 24),
              Text(
                'Detalles de la Pieza',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del repuesto',
                  prefixIcon: Icon(Icons.build_outlined),
                  hintText: 'Ej. Faros Neblineros delanteros',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingresa el nombre del repuesto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _catCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_outlined),
                  hintText: 'Ej. Motor, Carrocería, Faros',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.description_outlined),
                  hintText: 'Detalles, compatibilidad, etc.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Precio (S/.)',
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                        hintText: '0.00',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa el precio';
                        final val = double.tryParse(v);
                        if (val == null || val <= 0) return 'Precio inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _isEditing ? 'Stock' : 'Stock Inicial',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        hintText: '0',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa el stock';
                        final val = int.tryParse(v);
                        if (val == null || val < 0) return 'Stock inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primary,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isEditing
                              ? 'ACTUALIZAR REPUESTO'
                              : 'GUARDAR REPUESTO',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerField extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? pickedBytes;
  final String? pickedXFilePath;
  final VoidCallback onTap;

  const _ImagePickerField({
    required this.imageUrl,
    required this.pickedBytes,
    required this.pickedXFilePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    Widget content;
    final hasPicked = pickedBytes != null;
    final hasRemote = imageUrl != null && imageUrl!.isNotEmpty;

    if (hasPicked) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          pickedBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (hasRemote) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (_, __, ___) => _placeholder(primary),
        ),
      );
    } else {
      content = _placeholder(primary);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: primary.withValues(alpha: 0.05),
          border: Border.all(
            color: primary.withValues(alpha: 0.2),
            width: 1.2,
            style: BorderStyle.solid,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Cambiar',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(Color primary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined,
            size: 44, color: primary.withValues(alpha: 0.7)),
        const SizedBox(height: 8),
        Text(
          'Agregar imagen del repuesto',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Toca para elegir de galería o cámara',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
      ],
    );
  }
}
