import 'package:flutter/material.dart';

import '../services/product_service.dart';
import '../widgets/paginated_product_list.dart';

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
                    return PaginatedProductList(
                      category: category,
                      scrollable: true,
                    );
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
