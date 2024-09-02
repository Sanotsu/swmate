import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../common/constants.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/db_tools/db_helper.dart';
import '../../../models/text_to_image/com_ig_state.dart';
import 'igvg_history_detail.dart';

///
/// 文生图、图生图、阿里云的艺术文字都可以通用这个图像生成历史记录
/// 但是需要传入指定页面文字和模型类型，方便查询数据时筛选
/// 2024-09-02 文生视频也用这个
///
class IGVGHistoryScreen extends StatefulWidget {
  final String lable;
  final LLModelType modelType;
  // 2024-09-02 区分ig和vg，不同未完成执行的操作不一样(目前只有阿里云和智谱是先job再查询job，后面更多的话要抽出来)

  const IGVGHistoryScreen({
    super.key,
    required this.lable,
    required this.modelType,
  });

  @override
  State<IGVGHistoryScreen> createState() => _IGVGHistoryScreenState();
}

class _IGVGHistoryScreenState extends State<IGVGHistoryScreen> {
  final DBHelper dbHelper = DBHelper();
  // 最近对话需要的记录历史对话的变量
  List<LlmIGVGResult> imageGenerationHistory = [];

  @override
  void initState() {
    super.initState();
    getHistory();
  }

  getHistory() async {
    // 获取历史记录
    var a = await dbHelper.queryIGVGResultList();

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
      body: imageGenerationHistory.isEmpty
          ? const Center(child: Text("暂无数据"))
          : ListView.builder(
              itemCount: imageGenerationHistory.length,
              itemBuilder: (context, index) {
                return buildGestureItems(
                    imageGenerationHistory[index], context);
              },
            ),
    );
  }

  /// 构建在对话历史中的对话标题列表
  Widget buildGestureItems(LlmIGVGResult e, BuildContext context) {
    return GestureDetector(
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IGVGHistoryDetail(
              igvg: e,
              label: widget.lable,
            ),
          ),
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
                    Text("是否完成: ${e.isFinish}"),
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

  Widget _buildDeleteButton(LlmIGVGResult e, BuildContext context) {
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
            await dbHelper.deleteIGVGResultById(e.requestId);

            // 然后重新查询并更新
            var b = await dbHelper.queryIGVGResultList();
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
