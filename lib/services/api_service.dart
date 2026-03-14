import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/order.dart' as order_model;
import '../models/product.dart';
import '../models/user.dart';

class ApiError implements Exception {
  final String message;
  ApiError(this.message);

  @override
  String toString() => message;
}

/// 分页结果
class PaginatedResult<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int pageNumber;
  final bool last;

  PaginatedResult({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.pageNumber,
    required this.last,
  });
}

class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  final String _baseHost = ApiConfig.baseUrl;
  String get _usersBaseUrl => '$_baseHost/api/users';
  String get _authBaseUrl => '$_baseHost/api/auth';
  String get _productsBaseUrl => '$_baseHost/api/products';
  String get _ordersBaseUrl => '$_baseHost/api/orders';

  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'auth_username';
  static const _roleKey = 'auth_role';

  String? _token;
  String? _username;
  String? _role;

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _username = prefs.getString(_usernameKey);
    _role = prefs.getString(_roleKey);
  }

  Future<void> _saveAuth(String? token, [String? username, String? role]) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_roleKey);
    } else {
      await prefs.setString(_tokenKey, token);
      if (username != null) await prefs.setString(_usernameKey, username);
      if (role != null) await prefs.setString(_roleKey, role);
    }
    _token = token;
    _username = username ?? _username;
    _role = role ?? _role;
  }

  String? get currentUsername => _username;
  String? get currentRole => _role;

  bool get isAdmin => _role == 'ADMIN';

  Future<bool> isLoggedIn() async {
    if (_token == null) {
      await _loadToken();
    }
    return _token != null;
  }

  Future<void> logout() async {
    await _saveAuth(null);
  }

  Future<Map<String, String>> _headers({bool useAuth = true}) async {
    if (useAuth && _token == null) {
      await _loadToken();
    }
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (useAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<dynamic> _performRequest(
    Uri uri, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool useAuth = true,
    bool decodeJson = true,
  }) async {
    final headers = await _headers(useAuth: useAuth);

    http.Response response;
    try {
      switch (method) {
        case 'POST':
          response =
              await http.post(uri, headers: headers, body: jsonEncode(body));
          break;
        case 'PUT':
          response =
              await http.put(uri, headers: headers, body: jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          response = await http.get(uri, headers: headers);
      }
    } catch (_) {
      throw ApiError('网络异常，请检查网络后重试');
    }

    final statusCode = response.statusCode;
    if (statusCode == 401) {
      await logout();
      throw ApiError('用户名或密码错误，请重试');
    }
    if (statusCode < 200 || statusCode >= 300) {
      throw ApiError('服务器错误: $statusCode');
    }

    if (!decodeJson || response.body.isEmpty) {
      return null;
    }
    return jsonDecode(response.body);
  }

  Future<void> login(String username, String password) async {
    final uri = Uri.parse('$_authBaseUrl/login');
    final result = await _performRequest(
      uri,
      method: 'POST',
      body: {
        'username': username,
        'password': password,
      },
      useAuth: false,
    ) as Map<String, dynamic>;

    final token = result['token'] as String?;
    if (token == null) {
      throw ApiError('登录返回数据异常');
    }
    final role = result['role'] as String? ?? 'USER';
    await _saveAuth(token, username, role);
  }

  Future<void> register(String username, String password, String phone) async {
    final uri = Uri.parse('$_authBaseUrl/register');
    final result = await _performRequest(
      uri,
      method: 'POST',
      body: {
        'username': username,
        'password': password,
        'phone': phone,
      },
      useAuth: false,
    ) as Map<String, dynamic>;

    final token = result['token'] as String?;
    if (token == null) {
      throw ApiError('注册返回数据异常');
    }
    final role = result['role'] as String? ?? 'USER';
    await _saveAuth(token, username, role);
  }

  Future<List<User>> fetchUsers() async {
    final uri = Uri.parse(_usersBaseUrl);
    final result = await _performRequest(uri) as List<dynamic>;
    return result.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<User> fetchUser(int id) async {
    final uri = Uri.parse('$_usersBaseUrl/$id');
    final result = await _performRequest(uri) as Map<String, dynamic>;
    return User.fromJson(result);
  }

  Future<User> createUser(User user) async {
    final uri = Uri.parse(_usersBaseUrl);
    final result = await _performRequest(
      uri,
      method: 'POST',
      body: user.toJson(),
    ) as Map<String, dynamic>;
    return User.fromJson(result);
  }

  Future<User> updateUser(User user) async {
    final id = user.id;
    if (id == null) {
      throw ApiError('用户 ID 为空');
    }
    final uri = Uri.parse('$_usersBaseUrl/$id');
    final result = await _performRequest(
      uri,
      method: 'PUT',
      body: user.toJson(),
    ) as Map<String, dynamic>;
    return User.fromJson(result);
  }

  Future<void> deleteUser(int id) async {
    final uri = Uri.parse('$_usersBaseUrl/$id');
    await _performRequest(uri, method: 'DELETE', decodeJson: false);
  }

  Future<User> updateUserRole(int id, String role) async {
    final uri = Uri.parse('$_usersBaseUrl/$id/role');
    final result = await _performRequest(
      uri,
      method: 'PUT',
      body: {'role': role},
    ) as Map<String, dynamic>;
    return User.fromJson(result);
  }

  // ---- Products ----

  Future<PaginatedResult<Product>> fetchProductsPaginated({
    String? category,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    final uri = Uri.parse(_productsBaseUrl).replace(queryParameters: params);
    final result = await _performRequest(uri) as Map<String, dynamic>;
    return PaginatedResult<Product>(
      content: (result['content'] as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: result['totalElements'] as int,
      totalPages: result['totalPages'] as int,
      pageNumber: result['number'] as int,
      last: result['last'] as bool,
    );
  }

  Future<List<Product>> fetchProducts({String? category}) async {
    final params = <String, String>{};
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    final uri = Uri.parse('$_productsBaseUrl/all').replace(queryParameters: params.isEmpty ? null : params);
    final result = await _performRequest(uri) as List<dynamic>;
    return result.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product?> fetchProduct(int id) async {
    final uri = Uri.parse('$_productsBaseUrl/$id');
    final result = await _performRequest(uri) as Map<String, dynamic>;
    return Product.fromJson(result);
  }

  Future<List<String>> fetchProductCategories() async {
    final uri = Uri.parse('$_productsBaseUrl/categories');
    final result = await _performRequest(uri) as List<dynamic>;
    return result.cast<String>();
  }

  Future<Product> createProduct(Product product) async {
    final uri = Uri.parse(_productsBaseUrl);
    final result = await _performRequest(
      uri,
      method: 'POST',
      body: product.toJson(),
    ) as Map<String, dynamic>;
    return Product.fromJson(result);
  }

  Future<Product> updateProduct(Product product) async {
    final id = product.id;
    if (id == null) throw ApiError('商品 ID 为空');
    final uri = Uri.parse('$_productsBaseUrl/$id');
    final result = await _performRequest(
      uri,
      method: 'PUT',
      body: product.toJson(),
    ) as Map<String, dynamic>;
    return Product.fromJson(result);
  }

  Future<void> deleteProduct(int id) async {
    final uri = Uri.parse('$_productsBaseUrl/$id');
    await _performRequest(uri, method: 'DELETE', decodeJson: false);
  }

  Future<List<Product>> searchProducts(String keyword) async {
    final uri = Uri.parse('$_productsBaseUrl/search').replace(
      queryParameters: {'keyword': keyword},
    );
    final result = await _performRequest(uri) as List<dynamic>;
    return result.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---- Orders ----

  Future<order_model.Order> createOrder(List<order_model.OrderItem> items) async {
    final uri = Uri.parse(_ordersBaseUrl);
    final result = await _performRequest(
      uri,
      method: 'POST',
      body: {
        'items': items.map((e) => e.toJson()).toList(),
      },
    ) as Map<String, dynamic>;
    return order_model.Order.fromJson(result);
  }

  Future<List<order_model.Order>> fetchOrders({String? status}) async {
    final params = <String, String>{};
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    final uri = Uri.parse(_ordersBaseUrl)
        .replace(queryParameters: params.isEmpty ? null : params);
    final result = await _performRequest(uri) as List<dynamic>;
    return result
        .map((e) => order_model.Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<order_model.Order> fetchOrder(int id) async {
    final uri = Uri.parse('$_ordersBaseUrl/$id');
    final result = await _performRequest(uri) as Map<String, dynamic>;
    return order_model.Order.fromJson(result);
  }

  Future<order_model.Order> updateOrderStatus(int id, String status) async {
    final uri = Uri.parse('$_ordersBaseUrl/$id/status');
    final result = await _performRequest(
      uri,
      method: 'PUT',
      body: {'status': status},
    ) as Map<String, dynamic>;
    return order_model.Order.fromJson(result);
  }

  Future<void> cancelOrder(int id) async {
    final uri = Uri.parse('$_ordersBaseUrl/$id');
    await _performRequest(uri, method: 'DELETE', decodeJson: false);
  }
}

