# Changelog

一些较大变更、新功能、bug 修复等记录放在此处，仅做参看的提交更新.

## 0.3.0-beta.1

- chore:
  - 更新开发环境到 flutter 3.24.4、Java 17, 以及更新相关依赖到最新
- refactor:
  - 将“生活日常工具”中模块划分为几个大类:
    - **实用工具**: 极简记账、随机菜品、猫狗之家、英英词典(新)
    - **图片动漫**: BGM 动漫资讯、MAL 动漫排行、WAIFU 图片
    - **摸鱼新闻(新)**: 摸摸鱼、每天 60 秒
    - **饮食健康(新)**: USDA 食品数据、Nutritionix 食品数据、热量计算器
- feat:
  - 在“生活日常工具”主页上方添加了每日一言
  - “生活日常工具”添加了以下几个新模块：
    - **英英词典**：使用 [freeDictionaryAPI](https://github.com/meetDeveloper/freeDictionaryAPI) 做的英英释义词典
      - 如果单词在 API 中查不到，可以使用“AI 翻译”通过大模型获取释义
    - **摸摸鱼**: 来源于 [摸摸鱼热榜](https://momoyu.cc/) 聚合新闻热点
    - **每天 60 秒**: [每天 60 秒图片](https://api.03c3.cn/api/zb) 展示最近热点新闻
    - **USDA 食品数据**: 来源于 [美国农业部(USDA)官方的食品数据](https://fdc.nal.usda.gov/api-guide.html)，可用“英文”进行搜索查询
      - 包含基础食品、品牌(美国)食品等 40 多万条数据
      - 目前用的"DEMO_KEY"作为 api_key，可自行申请替换
    - **Nutritionix 食品数据**: 来源于 [Nutritionix](https://www.nutritionix.com/business/api) 的食品营养素数据，可用“英文”进行搜索查询。
      - 号称“Largest Verified Nutrition Database”
        - 截止 2024-11-04，拥有“1,202,162 food items and growing!”
      - 可用自然语言查询食物摄入和运动消耗的预估热量
      - _**因为免费方案的限制，最好自行申请一个 api key，并在“智能助手”->“模型列表”->“平台密钥”处导入**_。
    - **热量计算器**: 基于 [Nutritionix API](https://www.nutritionix.com/business/api) 和 AI 大模型，预估用户输入的食品摄入或运动消耗的热量
      - 可中文或其他语言输入，AI 大模型翻译成英文后调用 Nutritionix API 得到预估热量数据。

[0.3.0-beta.1 新增内容截图](_doc/changelog_pics/0.3.0-beta.1新增内容截图.jpg)

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

[0.2.0-beta.1 新增内容截图](_doc/changelog_pics/0.2.0-beta.1新增内容截图.png)

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
