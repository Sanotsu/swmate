# SWMate

Smart Work Mate

一个包含极简的记账、幸运转盘随机菜品的日常生活工具，和使用 AI 大模型为基础的智能助手类 flutter 应用。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

```sh
flutter pub add json_annotation dev:build_runner dev:json_serializable

dart run build_runner build --delete-conflicting-outputs
```

### 各种修改国内镜像

- 配置 gradle
  - https://juejin.cn/post/7299346813261676544
- 修改 flutter 库中的仓库
  - https://juejin.cn/post/7348289379054223399
- Flutter 升级 Gradle 和 Gradle Plugin
  - https://www.cnblogs.com/inexbot/p/17593347.html

### dev log

- 2024-08-11
  - 还在尝试处理 api 流式响应的结果
    - `common_cc_sse_apis.dart` 结果完整，但重复请求就会报 Bad state: Stream has already been listened to.
    - `common_cc_http_apis.dart` 模仿 sse 那个源码使用 http 库来处理 sse 数据，但 data 还是会存在不是 json 的情况
    - `common_cc_apis.dart` 基本能够解析到 yi-large-reg 的引用值了，data 好像也都是 json 了
      - 参看https://github.com/cfug/dio/issues/1279
