import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../../apis/news/newsapi_apis.dart';
import '../../../../common/constants.dart';
import '../../../../common/utils/dio_client/interceptor_error.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/news/news_api_resp.dart';
import '../_components/cus_news_card.dart';
import 'base_news_page_state.dart';

List<CusLabel> newsapiCategorys = [
  CusLabel(cnLabel: "新闻", value: "general"),
  CusLabel(cnLabel: "商业", value: "business"),
  CusLabel(cnLabel: "娱乐", value: "entertainment"),
  CusLabel(cnLabel: "健康", value: "health"),
  CusLabel(cnLabel: "科学", value: "science"),
  CusLabel(cnLabel: "体育", value: "sports"),
  CusLabel(cnLabel: "科技", value: "technology"),
];

class NewsApiPage extends StatefulWidget {
  const NewsApiPage({super.key});

  @override
  State<NewsApiPage> createState() => _NewsApiPageState();
}

class _NewsApiPageState
    extends BaseNewsPageState<NewsApiPage, NewsApiArticle> {
  // 获取分类
  @override
  List<CusLabel> getCategories() => newsapiCategorys;

  // 获取新闻数据
  @override
  Future<void> fetchNewsData({bool isRefresh = false}) async {
    if (isRefresh) {
      if (isRefreshLoading) return;
      setState(() {
        isRefreshLoading = true;
      });
    } else {
      if (isLoading) return;
      setState(() {
        isLoading = true;
      });
    }

    try {
      // 2024-11-06 为了简单点，有输入就是查询everything的接口，不输入就是热点
      NewsApiResp rst;
      if (query.isNotEmpty) {
        rst = await getNewsapiList(
          query: query,
          type: "everything",
          pageSize: pageSize,
          page: currentPage,
        );
      } else {
        // 如果查询条件为空，就自动关闭查询输入框，展示分类栏
        setState(() {
          isClickSearch = false;
        });

        rst = await getNewsapiList(
          category: (selectedCategory.value as String),
          pageSize: pageSize,
          page: currentPage,
        );
      }

      if (!mounted) return;
      setState(() {
        if (currentPage == 1) {
          newsList = rst.articles ?? [];
        } else {
          newsList.addAll(rst.articles ?? []);
        }

        // 结果中可能存存remove的内容，要过滤掉
        newsList = newsList.where((i) => i.title != "[Removed]").toList();

        // 2024-11-06 免费用户只能查看100条新闻(在这里就只有1页)
        hasMore = pageSize * currentPage >= 100 ? false : true;

        // 重新加载新闻列表都是未加载的状态
        isExpandedList = List.generate(newsList.length, (index) => false);
      });
    } on CusHttpException catch (e) {
      // API请求报错，显示报错信息
      // http连接相关的报错在拦截器就有弹窗报错了，这里暂时不显示了
      debugPrint(e.toString());
    } catch (e) {
      // 其他错误，可能有转型报错啥的，所以还是显示一下
      EasyLoading.showError(e.toString());
      rethrow;
    } finally {
      setState(() {
        isRefresh ? isRefreshLoading = false : isLoading = false;
      });
    }
  }

  @override
  Widget buildNewsCard(NewsApiArticle item, int index) {
    return CusNewsCard(
      title: item.title ?? '',
      summary: item.description ?? '',
      url: item.url ?? '',
      imageUrl: item.urlToImage ?? '',
      author: item.author,
      source: item.source?.name ?? item.source?.id ?? "",
      publishedAt: formatDateTimeString(item.publishedAt ?? ''),
      index: index,
      isExpandedList: isExpandedList,
    );
  }

  @override
  String getAppBarTitle() => 'NewsAPI新闻';

  @override
  String getInfoMessage() => """数据来源：[NewsAPI](https://newsapi.org/)
\n目前为免费订阅版本，该API不完全限制如下：
- **国内无法直接访问**
- 新闻滞后24小时
- 新闻搜索区间最近1个月内
- 每天累计请求上限100次
- 每个请求数据上限100条""";

  @override
  bool get showSearchBox => true;
}
