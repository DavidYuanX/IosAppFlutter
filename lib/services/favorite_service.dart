import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

/// 收藏服务
/// 使用本地存储管理用户的商品收藏
class FavoriteService {
  FavoriteService._internal();
  static final FavoriteService instance = FavoriteService._internal();

  static const _key = 'favorites';
  static const _maxCount = 100; // 最多保存100条记录

  List<Product> _favorites = [];
  List<VoidCallback> _listeners = [];

  List<Product> get favorites => List.unmodifiable(_favorites);

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// 加载收藏列表
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null || jsonStr.isEmpty) {
      _favorites = [];
      return;
    }
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      _favorites = list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _favorites = [];
    }
    _notifyListeners();
  }

  /// 保存收藏列表
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_favorites.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  /// 检查是否已收藏
  bool isFavorite(int productId) {
    return _favorites.any((p) => p.id == productId);
  }

  /// 添加收藏
  Future<void> add(Product product) async {
    if (product.id == null) return;
    if (isFavorite(product.id!)) return; // 已收藏则不重复添加

    _favorites.insert(0, product);

    if (_favorites.length > _maxCount) {
      _favorites = _favorites.sublist(0, _maxCount);
    }

    await _save();
    _notifyListeners();
  }

  /// 取消收藏
  Future<void> remove(int productId) async {
    _favorites.removeWhere((p) => p.id == productId);
    await _save();
    _notifyListeners();
  }

  /// 切换收藏状态
  /// 返回切换后的状态（true=已收藏，false=未收藏）
  Future<bool> toggle(Product product) async {
    if (product.id == null) return false;

    if (isFavorite(product.id!)) {
      await remove(product.id!);
      return false;
    } else {
      await add(product);
      return true;
    }
  }

  /// 清空所有收藏
  Future<void> clear() async {
    _favorites = [];
    await _save();
    _notifyListeners();
  }
}