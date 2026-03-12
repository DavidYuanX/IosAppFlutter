import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<Order> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.fetchOrder(widget.orderId);
  }

  void _reload() {
    setState(() {
      _future = ApiService.instance.fetchOrder(widget.orderId);
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await ApiService.instance.updateOrderStatus(widget.orderId, newStatus);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('取消订单'),
        content: const Text('确定要取消此订单吗？'),
        actions: [
          TextButton(
              child: const Text('返回'),
              onPressed: () => Navigator.of(context).pop(false)),
          TextButton(
              child: const Text('取消订单'),
              onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.instance.cancelOrder(widget.orderId);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('取消失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: FutureBuilder<Order>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('订单详情')),
              body: Center(child: Text('加载失败: ${snapshot.error}')),
            );
          }
          final order = snapshot.data!;
          return _buildBody(context, order);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, Order order) {
    final colorScheme = Theme.of(context).colorScheme;
    final (Color statusColor, IconData statusIcon, String statusHint) =
        switch (order.status) {
      '待付款' => (Colors.orange, Icons.access_time_rounded, '请尽快完成付款'),
      '待发货' => (Colors.blue, Icons.inventory_2_outlined, '商家正在备货中'),
      '待收货' => (Colors.teal, Icons.local_shipping_outlined, '商品正在配送中'),
      '已完成' => (Colors.green, Icons.check_circle_outline, '感谢您的购买'),
      '已取消' => (Colors.grey, Icons.cancel_outlined, '订单已取消'),
      _ => (Colors.grey, Icons.receipt_outlined, ''),
    };

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 140,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(60, 12, 20, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          Text(order.status,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(statusHint,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          foregroundColor: Colors.white,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildStepIndicator(order, statusColor),
              const SizedBox(height: 16),
              _buildItemsCard(order, colorScheme),
              const SizedBox(height: 12),
              _buildPriceCard(order, colorScheme),
              const SizedBox(height: 12),
              _buildInfoCard(order, colorScheme),
              const SizedBox(height: 24),
              _buildActions(order),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(Order order, Color activeColor) {
    const steps = ['待付款', '待发货', '待收货', '已完成'];
    final currentStep = steps.indexOf(order.status).clamp(0, steps.length - 1);
    final isCancelled = order.status == '已取消';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            final done = !isCancelled && stepIdx < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: done
                    ? activeColor
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.15),
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final done = !isCancelled && stepIdx <= currentStep;
          final isCurrent = !isCancelled && stepIdx == currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isCurrent ? 24 : 18,
                height: isCurrent ? 24 : 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? activeColor
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.15),
                ),
                child: done
                    ? Icon(
                        isCurrent ? Icons.radio_button_checked : Icons.check,
                        size: isCurrent ? 14 : 12,
                        color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 6),
              Text(steps[stepIdx],
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.normal,
                      color: done
                          ? activeColor
                          : Theme.of(context).colorScheme.outline)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildItemsCard(Order order, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
                const Text('商品清单',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('共${order.items.length}件',
                    style:
                        TextStyle(fontSize: 12, color: colorScheme.outline)),
              ],
            ),
          ),
          ...order.items.map((item) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.productImage ?? '',
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.image_outlined,
                              color: colorScheme.outline),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('¥${item.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.error)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('x${item.quantity}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.outline)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPriceCard(Order order, ColorScheme colorScheme) {
    final itemTotal = order.items.fold<double>(
        0, (sum, item) => sum + item.price * item.quantity);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _priceRow('商品总价', '¥${itemTotal.toStringAsFixed(2)}', colorScheme),
          _priceRow('运费', '免运费', colorScheme),
          const Divider(height: 20),
          Row(
            children: [
              Text('实付金额',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface)),
              const Spacer(),
              Text('¥${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: colorScheme.outline)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Order order, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: colorScheme.primary),
              const SizedBox(width: 6),
              const Text('订单信息',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('订单编号', '${order.id}', colorScheme),
          _infoRow('下单时间', order.formattedDate, colorScheme),
          _infoRow('订单状态', order.status, colorScheme),
          _infoRow('支付方式', '在线支付', colorScheme),
          _infoRow('配送方式', '快递配送', colorScheme),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: colorScheme.outline)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildActions(Order order) {
    switch (order.status) {
      case '待付款':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelOrder,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('取消订单', style: TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _updateStatus('待发货'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('立即付款', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        );
      case '待发货':
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _cancelOrder,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('取消订单', style: TextStyle(fontSize: 15)),
          ),
        );
      case '待收货':
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _updateStatus('已完成'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('确认收货', style: TextStyle(fontSize: 15)),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
