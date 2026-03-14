import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/browse_history_service.dart';
import 'product_detail_page.dart';

/// 浏览记录页面
class BrowseHistoryPage extends StatefulWidget {
  const BrowseHistoryPage({super.key});

  @override
  State<BrowseHistoryPage> createState() => _BrowseHistoryPageState();
}

class _BrowseHistoryPageState extends State<BrowseHistoryPage> {
  List<Product> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    BrowseHistoryService.instance.addListener(_loadHistory);
  }

  @override
  void dispose() {
    BrowseHistoryService.instance.removeListener(_loadHistory);
    super.dispose();
  }

  void _loadHistory() {
    setState(() {
      _history = BrowseHistoryService.instance.history;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清空浏览记录'),
        content: const Text('确定要清空所有浏览记录吗？'),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('清空'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await BrowseHistoryService.instance.clear();
    }
  }

  Future<void> _removeItem(int productId) async {
    await BrowseHistoryService.instance.remove(productId);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('浏览记录'),
        actions: [
          if (_history.isNotEmpty)
            TextButton(
              onPressed: _clearHistory,
              child: Text(
                '清空',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
        ],
      ),
      body: _history.isEmpty
          ? _buildEmptyState(colorScheme)
          : _buildHistoryList(colorScheme),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无浏览记录',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final product = _history[index];
        return Dismissible(
          key: Key('browse_${product.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: colorScheme.errorContainer,
            child: Icon(
              Icons.delete_outline,
              color: colorScheme.onErrorContainer,
            ),
          ),
          onDismissed: (_) => _removeItem(product.id!),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image,
                      color: colorScheme.outline,
                    ),
                  ),
                ),
              ),
              title: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '¥${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(product: product),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}