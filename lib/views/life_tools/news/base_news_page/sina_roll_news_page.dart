import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../../../apis/life_tools/news/sina_roll_news_apis.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/utils/dio_client/interceptor_error.dart';
import '../../../../common/utils/tools.dart';
import '../../../../models/life_tools/news/sina_roll_news_resp.dart';
import '../_components/cus_news_card.dart';
import 'base_news_page_state.dart';

List<CusLabel> sinaRollNewsCategorys = [
  CusLabel(cnLabel: "全部", value: 2509),
  CusLabel(cnLabel: "体育", value: 2512),
  CusLabel(cnLabel: "科技", value: 2515),
  CusLabel(cnLabel: "财经", value: 2516),
  CusLabel(cnLabel: "股市", value: 2517),
  CusLabel(cnLabel: "美股", value: 2518),
];

class SinaRollNewsPage extends StatefulWidget {
  const SinaRollNewsPage({super.key});

  @override
  State<SinaRollNewsPage> createState() => _SinaRollNewsPageState();
}

class _SinaRollNewsPageState
    extends BaseNewsPageState<SinaRollNewsPage, SinaRollNews> {
  @override
  List<CusLabel> getCategories() => sinaRollNewsCategorys;

  // isRefresh 是上下拉的时候的刷新，初始化进入页面时就为false，展示加载圈位置不一样
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
      SinaRollNewsResp htRst = await getSinaRollNewsList(
        lid: (selectedCategory.value as int),
        size: pageSize,
        page: currentPage,
      );

      if (!mounted) return;
      setState(() {
        if (currentPage == 1) {
          newsList = htRst.data ?? [];
        } else {
          newsList.addAll(htRst.data ?? []);
        }

        hasMore = pageSize * currentPage >= (htRst.total ?? 100) ? false : true;

        // 重新加载新闻列表都是未加载的状态
        isExpandedList = List.generate(newsList.length, (index) => false);
      });
    } on CusHttpException catch (e) {
      // API请求报错，显示报错信息
      // http连接相关的报错在拦截器就有弹窗报错了，这里暂时不显示了
      // showSnackMessage(context, e.cusMsg);
      debugPrint(e.toString());
    } catch (e) {
      EasyLoading.showError(e.toString());
      rethrow;
    } finally {
      setState(() {
        isRefresh ? isRefreshLoading = false : isLoading = false;
      });
    }
  }

  @override
  Widget buildNewsCard(SinaRollNews item, int index) {
    // 2024-11-08 根据接口返回结果，有标题图片可能是一个对象，无标题图片可能是一个空列表
    // 如果无标题图片、但有内容图片，就把内容图片第一张作为标题图片
    var img = item.img;
    if (img is Map) {
      img = img['u'];
    } else if (item.images != null && item.images!.isNotEmpty) {
      img = item.images!.first.u ?? '';
    } else {
      img = '';
    }

    return CusNewsCard(
      title: item.title ?? '',
      summary: item.intro ?? '',
      url: item.url ?? '',
      imageUrl: img,
      source: item.mediaName ?? '',
      author: item.keywords,
      // 源网页显示的是发布时间而不是修改时间
      publishedAt: formatTimestampToString(item.ctime),
      // ？？？这两个处理折叠栏状态的参数，可以想想办法其他处理操作
      index: index,
      isExpandedList: isExpandedList,
    );
  }

  @override
  String getAppBarTitle() => '新浪滚动新闻';

  @override
  String getInfoMessage() =>
      """数据来源：[新浪新闻中心滚动新闻](https://news.sina.com.cn/roll)\n\n不要频繁刷新，若侵权则请勿使用""";

  @override
  bool get showSearchBox => false;
}
