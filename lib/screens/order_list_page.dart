import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_service.dart';
import 'order_detail_page.dart';

class OrderListPage extends StatefulWidget {
  final String? initialStatus;
  const OrderListPage({super.key, this.initialStatus});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['全部', '待付款', '待发货', '待收货', '已完成', '已取消'];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialStatus != null
        ? _tabs.indexOf(widget.initialStatus!).clamp(0, _tabs.length - 1)
        : 0;
    _tabController = TabController(
        length: _tabs.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('我的订单'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          final status = tab == '全部' ? null : tab;
          return _OrderTabView(status: status);
        }).toList(),
      ),
    );
  }
}

class _OrderTabView extends StatefulWidget {
  final String? status;
  const _OrderTabView({this.status});

  @override
  State<_OrderTabView> createState() => _OrderTabViewState();
}

class _OrderTabViewState extends State<_OrderTabView>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Order>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.fetchOrders(status: widget.status);
  }

  void _reload() {
    setState(() {
      _future = ApiService.instance.fetchOrders(status: widget.status);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return ListView(children: [_buildEmpty(context)]);
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            itemCount: orders.length,
            itemBuilder: (context, index) =>
                _OrderCard(order: orders[index], onChanged: _reload),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                size: 44, color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 16),
          Text('暂无订单',
              style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 6),
          Text('去逛逛，发现好物',
              style: TextStyle(
                  fontSize: 13,
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.6))),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onChanged;
  const _OrderCard({required this.order, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => OrderDetailPage(orderId: order.id!)),
            );
            onChanged();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.storefront_outlined,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('订单 #${order.id}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant)),
                    const Spacer(),
                    _StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 12),
                ...order.items.take(2).map((item) => _buildItemRow(item, colorScheme)),
                if (order.items.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 2),
                    child: Text(
                      '还有 ${order.items.length - 2} 件商品',
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.outline),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Text(order.formattedDate,
                          style: TextStyle(
                              fontSize: 12, color: colorScheme.outline)),
                      const Spacer(),
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                                text: '共${order.items.length}件  ',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.outline)),
                            const TextSpan(
                                text: '实付 ',
                                style: TextStyle(fontSize: 13)),
                            TextSpan(
                              text:
                                  '¥${order.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCardActions(context, order),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(OrderItem item, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.productImage ?? '',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image_outlined,
                    size: 22, color: colorScheme.outline),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text('¥${item.price.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 13, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('x${item.quantity}',
                style: TextStyle(fontSize: 12, color: colorScheme.outline)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActions(BuildContext context, Order order) {
    List<Widget> actions = [];
    switch (order.status) {
      case '待付款':
        actions = [
          _ActionButton(label: '取消订单', filled: false, onTap: () {}),
          _ActionButton(label: '去付款', filled: true, onTap: () {}),
        ];
        break;
      case '待收货':
        actions = [
          _ActionButton(label: '确认收货', filled: true, onTap: () {}),
        ];
        break;
      case '已完成':
        actions = [
          _ActionButton(label: '再次购买', filled: false, onTap: () {}),
        ];
        break;
    }
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions
            .expand((w) => [w, const SizedBox(width: 8)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (filled) {
      return SizedBox(
        height: 32,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            textStyle: const TextStyle(fontSize: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(label),
        ),
      );
    }
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: const TextStyle(fontSize: 13),
          side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(label),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (status) {
      '待付款' => (Colors.orange, Icons.access_time_rounded),
      '待发货' => (Colors.blue, Icons.inventory_2_outlined),
      '待收货' => (Colors.teal, Icons.local_shipping_outlined),
      '已完成' => (Colors.green, Icons.check_circle_outline),
      '已取消' => (Colors.grey, Icons.cancel_outlined),
      _ => (Colors.grey, Icons.receipt_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(status,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
