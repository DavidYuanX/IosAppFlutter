import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../screens/product_detail_page.dart';

/// 分页商品列表组件
class PaginatedProductList extends StatefulWidget {
  final String? category;
  final bool scrollable;

  const PaginatedProductList({
    super.key,
    this.category,
    this.scrollable = false,
  });

  @override
  State<PaginatedProductList> createState() => PaginatedProductListState();
}

class PaginatedProductListState extends State<PaginatedProductList> {
  final List<Product> _products = [];
  final _scrollController = ScrollController();
  int _currentPage = 0;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _hasError = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get hasMore => _currentPage < _totalPages;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    if (widget.scrollable) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void didUpdateWidget(PaginatedProductList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _loadFirstPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      loadPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _products.clear();
      _currentPage = 0;
      _hasError = false;
    });
    await loadPage();
  }

  Future<void> loadPage() async {
    if (_isLoading || _currentPage >= _totalPages) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.instance.fetchProductsPaginated(
        category: widget.category,
        page: _currentPage,
        size: 20,
      );

      if (mounted) {
        setState(() {
          _products.addAll(result.content);
          _totalPages = result.totalPages;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty && _isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_products.isEmpty && _hasError) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('加载失败'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loadFirstPage,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('暂无商品')),
      );
    }

    return GridView.builder(
      controller: widget.scrollable ? _scrollController : null,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) => _ProductCard(product: _products[index]),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.image,
                        size: 48, color: Theme.of(context).colorScheme.outline),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    Row(
                      children: [
                        Text('¥${product.price.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.error)),
                        const SizedBox(width: 4),
                        if (product.originalPrice != null)
                          Text(
                            '¥${product.originalPrice!.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.outline,
                                decoration: TextDecoration.lineThrough),
                          ),
                      ],
                    ),
                    Text('已售 ${product.salesCount}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}