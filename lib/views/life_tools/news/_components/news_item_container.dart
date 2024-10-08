import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../common/components/tool_widget.dart';

class NewsItemContainer extends StatelessWidget {
  final int index;
  final String title;
  final String? trailingText;
  final String link;

  const NewsItemContainer({
    super.key,
    required this.index,
    required this.title,
    this.trailingText,
    required this.link,
  });

  void _launchUrl(String url) async {
    if (!url.startsWith("http") && !url.startsWith("https")) {
      url = "https:$url";
    }
    launchStringUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => _launchUrl(link),
          child: SizedBox(
            height: 56.sp,
            child: Row(
              children: [
                SizedBox(
                  width: 40.sp,
                  child: Text(
                    "$index",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                if (trailingText != null && trailingText!.isNotEmpty)
                  SizedBox(
                    width: 48.sp,
                    child: Text(
                      trailingText!,
                      style: TextStyle(
                        fontSize: 11.sp,
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                SizedBox(width: 10.sp),
              ],
            ),
          ),
        ),
        Divider(height: 1.sp),
      ],
    );
  }
}

/// 就是上面组价的函数形式
/// 自定义的比直接使用ListTile更紧凑点，其他没区别
Widget buildNewsItemContainer(
  BuildContext context,
  int index,
  String title,
  String? trailingText,
  String link,
) {
  return Column(
    children: [
      InkWell(
        onTap: () {
          // 2024-10-07 实测中关村在线的地址没有https开头
          var url = link;
          if (!url.startsWith("http") || !url.startsWith("https")) {
            url = "https:$url";
          }

          launchStringUrl(url);
        },
        child: SizedBox(
          height: 56.sp,
          child: Row(
            children: [
              SizedBox(
                width: 40.sp,
                child: Text(
                  "$index",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              if (trailingText != null && trailingText.isNotEmpty)
                SizedBox(
                  width: 48.sp,
                  child: Text(
                    trailingText,
                    style: TextStyle(
                      fontSize: 11.sp,
                      // color: Theme.of(context).disabledColor,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              SizedBox(width: 10.sp),
            ],
          ),
        ),
      ),
      Divider(height: 1.sp),
    ],
  );
}

/// 直接使用ListTile的新闻条目
Widget buildNewsItem(
  BuildContext context,
  int index,
  String title,
  String? trailingText,
  String link,
) {
  return Column(
    children: [
      ListTile(
        leading: Text(
          "$index",
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.orange,
          ),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).primaryColor,
          ),
        ),
        trailing: (trailingText != null && trailingText.isNotEmpty)
            ? SizedBox(
                width: 48.sp,
                child: Text(
                  trailingText,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        onTap: () {
          // 2024-10-07 实测中关村在线的地址没有https开头
          var url = link;
          if (!url.startsWith("http") || !url.startsWith("https")) {
            url = "https:$url";
          }

          launchStringUrl(url);
        },
      ),
      Divider(height: 1.sp),
    ],
  );
}
