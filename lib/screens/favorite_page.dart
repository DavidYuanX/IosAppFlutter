import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/favorite_service.dart';
import 'product_detail_page.dart';

/// 收藏页面
class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<Product> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    FavoriteService.instance.addListener(_loadFavorites);
  }

  @override
  void dispose() {
    FavoriteService.instance.removeListener(_loadFavorites);
    super.dispose();
  }

  void _loadFavorites() {
    setState(() {
      _favorites = FavoriteService.instance.favorites;
    });
  }

  Future<void> _removeItem(int productId) async {
    await FavoriteService.instance.remove(productId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已取消收藏'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
      ),
      body: _favorites.isEmpty
          ? _buildEmptyState(colorScheme)
          : _buildFavoriteList(colorScheme),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无收藏商品',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '去逛逛，收藏喜欢的商品吧',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.outline.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteList(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final product = _favorites[index];
        return Dismissible(
          key: Key('favorite_${product.id}'),
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
              trailing: IconButton(
                icon: Icon(
                  Icons.favorite,
                  color: colorScheme.error,
                ),
                onPressed: () => _removeItem(product.id!),
              ),
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