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

#### 2024-08-09

- init: 构建了基础项目结构

#### 2024-08-10

- feat: 添加了基础的基于对话模型的“你问我答”模块(SSE 流式数据的处理还有 bug，待处理)。
- feat: 添加了基础的基于对话模型的“翻译助手”和“拍照翻译”模块(yi 的图像识别请求参数报错，原因不知)。

#### 2024-08-11

- 还在尝试处理 api 流式响应的结果
  - `common_cc_sse_apis.dart` 结果完整，但重复请求就会报 Bad state: Stream has already been listened to.
  - `common_cc_http_apis.dart` 模仿 sse 那个源码使用 http 库来处理 sse 数据，但 data 还是会存在不是 json 的情况
  - `common_cc_apis.dart` 基本能够解析到 yi-large-reg 的引用值了，data 好像也都是 json 了
    - 参看https://github.com/cfug/dio/issues/1279

#### 2024-08-12

- fix: 修正对话模型 API 请求流式响应和非流式响应时的相关错误，refactor:重构了“你问我答”和“拍照翻译”、“翻译助手”页面的部分代码，提高复用率。

#### 2024-08-13

- refactor: “文档总结”和“文档翻译”合并为“文档解读”功能页面。
- feat: “智能对话”部分添加了百度的免费模型。

### todo:

- 得到流式响应的数据的处理都非常相似，可以抽出来公共函数
- 考虑如何加入智能体，拍照翻译、翻译器、其他预设的角色，可以当作按钮放在上方；
- 能上传文件、上传图片的模型和功能待区分；文档解析要单独做。
