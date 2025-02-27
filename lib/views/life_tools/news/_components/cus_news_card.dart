// 除了readhub热门话题那个有关联新闻、有时间线
// 其他的新闻预览卡片基本都可以使用这个可折叠栏卡片组件
// 布局基本为：标题、概要、图片?、作者?、来源、地址跳转
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../common/components/tool_widget.dart';

class CusNewsCard extends StatefulWidget {
  // 标题
  final String title;
  // 简述
  final String summary;
  // 标题图片
  final String? imageUrl;
  // 来源媒体
  final String source;
  // 虽然是作者栏位，但也可以是关键字、tag等其他内容
  final String? author;
  // 发表时间
  final String? publishedAt;
  // 新闻源链接
  final String url;
  // 包含折叠状态的列表
  final List<bool> isExpandedList;
  // 当前属于哪一个，用于获取当前新闻卡片的折叠状态
  final int index;

  const CusNewsCard({
    super.key,
    required this.title,
    required this.summary,
    this.imageUrl,
    required this.source,
    this.author,
    this.publishedAt,
    required this.url,
    required this.index,
    required this.isExpandedList,
  });

  @override
  State<CusNewsCard> createState() => _CusNewsCardState();
}

class _CusNewsCardState extends State<CusNewsCard> {
  bool get isExpanded => widget.isExpandedList[widget.index];

  void _onExpansionChanged(bool expanded) {
    setState(() {
      widget.isExpandedList[widget.index] = expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isExpanded ? 5 : 0,
      color: isExpanded ? null : Theme.of(context).canvasColor,
      shape: isExpanded
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
      child: ExpansionTile(
        showTrailingIcon: false,
        initiallyExpanded: isExpanded,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        onExpansionChanged: _onExpansionChanged,
        tilePadding: EdgeInsets.all(5.sp),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
                Container(
                  width: 100.sp,
                  padding: EdgeInsets.only(left: 5.sp),
                  height: 70.sp,
                  child: buildNetworkOrFileImage(
                    widget.imageUrl ?? '',
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 2.sp),
              child: RichText(
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: widget.publishedAt ?? "",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.sp,
                      ),
                    ),
                    // 虽然是作者栏位，但也可以是关键字、tag等其他内容
                    TextSpan(
                      text: "\t\t\t\t${widget.author ?? ''}",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                widget.summary,
                maxLines: isExpanded ? null : 2,
                overflow: isExpanded ? null : TextOverflow.ellipsis,
                style: TextStyle(
                  color: isExpanded ? null : Colors.black54,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
        children: [
          ListTile(
            title: Text(
              '来源: ${widget.source}',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Colors.blue,
                decorationThickness: 2.sp,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward,
              color: Theme.of(context).primaryColor,
            ),
            onTap: () => launchStringUrl(widget.url),
          ),
        ],
      ),
    );
  }
}
