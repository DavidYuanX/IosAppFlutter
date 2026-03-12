import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/user.dart';

class ApiError implements Exception {
  final String message;
  ApiError(this.message);

  @override
  String toString() => message;
}

class ApiService {
  ApiService._internal();
  static final ApiService instance = ApiService._internal();

  final String _baseHost = 'http://192.168.22.58:8080';
  String get _usersBaseUrl => '$_baseHost/api/users';
  String get _authBaseUrl => '$_baseHost/api/auth';
  String get _productsBaseUrl => '$_baseHost/api/products';

  static const _tokenKey = 'auth_token';

  String? _token;

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
    _token = token;
  }

  Future<bool> isLoggedIn() async {
    if (_token == null) {
      await _loadToken();
    }
    return _token != null;
  }

  Future<void> logout() async {
    await _saveToken(null);
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
    await _saveToken(token);
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

  // ---- Products ----

  Future<List<Product>> fetchProducts({String? category}) async {
    final params = <String, String>{};
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    final uri = Uri.parse(_productsBaseUrl).replace(queryParameters: params.isEmpty ? null : params);
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
}

