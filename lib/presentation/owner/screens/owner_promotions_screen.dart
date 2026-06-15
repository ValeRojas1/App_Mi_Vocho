import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/app_errors.dart';
import '../../../data/models/promotion_model.dart';
import '../../../data/repositories/promotion_repository.dart';
import '../../shared/widgets/branded_app_bar_title.dart';
import '../widgets/owner_side_drawer.dart';

class OwnerPromotionsScreen extends StatefulWidget {
  const OwnerPromotionsScreen({super.key});

  @override
  State<OwnerPromotionsScreen> createState() => _OwnerPromotionsScreenState();
}

class _OwnerPromotionsScreenState extends State<OwnerPromotionsScreen> {
  final _repo = PromotionRepository();
  final _picker = ImagePicker();
  final Map<String, String> _titles = {};
  final Map<String, bool> _active = {};
  final Map<String, XFile> _pickedFiles = {};
  final Map<String, Uint8List> _pickedBytes = {};
  final Set<String> _saving = {};

  List<PromotionModel> _promotions = [];
  bool _loading = true;
  bool _setupRequired = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _setupRequired = false;
      _error = null;
    });
    try {
      final promotions = await _repo.getOwnerPromotions();
      if (!mounted) return;
      setState(() {
        _promotions = promotions;
        for (final promo in promotions) {
          _titles[promo.id] = promo.title;
          _active[promo.id] = promo.isActive;
        }
      });
    } on PromotionSetupRequiredException {
      if (!mounted) return;
      setState(() => _setupRequired = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppErrors.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(PromotionModel promo) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedFiles[promo.id] = picked;
      _pickedBytes[promo.id] = bytes;
    });
  }

  Future<void> _save(PromotionModel promo) async {
    setState(() => _saving.add(promo.id));
    try {
      String? imageUrl = promo.imageUrl;
      final picked = _pickedFiles[promo.id];
      if (picked != null) {
        final bytes = _pickedBytes[promo.id] ?? await picked.readAsBytes();
        imageUrl = await _repo.uploadPromotionImage(
          position: promo.position,
          bytes: bytes,
          fileExtension: _extensionFromName(picked.name),
        );
      }

      await _repo.updatePromotion(
        id: promo.id,
        title: (_titles[promo.id] ?? promo.title).trim().isEmpty
            ? 'Oferta ${promo.position + 1}'
            : (_titles[promo.id] ?? promo.title).trim(),
        isActive: _active[promo.id] ?? promo.isActive,
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      _pickedFiles.remove(promo.id);
      _pickedBytes.remove(promo.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagen actualizada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrors.message(e))));
    } finally {
      if (mounted) setState(() => _saving.remove(promo.id));
    }
  }

  String _extensionFromName(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return 'jpg';
    final ext = parts.last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      drawer: const OwnerSideDrawer(),
      appBar: AppBar(
        title: const BrandedAppBarTitle(subtitle: 'Ofertas y noticias'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _setupRequired
          ? _PromotionSetupRequired(onRetry: _load)
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _load,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: _promotions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, index) {
                  final promo = _promotions[index];
                  return _PromotionSlotCard(
                    promo: promo,
                    title: _titles[promo.id] ?? promo.title,
                    active: _active[promo.id] ?? promo.isActive,
                    pickedBytes: _pickedBytes[promo.id],
                    saving: _saving.contains(promo.id),
                    primary: primary,
                    onTitleChanged: (value) =>
                        setState(() => _titles[promo.id] = value),
                    onActiveChanged: (value) =>
                        setState(() => _active[promo.id] = value),
                    onPickImage: () => _pickImage(promo),
                    onSave: () => _save(promo),
                  );
                },
              ),
            ),
    );
  }
}

class _PromotionSetupRequired extends StatelessWidget {
  final VoidCallback onRetry;

  const _PromotionSetupRequired({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.storage_outlined, color: primary, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  'Falta preparar Supabase',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Para editar las imágenes de ofertas y noticias primero debes aplicar la migración que crea la tabla promotions y el bucket promotion-images.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'supabase/migrations/20260606000000_add_shipping_agency.sql',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromotionSlotCard extends StatelessWidget {
  final PromotionModel promo;
  final String title;
  final bool active;
  final Uint8List? pickedBytes;
  final bool saving;
  final Color primary;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onPickImage;
  final VoidCallback onSave;

  const _PromotionSlotCard({
    required this.promo,
    required this.title,
    required this.active,
    required this.pickedBytes,
    required this.saving,
    required this.primary,
    required this.onTitleChanged,
    required this.onActiveChanged,
    required this.onPickImage,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${promo.position + 1}',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Espacio ${promo.position + 1}',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                Switch(value: active, onChanged: onActiveChanged),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 16 / 7,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _PreviewImage(
                  imageUrl: promo.imageUrl,
                  pickedBytes: pickedBytes,
                  primary: primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: title,
              onChanged: onTitleChanged,
              decoration: const InputDecoration(
                labelText: 'Título interno',
                prefixIcon: Icon(Icons.short_text_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: saving ? null : onPickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Elegir imagen'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: saving ? null : onSave,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Guardando' : 'Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? pickedBytes;
  final Color primary;

  const _PreviewImage({
    required this.imageUrl,
    required this.pickedBytes,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (pickedBytes != null) {
      return Image.memory(pickedBytes!, fit: BoxFit.cover);
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(
        Icons.campaign_outlined,
        color: primary.withValues(alpha: 0.45),
        size: 44,
      ),
    );
  }
}
