# Changelog

All notable changes to this project will be documented in this file.

## 0.2.0-beta.1

- feat:
  - 大模型列表添加了[“无问芯穹”](https://docs.infini-ai.com/gen-studio/models/supported-models.html)平台中个人开发者免申请可用的模型。
    - [个人用户账户余额仅可用于 AIStudio 开发机，GenStudio 功能当前免费](https://docs.infini-ai.com/support/)
    - 可以限时免费体验最新 QWEN2.5 最高 72B 的模型。
  - “生活日常工具”添加了以下几个新模块：
    - **猫狗之家**：随机或指定猫猫狗狗的照片，并可以使用 AI 获取品种信息
      - 视觉大模型获取的结果仅供参考，实测零一万物"Yi-Vsion"、智谱"GLM-4V"、通义千问 "QwenVL-Max"中，千问识别最准确。
    - **WAIFU 图片**: 随机或指定类别获取 `waifu.pic` 或 `waifu.im` 站点的 waifu 图片。
      - 仅面向少量纯粹受众，如有不适请勿使用，与开发者无关。
    - **MAL 动漫排行**: 获取 MyAnimeList(MAL)站点中动漫排行榜信息、播放日历、动漫相关数据查询。
      - 暂时仅支持少量无需登录可查看使用的接口
    - **BGM 动漫资讯**: 获取 Bangumi(BGM)站点的播放日历、动漫相关数据查询。
      - 暂时仅支持少量无需登录可查看使用的接口
- fix:
  - 跟着 SiliconFlow 官方下架了一些模型后，移除相关图生图功能模块。

[0.2.0-beta.1 截图](_doc/changelog_pics/0.2.0-beta.1截图.png)

## v0.1.0-beta.1

首次打包版本，基本完成了预想的所有功能：

目前(2024-09-06)是兼容了百度、腾讯、阿里、智谱 AI、零一万物、SiliconFlow、讯飞 7 个平台的 92 个大模型(含重复) 的 API 调用。

基本完成以下功能:

- AI 智能助手
  - 智能对话
  - 智能多聊
  - 文档解读
  - 图片解读
  - 文本生图
  - 创意文字
  - 图片生图
  - 文生视频
- 生活日常工具
  - 极简记账
  - 随机菜品
