import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  final String? category;
  const ProductListPage({super.key, this.category});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: ProductService.instance.fetchCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final categories = snapshot.data ?? [];
        final tabs = ['全部', ...categories];

        int initialIndex = 0;
        if (widget.category != null) {
          final idx = tabs.indexOf(widget.category!);
          if (idx != -1) {
            initialIndex = idx;
          }
        }

        return DefaultTabController(
          length: tabs.length,
          initialIndex: initialIndex,
          child: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('商品分类'),
                  bottom: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: EdgeInsets.zero,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    labelStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 14),
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    tabs: tabs.map((t) => Tab(text: t)).toList(),
                  ),
                ),
                body: TabBarView(
                  children: tabs.map((t) {
                    final category = t == '全部' ? null : t;
                    return _ProductGridView(category: category);
                  }).toList(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductGridView extends StatelessWidget {
  final String? category;
  const _ProductGridView({this.category});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: ProductService.instance.fetchProducts(category: category),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data!;
        if (products.isEmpty) {
          return const Center(child: Text('暂无商品'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductGridCard(product: product);
          },
        );
      },
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  const _ProductGridCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product)),
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
                        size: 48,
                        color: Theme.of(context).colorScheme.outline),
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
