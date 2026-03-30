# IosAppFlutter

Flutter 电商示例客户端，对接同仓库中的 `JavaService` 后端，包含首页、商品浏览、购物车、收藏、收货地址、订单和个人中心等页面。

## 项目定位

- 技术栈：Flutter 3、Dart 3、`http`、`shared_preferences`
- 目标平台：iOS、Android，同时保留了 Web/macOS/Windows/Linux 工程骨架
- 入口文件：`lib/main.dart`

## 页面与模块

- 首页：Banner、推荐商品
- 分类页：商品列表、搜索、分类筛选
- 商品详情页：加入购物车、收藏、浏览记录
- 购物车页：下单
- 订单页：订单列表、订单详情、状态更新
- 个人中心：地址管理、收藏、浏览记录
- 管理页：商品管理、Banner 管理、用户管理

## 目录说明

- `lib/config`：接口地址配置
- `lib/models`：数据模型
- `lib/services`：接口请求与本地持久化
- `lib/screens`：页面
- `lib/widgets`：复用组件

## 本地运行

### 1. 准备环境

- Flutter SDK
- Xcode 或 Android Studio
- 一个可访问 `JavaService` 的模拟器或真机环境

### 2. 配置后端地址

推荐使用 `--dart-define` 注入：

```bash
flutter run --dart-define=API_BASE_URL=http://你的后端地址:8080
```

如果没有传入 `API_BASE_URL`，应用会回退到 `lib/config/api_config.dart` 里的默认地址。

注意：

- iOS 模拟器通常不能直接使用 Android 模拟器那套 `10.0.2.2`
- 真机调试时要确保手机和后端所在机器网络互通
- 如果后端跑在本机，局域网 IP 往往比 `localhost` 更稳妥

### 3. 启动项目

```bash
flutter pub get
flutter run
```

或：

```bash
flutter run --dart-define=API_BASE_URL=http://你的后端地址:8080
```

## 登录与角色

- 登录态保存在 `shared_preferences`
- 角色字段由后端返回，客户端据此决定是否展示管理入口
- 管理能力展示在“我的”页面

## 快速体检结论

客户端结构清晰，适合继续扩展功能；当前主要风险不在页面层，而在“环境依赖写死”和“客户端展示权限不等于服务端真实授权”这两点上。

## 已发现的明显风险

### 1. 默认后端地址仍是局域网 IP

- 当前已支持通过 `--dart-define=API_BASE_URL=...` 覆盖地址
- 但默认回退值仍是 `http://192.168.22.58:8080`
- 风险：如果忘记传环境参数，换网络后仍可能联调失败
- 建议：后续继续补齐 dev/staging/prod 多环境配置

### 2. 管理页入口只依赖客户端角色判断

- 客户端会根据本地保存的 `role` 展示管理入口
- 风险：真正的权限控制必须依赖后端；如果后端没拦住，客户端隐藏按钮并不安全
- 建议：把客户端判断仅当作 UI 优化，权限以服务端为准

### 3. 错误提示较粗

- 当前已优先透传后端返回的 `error/message`
- 仍建议后端统一错误响应结构，方便前端稳定展示

### 4. 当前未完成本地静态检查验证

- 尝试执行 `flutter analyze` 时，Flutter 需要写本机缓存目录，当前沙箱权限下被阻止
- 结论：这一轮没有拿到完整静态检查结果

## 与后端的耦合点

- 认证接口：`/api/auth/**`
- 商品接口：`/api/products/**`
- 订单接口：`/api/orders/**`
- Banner 接口：`/api/banners/**`
- 用户接口：`/api/users/**`

所有接口统一封装在 `lib/services/api_service.dart`。

## 推荐下一步

- 继续补齐正式的多环境配置方案
- 再跑一次 `flutter analyze` 和真机联调验证
