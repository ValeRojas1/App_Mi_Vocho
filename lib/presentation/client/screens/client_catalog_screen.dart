import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/promotion_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/promotion_repository.dart';
import '../../shared/widgets/branded_app_bar_title.dart';
import '../../shared/widgets/list_shimmer.dart';
import 'client_profile_screen.dart';
import 'product_detail_screen.dart';

class ClientCatalogScreen extends StatefulWidget {
  final bool Function(Map<String, dynamic>) onAddToCart;
  final VoidCallback? onInitialLoadComplete;

  const ClientCatalogScreen({
    super.key,
    required this.onAddToCart,
    this.onInitialLoadComplete,
  });
  @override
  State<ClientCatalogScreen> createState() => ClientCatalogScreenState();
}

class ClientCatalogScreenState extends State<ClientCatalogScreen> {
  final _repo = ProductRepository();
  final _promotionRepo = PromotionRepository();
  final _searchCtrl = TextEditingController();
  final _promoController = PageController();
  List<ProductModel> _products = [];
  List<ProductModel> _allActive = [];
  List<PromotionModel> _promotions = [];
  String? _selectedCategory;
  bool _loading = false;
  Timer? _promoTimer;
  int _promoPage = 0;
  bool _notifiedInitialLoad = false;

  int get _promoSlideCount => _promotions.isEmpty ? 3 : _promotions.length;

  List<String> get _categories {
    final set = <String>{};
    for (final p in _allActive) {
      final c = p.category?.trim();
      if (c != null && c.isNotEmpty) set.add(c);
    }
    final list = set.toList()..sort();
    return list;
  }

  void _applyCategoryFilter() {
    if (_selectedCategory == null) {
      _products = List.from(_allActive);
    } else {
      _products = _allActive
          .where((p) => p.category == _selectedCategory)
          .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _load('');
    _loadPromotions();
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_promoController.hasClients) return;
      _promoPage = (_promoPage + 1) % _promoSlideCount;
      _promoController.animateToPage(
        _promoPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
    setState(() => _loading = true);
    try {
      final result = query.isEmpty
          ? await _repo.getAllProducts()
          : await _repo.searchProducts(query);
      _allActive = result.where((p) => p.isActive).toList();
      _applyCategoryFilter();
      setState(() {});
    } finally {
      if (mounted) setState(() => _loading = false);
      _notifyInitialLoadComplete();
    }
  }

  void _notifyInitialLoadComplete() {
    if (_notifiedInitialLoad) return;
    _notifiedInitialLoad = true;
    widget.onInitialLoadComplete?.call();
  }

  Future<void> _loadPromotions() async {
    final promotions = await _promotionRepo.getActivePromotions();
    if (!mounted) return;
    setState(() {
      _promotions = promotions;
      if (_promoPage >= _promoSlideCount) _promoPage = 0;
    });
  }

  Future<void> refresh() async {
    await Future.wait([_load(_searchCtrl.text), _loadPromotions()]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(),
        actions: [
          Material(
            color: primary.withValues(alpha: 0.12),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClientProfileScreen(),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.person_outline, color: primary, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Card(
              elevation: 4,
              shadowColor: primary.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar repuesto para tu Vocho...',
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
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => _load(v),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: _PromoCarousel(
              controller: _promoController,
              promotions: _promotions,
              onPageChanged: (page) => _promoPage = page,
            ),
          ),
          if (_categories.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Todas'),
                      selected: _selectedCategory == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = null;
                          _applyCategoryFilter();
                        });
                      },
                    ),
                  ),
                  ..._categories.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c),
                        selected: _selectedCategory == c,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = c;
                            _applyCategoryFilter();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: _loading
                  ? const ListShimmer(itemCount: 4, itemHeight: 120)
                  : _products.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.45,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.build_circle_outlined,
                                    size: 64,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No se encontraron repuestos',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.73,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _products.length,
                      itemBuilder: (_, i) => _ProductCard(
                        product: _products[i],
                        onAddToCart: widget.onAddToCart,
                        onOpenDetail: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              product: _products[i],
                              onAddToCart: widget.onAddToCart,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCarousel extends StatefulWidget {
  final PageController controller;
  final List<PromotionModel> promotions;
  final ValueChanged<int> onPageChanged;

  const _PromoCarousel({
    required this.controller,
    required this.promotions,
    required this.onPageChanged,
  });

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final itemCount = widget.promotions.isEmpty ? 3 : widget.promotions.length;

    return SizedBox(
      height: 140,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: widget.controller,
              itemCount: itemCount,
              onPageChanged: (page) {
                setState(() => _current = page);
                widget.onPageChanged(page);
              },
              itemBuilder: (_, index) {
                final promo = widget.promotions.isEmpty
                    ? null
                    : widget.promotions[index];
                final imageUrl = promo?.imageUrl;
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  return CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade100),
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.grey.shade100),
                  );
                }
                return Container(color: Colors.grey.shade100);
              },
            ),
            Positioned(
              left: 12,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ofertas y noticias',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  itemCount,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _current == index ? 18 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _current == index
                          ? primary
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool Function(Map<String, dynamic>) onAddToCart;
  final VoidCallback onOpenDetail;

  const _ProductCard({
    required this.product,
    required this.onAddToCart,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final outOfStock = product.stock == 0;
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;
    final heroTag = 'product-image-${product.id}';

    return Card(
      elevation: 2,
      shadowColor: primary.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: hasImage
                    ? () => _openImageViewer(context, product, heroTag)
                    : null,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: hasImage
                        ? null
                        : LinearGradient(
                            colors: [
                              secondary.withValues(alpha: 0.4),
                              secondary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                  ),
                  child: hasImage
                      ? Hero(
                          tag: heroTag,
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) => Container(
                              color: secondary.withValues(alpha: 0.15),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: primary.withValues(alpha: 0.6),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.directions_car_filled_outlined,
                          size: 54,
                          color: primary.withValues(alpha: 0.75),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.category ?? 'General',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppFormatters.currency(product.price),
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
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
                                        ? '¡${product.name} agregado al carrito!'
                                        : 'Stock máximo alcanzado para este repuesto.',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: added
                                      ? primary
                                      : const Color(0xFFC8102E),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: outOfStock
                            ? Colors.grey.shade300
                            : primary,
                      ),
                      child: Text(
                        outOfStock ? 'Agotado' : 'Agregar',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImageViewer(
    BuildContext context,
    ProductModel product,
    String heroTag,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) =>
            _FullScreenImageViewer(product: product, heroTag: heroTag),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final ProductModel product;
  final String heroTag;

  const _FullScreenImageViewer({required this.product, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          product.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Hero(
                    tag: heroTag,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 80,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.category ?? 'General',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.currency(product.price),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
