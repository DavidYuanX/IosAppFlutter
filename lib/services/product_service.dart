import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  List<String>? _cachedCategories;

  Future<List<String>> fetchCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;
    _cachedCategories = await ApiService.instance.fetchProductCategories();
    return _cachedCategories!;
  }

  void clearCategoryCache() => _cachedCategories = null;

  Future<List<Product>> fetchProducts({String? category}) {
    return ApiService.instance.fetchProducts(category: category);
  }

  Future<Product?> fetchProduct(int id) {
    return ApiService.instance.fetchProduct(id);
  }

  Future<List<Product>> searchProducts(String keyword) {
    return ApiService.instance.searchProducts(keyword);
  }
}
