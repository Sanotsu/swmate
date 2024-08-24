import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/db_tools/db_helper.dart';
import '../../../models/text_to_image/com_ig_state.dart';

///
/// 文生图、图生图、阿里云的艺术文字都可以通用这个图像生成历史记录
/// 但是需要传入指定页面文字和模型类型，方便查询数据时筛选
///
class ImageGenerationHistoryScreen extends StatefulWidget {
  final String lable;
  final LLModelType modelType;

  const ImageGenerationHistoryScreen({
    super.key,
    required this.lable,
    required this.modelType,
  });

  @override
  State<ImageGenerationHistoryScreen> createState() =>
      _ImageGenerationHistoryScreenState();
}

class _ImageGenerationHistoryScreenState
    extends State<ImageGenerationHistoryScreen> {
  final DBHelper dbHelper = DBHelper();
  // 最近对话需要的记录历史对话的变量
  List<LlmIGResult> imageGenerationHistory = [];

  @override
  void initState() {
    super.initState();
    getHistory();
  }

  getHistory() async {
    // 获取历史记录
    var a = await dbHelper.queryTextToImageResultList();

    setState(() {
      imageGenerationHistory =
          a.where((e) => e.llmSpec?.modelType == widget.modelType).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.lable}历史记录'),
      ),
      body: ListView.builder(
        itemCount: imageGenerationHistory.length,
        itemBuilder: (context, index) {
          return buildGestureItems(imageGenerationHistory[index], context);
        },
      ),
    );
  }

  /// 构建在对话历史中的对话标题列表
  Widget buildGestureItems(LlmIGResult e, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击了指定文生图记录，弹窗显示缩略图
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("${widget.lable}图片信息",
                  style: TextStyle(fontSize: 18.sp)),
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
                                prefix:
                                    "${e.llmSpec?.platform.name}_${e.llmSpec?.cusLlm.name}",
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

  Widget _buildDeleteButton(LlmIGResult e, BuildContext context) {
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
              imageGenerationHistory = b
                  .where((e) => e.llmSpec?.modelType == LLModelType.tti)
                  .toList();
            });
          }
        });
      },
      icon: Icon(Icons.delete, color: Theme.of(context).primaryColor),
      padding: EdgeInsets.all(0.sp),
    );
  }
}
