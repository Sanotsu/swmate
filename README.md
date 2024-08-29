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

#### 2024-08-14

- refactor: “拍照翻译”重构为“图片解读”，预设支持翻译、总结、分析功能。
  - 翻译、总结是预设提问单个响应，分析是可以追问多轮问答。
- refactor: 重构“文档解读”和“图片解读”为类似写法。
- refactor: 使用抽象类重构了“文档解读”和“图片解读”;fix:修复了一些细节。
- feat: 基本完成 SF 平台的文生图页面布局。
  - todo 后续考虑同平台同方式的，图生图、文生视频，也可以先依文生图构建抽象类。
  - todo 没有保存生成记录

#### 2024-08-16

- feat: 基本完成“文本生图”通用页面布局，目前可支持 sf 平台和通义万相切换。
- refactor: “文本生图”重构历史记录从抽屉到单独页面;修正一些细节。

#### 2024-08-17

- feat: “文本生图”添加了讯飞云的图片生成接口。
- feat: “智能对话”添加了讯飞云的 Spark Lite 模型接口。
- feat: “智能对话”添加了腾讯的混元 Lite 模型接口。

#### 2024-08-18

- feat: 补上“极简记账”、“随机菜品”模块，“用户设置”补上“备份恢复”页面(以上都未重构和优化)。
- feat: 补上了‘智能助手’的‘智能群聊’模块。

#### 2024-08-19

- feat: “文本生图”添加了阿里云上部署的 flux 服务的接口。

#### 2024-08-21

- feat: “智能助手”新增“创意文字”模块，使用了阿里云上部署的“wordart 锦书”服务的接口;fix:修改了应用图标。

#### 2024-08-22

- refactor: 使用抽象类重构“文本生图”页面和“创意文字”页面。

#### 2024-08-23

- feat: “智能助手”添加了 sf 平台的“图生图”模块;refactor:重构页面“文生生图”和“图片生图”统一为“图片生成”。
- feat: “智能助手”的“智能对话”添加了“预设角色”功能(可以选择一些自定义的 system prompt，但列表数据还未列示。)
- refactor:重构了功能模块入口卡片; feat: 完善了“智能助手”的“智能对话”的“预设角色”功能，添加了一部分 GPT 格式的系统提示词示例。

#### 2024-08-24

- fix: 调整图片生成页面的一些布局细节。

#### 2024-08-25

- refactor: 将自定义的模型信息存入 sqlite 数据库;两步生成图片的接口将任务编号存入数据库方便后续查询。

#### 2024-08-26

- refactor: 将预设的系统角色信息存入 sqlite 数据库;feat: 添加了系统角色管理页面(列表、新增、导入、删除等);文生图也可选中预设提示词。
- fix: 修复一些细节问题，整体功能基本完成。
  - 如果后续没有 tts api 的话，基本上就没有新功能了，都是些优化（还有模型和系统角色的 json 文件优化等）和修 bug 的工作了。

#### 2024-08-27

- feat: 添加了用户输入自己平台的密钥来启用付费模型的功能,并修改所有获取模型的地方先判断是否有用户密钥来决定是否展示付费模型。
- feat: “智能助手”的“智能对话”添加了智谱 AI 免费的 GLM4-FLASH 接口;添加可以通过 json 导入各个平台的密钥。

#### 2024-08-28

- refactor: 重构智能助手各个功能页面获取模型列表和系统角色的逻辑到父页面。

#### 2024-08-29

- refactor: 重构了部分下拉选择框样式，修正智能对话点击历史记录后当前平台和模型没有改变的问题。
- fix: 完善了一些细节，添加了更多的平台支持的付费模型规格数据，添加模型列表展示页面等。

### todo:

- （done）得到流式响应的数据的处理都非常相似，可以抽出来公共函数
- （done 一些）考虑如何加入系统角色，拍照翻译、翻译器、其他预设的角色，可以当作按钮放在上方；
- （done）能上传文件、上传图片的模型和功能待区分；文档解析要单独做。
- （done 文档和图片部分）智能对话和图片解读很多相似，拍照翻译和图片解读重复，文档解读和其他两个也类似
  - 分为 3 个页面因为功能区分，但通用的代码可以抽出来
- （done）阿里或其他文生图先提交 job,再查询 job 结果的接口,可以保存请求的 taskid,就算被意外中断了 job 状态查询,后续还能查到当时的结果
- 所有的平台和模型,都使用 json 文件,在首次启动 app 的时候导入,并说明内置模型类型,存入数据库.
  - 方便后续添加个人配置各个平台的 ak,使用更高级的付费接口
- （done）预设的一些对话模型的 system prompt 也存 json,也存数据库,后续用户可以自己添加.
  - 其他文生图的示例 prompt 也这样操作.
- 添加语音合成的功能(默认的 tts 可能效果不太好，还是想找个付费的)
- **检查是否有用户配置密钥这一步在智能助手主页完成，同时查询出支持的模型列表，传入子页面**
  - 既避免在内部去查，浪费一些逻辑，还能在无密钥时不显示一些付费的页面。
