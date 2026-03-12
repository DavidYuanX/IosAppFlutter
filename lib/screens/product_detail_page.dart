import 'package:flutter/material.dart';

import '../models/order.dart' as order_model;
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import 'order_detail_page.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: colorScheme.surfaceContainerHighest,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.image,
                        size: 80, color: colorScheme.outline),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.originalPrice != null)
                        Text(
                          '¥${product.originalPrice!.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.outline,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${((1 - product.price / (product.originalPrice ?? product.price)) * 100).toStringAsFixed(0)}% OFF',
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(product.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text('${product.rating}',
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 16),
                      Text('已售 ${product.salesCount}',
                          style: TextStyle(
                              fontSize: 13, color: colorScheme.outline)),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(product.category,
                            style: TextStyle(
                                fontSize: 11, color: colorScheme.outline)),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('商品详情',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(product.description,
                      style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.6)),
                  const SizedBox(height: 16),
                  _buildInfoRow('配送', '全国包邮  预计3-5天送达'),
                  _buildInfoRow('保障', '正品保证  7天无理由退换'),
                  _buildInfoRow('服务', '顺丰发货  极速售后'),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListenableBuilder(
                    listenable: CartService.instance,
                    builder: (context, _) {
                      final count = CartService.instance.totalCount;
                      return Badge(
                        isLabelVisible: count > 0,
                        label: Text('$count'),
                        child: IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    CartService.instance.addProduct(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('已加入购物车'),
                          duration: Duration(seconds: 1)),
                    );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('加入购物车', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    try {
                      final items = [
                        order_model.OrderItem(
                          productId: product.id,
                          productName: product.name,
                          productImage: product.imageUrl,
                          price: product.price,
                          quantity: 1,
                        ),
                      ];
                      final order =
                          await ApiService.instance.createOrder(items);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('下单成功'),
                            duration: Duration(seconds: 1)),
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                OrderDetailPage(orderId: order.id!)),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('下单失败: $e')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('立即购买', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child:
                  Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
