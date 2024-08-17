import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/llm_spec/cus_llm_spec.dart';
import '../../../../common/utils/db_tools/db_helper.dart';
import '../../../../models/text_to_image/com_tti_state.dart';

class TtiHistoryScreen extends StatefulWidget {
  const TtiHistoryScreen({super.key});

  @override
  State<TtiHistoryScreen> createState() => _TtiHistoryScreenState();
}

class _TtiHistoryScreenState extends State<TtiHistoryScreen> {
  final DBHelper dbHelper = DBHelper();
  // 最近对话需要的记录历史对话的变量
  List<LlmTtiResult> text2ImageHistory = [];

  @override
  void initState() {
    super.initState();
    getHistory();
  }

  getHistory() async {
    // 获取历史记录
    var a = await dbHelper.queryTextToImageResultList();

    setState(() {
      text2ImageHistory = a;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文本生图历史记录'),
      ),
      body: ListView.builder(
        itemCount: text2ImageHistory.length,
        itemBuilder: (context, index) {
          return buildGestureItems(text2ImageHistory[index], context);
        },
      ),
    );
  }

  /// 构建在对话历史中的对话标题列表
  Widget buildGestureItems(LlmTtiResult e, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击了指定文生图记录，弹窗显示缩略图
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("文本生成图片信息", style: TextStyle(fontSize: 18.sp)),
              content: SizedBox(
                height: 250.sp,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (e.llmSpec?.platform != null)
                        Text("平台: ${CP_NAME_MAP[e.llmSpec?.platform]}"),

                      if (e.llmSpec?.cusLlm.name != null)
                        Text("模型: ${e.llmSpec?.name}"),

                      SizedBox(height: 10.sp),
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

                      SizedBox(height: 10.sp),
                      // 直接预览
                      Text(
                        "直接预览 ",
                        style: TextStyle(fontSize: 15.sp),
                      ),
                      Text(
                        "原始宽高比,点击缩放,长按保存",
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      (e.imageUrls != null && e.imageUrls!.isNotEmpty)
                          ? Wrap(
                              children: buildImageList(
                                context,
                                e.imageUrls!,
                                prefix: e.llmSpec?.platform.name,
                              ),
                            )
                          : const Text("暂无可预览图片"),
                      // SizedBox(height: 20.sp),
                      // Text(
                      //   "点击按钮去浏览器下载查看",
                      //   style: TextStyle(fontSize: 15.sp),
                      // ),
                      // if (e.imageUrls != null && e.imageUrls!.isNotEmpty)
                      //   Wrap(
                      //     spacing: 5.sp,
                      //     children: List.generate(
                      //       e.imageUrls!.length,
                      //       (index) => ElevatedButton(
                      //         // 尽量弹窗中一排4个按钮
                      //         style: ElevatedButton.styleFrom(
                      //           minimumSize: Size(52, 26.sp),
                      //           padding: EdgeInsets.all(0.sp),
                      //           shape: RoundedRectangleBorder(
                      //             borderRadius: BorderRadius.circular(5.sp),
                      //           ),
                      //         ),
                      //         // 假设url一定存在的
                      //         onPressed: () =>
                      //             launchStringUrl(e.imageUrls![index]),
                      //         child: Text(
                      //           '图片${index + 1}',
                      //           style: TextStyle(fontSize: 12.sp),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
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
                      // uuid,第9位正好是破折号
                      "${e.requestId.length > 8 ? e.requestId.substring(0, 8) : e.requestId} ${e.prompt.length > 10 ? e.prompt.substring(0, 10) : e.prompt}",
                      style: TextStyle(fontSize: 15.sp),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10.sp),
                    if (e.llmSpec?.platform != null)
                      Text("平台:${CP_NAME_MAP[e.llmSpec?.platform]}"),
                    if (e.llmSpec?.cusLlm.name != null)
                      Text("模型:${e.llmSpec?.name}"),
                    Text(
                      "创建时间:${DateFormat(constDatetimeFormat).format(e.gmtCreate)}",
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    Text(
                      "过期时间:${DateFormat(constDatetimeFormat).format(e.gmtCreate.add(const Duration(days: 1)))}",
                      style: TextStyle(fontSize: 13.sp),
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
    return IconButton(
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
            // 先删除
            await dbHelper.deleteTextToImageResultById(e.requestId);

            // 然后重新查询并更新
            var b = await dbHelper.queryTextToImageResultList();
            setState(() {
              text2ImageHistory = b;
            });
          }
        });
      },
      icon: Icon(Icons.delete, color: Theme.of(context).primaryColor),
      padding: EdgeInsets.all(0.sp),
    );
  }
}
