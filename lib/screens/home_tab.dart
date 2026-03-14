import 'dart:async';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/paginated_product_list.dart';
import 'product_detail_page.dart';
import 'product_list_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _banners = const [
    {'color': Color(0xFF1a1a2e), 'text': '春季大促  全场低至5折'},
    {'color': Color(0xFF16213e), 'text': '数码新品  限时特惠'},
    {'color': Color(0xFF0f3460), 'text': '每日坚果  买二送一'},
  ];

  late final PageController _pageController;
  final _productListKey = GlobalKey<PaginatedProductListState>();
  Timer? _autoScrollTimer;
  int _currentBanner = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentBanner + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      final maxScroll = notification.metrics.maxScrollExtent;
      final currentScroll = notification.metrics.pixels;
      if (maxScroll - currentScroll < 300) {
        _productListKey.currentState?.loadPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _openSearch(context),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.search,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text('搜索商品...',
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ProductService.instance.clearCategoryCache();
          setState(() {});
        },
        child: FutureBuilder<List<String>>(
          future: ProductService.instance.fetchCategories(),
          builder: (context, catSnap) {
            final categories = catSnap.data ?? [];
            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                _onScroll(notification);
                return false;
              },
              child: ListView(
                children: [
                  _buildBanner(),
                  const SizedBox(height: 16),
                  if (categories.isNotEmpty) _buildCategoryGrid(categories),
                  const SizedBox(height: 16),
                  _buildSectionTitle('热门推荐'),
                  _buildProductSection(null),
                  if (_productListKey.currentState?.isLoading ?? false)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentBanner = i),
        itemCount: _banners.length,
        itemBuilder: (context, index) {
          final banner = _banners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: banner['color'] as Color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                banner['text'] as String,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid(List<String> categories) {
    final icons = [
      Icons.devices,
      Icons.checkroom,
      Icons.restaurant,
      Icons.weekend,
      Icons.fitness_center,
      Icons.menu_book,
    ];
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.9,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final icon = icons[index % icons.length];
          final color = [
            Colors.blue,
            Colors.pink,
            Colors.deepOrange,
            Colors.teal,
            Colors.indigo,
            Colors.purple,
          ][index % 6];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => ProductListPage(category: categories[index])),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  categories[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductListPage()),
            ),
            child: const Text('查看全部 >'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(String? category) {
    return PaginatedProductList(
      key: _productListKey,
      category: category,
    );
  }

  void _openSearch(BuildContext context) {
    showSearch(context: context, delegate: _ProductSearchDelegate());
  }
}

class _ProductSearchDelegate extends SearchDelegate<Product?> {
  @override
  String get searchFieldLabel => '搜索商品';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('输入关键词搜索'));
    }
    return FutureBuilder<List<Product>>(
      future: ProductService.instance.searchProducts(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data!;
        if (results.isEmpty) {
          return const Center(child: Text('没有找到相关商品'));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final p = results[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(p.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image, size: 48)),
              ),
              title: Text(p.name),
              subtitle: Text('¥${p.price.toStringAsFixed(0)}'),
              onTap: () {
                close(context, null);
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => ProductDetailPage(product: p)),
                );
              },
            );
          },
        );
      },
    );
  }
}
