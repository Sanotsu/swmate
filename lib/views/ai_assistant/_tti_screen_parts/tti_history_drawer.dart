import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/components/tool_widget.dart';
import '../../../models/text_to_image/com_tti_state.dart';

///
/// tti 历史记录抽屉组件
///
class TtiHistoryDrawer extends StatelessWidget {
  final List<LlmTtiResult> text2ImageHistory;
  final Function(LlmTtiResult) onDelete;

  const TtiHistoryDrawer({
    super.key,
    required this.text2ImageHistory,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          SizedBox(
            // 调整DrawerHeader的高度
            height: 60.sp,
            child: DrawerHeader(
              decoration: BoxDecoration(color: Colors.lightGreen[100]),
              child: const Center(child: Text('文本生成图片记录')),
            ),
          ),
          ...(text2ImageHistory
              .map((e) => buildGestureItems(e, context))
              .toList()),
        ],
      ),
    );
  }

  /// 构建在对话历史中的对话标题列表
  Widget buildGestureItems(LlmTtiResult e, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();

        // 点击了指定文生图记录，弹窗显示缩略图
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("文本生成图片信息", style: TextStyle(fontSize: 18.sp)),
              content: SizedBox(
                height: 300.sp,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "正向提示词:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        e.prompt,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      const Text(
                        "反向提示词:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        e.negativePrompt ?? "无",
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      Divider(height: 5.sp),
                      Wrap(
                        children: List.generate(
                          e.imageUrls?.length ?? 0,
                          (index) => ElevatedButton(
                            onPressed: () => _launchUrl(e.imageUrls![index]),
                            child: Text('图片${index + 1}'),
                          ),
                        ).toList(),
                      ),
                      if (e.imageUrls != null && e.imageUrls!.isNotEmpty)
                        Wrap(
                          children: buildImageList(
                            context,
                            e.imageUrls!,
                            prefix: e.llmSpec?.platform.name,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text("确定"),
                ),
              ],
            );
          },
        );
      },
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 5.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${e.requestId.length > 6 ? e.requestId.substring(0, 6) : e.requestId} ${e.prompt.length > 10 ? e.prompt.substring(0, 10) : e.prompt}",
                      style: TextStyle(fontSize: 15.sp),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "创建时间:${e.gmtCreate} \n过期时间:${e.gmtCreate.add(const Duration(days: 1))}",
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
            ),
            _buildDeleteButton(e, context),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(LlmTtiResult e, BuildContext context) {
    return SizedBox(
      width: 40.sp,
      child: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("确认删除文生图记录:", style: TextStyle(fontSize: 18.sp)),
                content: Text("记录请求编号：\n${e.requestId}"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text("取消"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text("确定"),
                  ),
                ],
              );
            },
          ).then((value) async {
            if (value == true) {
              onDelete(e);
            }
          });
        },
        icon: Icon(
          Icons.delete,
          size: 16.sp,
          color: Theme.of(context).primaryColor,
        ),
        iconSize: 18.sp,
        padding: EdgeInsets.all(0.sp),
      ),
    );
  }
}

Future<void> _launchUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}
