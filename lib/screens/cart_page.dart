import 'package:flutter/material.dart';

import '../services/cart_service.dart';

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
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
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
                                  Text(item.product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Text(
                                    '¥${item.product.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.error),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20),
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
                                              fontSize: 16,
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

  void _checkout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('提示'),
        content: Text(
            '订单总额 ¥${CartService.instance.totalPrice.toStringAsFixed(0)}，确认下单？'),
        actions: [
          TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop()),
          FilledButton(
            child: const Text('确认'),
            onPressed: () {
              CartService.instance.clear();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('下单成功！')),
              );
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
      child: IconButton.outlined(
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}
