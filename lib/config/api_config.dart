/// API 配置
///
/// 优先使用 `--dart-define=API_BASE_URL=...` 注入后端地址。
class ApiConfig {
  /// API 基础地址
  ///
  /// 开发环境示例: 'http://192.168.22.58:8080'
  /// 生产环境示例: 'https://api.example.com'
  static const String defaultBaseUrl = 'http://192.168.22.58:8080';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );
}
