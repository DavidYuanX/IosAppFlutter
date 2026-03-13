import 'package:flutter/material.dart';

import '../models/order.dart' as order_model;
import '../services/api_service.dart';
import '../services/cart_service.dart';
import 'login_page.dart';
import 'order_detail_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('购物车'),
        actions: [
          ListenableBuilder(
            listenable: CartService.instance,
            builder: (context, _) {
              if (CartService.instance.items.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () => _confirmClear(context),
                child: const Text('清空'),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: CartService.instance,
        builder: (context, _) {
          final cart = CartService.instance;
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('购物车是空的',
                      style: TextStyle(
                          fontSize: 16, color: colorScheme.outline)),
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item.product.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.image),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '¥${item.product.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      size: 20, color: colorScheme.outline),
                                  onPressed: () =>
                                      cart.removeProduct(item.product.id),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _QuantityButton(
                                      icon: Icons.remove,
                                      onPressed: item.quantity > 1
                                          ? () => cart.updateQuantity(
                                              item.product.id,
                                              item.quantity - 1)
                                          : null,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text('${item.quantity}',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    _QuantityButton(
                                      icon: Icons.add,
                                      onPressed: () => cart.updateQuantity(
                                          item.product.id,
                                          item.quantity + 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2)),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('共 ${cart.totalCount} 件',
                              style: TextStyle(
                                  fontSize: 12, color: colorScheme.outline)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text('合计 ',
                                  style: TextStyle(fontSize: 14)),
                              Text(
                                '¥${cart.totalPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.error),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => _checkout(context),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(120, 48),
                        ),
                        child: const Text('去结算',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _checkout(BuildContext context) async {
    // 检查是否登录
    final loggedIn = await ApiService.instance.isLoggedIn();
    if (!loggedIn) {
      if (!context.mounted) return;
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('请先登录'),
          content: const Text('结算需要登录账号，是否立即登录？'),
          actions: [
            TextButton(
                child: const Text('取消'),
                onPressed: () => Navigator.of(context).pop(false)),
            FilledButton(
                child: const Text('去登录'),
                onPressed: () => Navigator.of(context).pop(true)),
          ],
        ),
      );
      if (shouldLogin == true && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final cart = CartService.instance;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认下单'),
        content: Text(
            '共 ${cart.totalCount} 件商品，合计 ¥${cart.totalPrice.toStringAsFixed(0)}，确认提交订单？'),
        actions: [
          TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop()),
          FilledButton(
            child: const Text('提交订单'),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final items = cart.items
                    .map((e) => order_model.OrderItem(
                          productId: e.product.id,
                          productName: e.product.name,
                          productImage: e.product.imageUrl,
                          price: e.product.price,
                          quantity: e.quantity,
                        ))
                    .toList();
                final order = await ApiService.instance.createOrder(items);
                cart.clear();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('下单成功！')),
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => OrderDetailPage(orderId: order.id!)),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('下单失败: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定清空购物车吗？'),
        actions: [
          TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop()),
          TextButton(
            child: const Text('清空'),
            onPressed: () {
              CartService.instance.clear();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _QuantityButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Icon(icon,
            size: 16, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
