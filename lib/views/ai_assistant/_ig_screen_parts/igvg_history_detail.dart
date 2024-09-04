import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants.dart';
import '../../../common/llm_spec/cus_llm_spec.dart';
import '../../../common/utils/db_tools/db_helper.dart';
import '../../../models/text_to_image/aliyun_tti_resp.dart';
import '../../../models/text_to_image/com_ig_state.dart';
import '../../../models/text_to_video/cogvideox_resp.dart';
import '../_componets/loading_overlay.dart';
import '../ai_tools/image_generation/base_ig_screen_state.dart';
import '../ai_tools/video_generation/cogvideox_index.dart';

///
/// 文生图、图生图、阿里云的艺术文字都可以通用这个图像生成历史记录
/// 但是需要传入指定页面文字和模型类型，方便查询数据时筛选
///
class IGVGHistoryDetail extends StatefulWidget {
  final LlmIGVGResult igvg;

  final String label;

  const IGVGHistoryDetail({
    super.key,
    required this.igvg,
    required this.label,
  });

  @override
  State<IGVGHistoryDetail> createState() => _IGVGHistoryDetailState();
}

class _IGVGHistoryDetailState extends State<IGVGHistoryDetail> {
  final DBHelper dbHelper = DBHelper();
  // 最近对话需要的记录历史对话的变量
  late LlmIGVGResult currentIgvg;

  @override
  void initState() {
    super.initState();

    getIGVGData();
  }

  getIGVGData() async {
    // CogVideoXResp? result = await timedVideoGenerationTaskStatus(
    //   "168017208620522638991735689073393514",
    //   () => setState(() {
    //     LoadingOverlay.hide();
    //   }),
    // );

    // print(result?.toRawJson());

    // 将传入的数据赋值
    currentIgvg = widget.igvg;

    // 如果历史记录中图片和视频没有得到结果，那来到详情页继续获取
    if (currentIgvg.isFinish == false) {
      // 因为不同平台的不同task查询返回的结构不一样，但存入数据库的操作相似
      // 所以这里放好一些通用变量来处理存入数据库的栏位
      String? errorCode;
      String? errorMsg;
      List<String> imageUrls = [];
      List<String> coverUrls = [];
      List<String> videoUrls = [];

      // 智谱的文生视频
      if (currentIgvg.llmSpec?.cusLlm == CusLLM.zhipu_CogVideoX_TTV) {
        CogVideoXResp? result = await timedVideoGenerationTaskStatus(
          currentIgvg.taskId!,
          () => setState(() {
            LoadingOverlay.hide();
          }),
        );

        // 错误信息
        errorCode = result?.error?.code;
        errorMsg = result?.error?.message;
        // 视频及其封面信息
        var a = result?.videoResult;
        if (a != null && a.isNotEmpty) {
          for (var e in a) {
            coverUrls.add(e.coverImageUrl);
            videoUrls.add(e.url);
          }
        }
      } else {
        // 2024-09-02 目前除了智谱的文生视频外，就只有阿里云上获取文生图是单独的提交task和查询task了
        // 后续还有的时候，再更新通用方法
        AliyunTtiResp? result = await timedImageGenerationTaskStatus(
          currentIgvg.taskId!,
          () => setState(() {
            LoadingOverlay.hide();
          }),
        );

        // 错误信息
        errorCode = result?.code;
        errorMsg = result?.message;
        // 图片信息
        var a = result?.output.results;
        if (a != null && a.isNotEmpty) {
          for (var e in a) {
            if (e.url != null) imageUrls.add(e.url!);
            if (e.pngUrl != null) imageUrls.add(e.pngUrl!);
          }
        }
      }

      // 如果查询进度有错，则删除该任务数据，并弹窗提示
      if (!context.mounted) return;
      if (errorCode != null) {
        setState(() {
          LoadingOverlay.hide();
        });

        await dbHelper.deleteIGVGResultById(currentIgvg.requestId);

        if (!mounted) return;
        return commonExceptionDialog(
          context,
          "发生异常",
          "该任务出现异常，无法查询进度：${errorMsg ?? ''}",
        );
      }

      // 没有错，那就是查到结果了，更新当前历史记录
      setState(() {
        currentIgvg = LlmIGVGResult(
          requestId: currentIgvg.requestId,
          prompt: currentIgvg.prompt,
          negativePrompt: currentIgvg.negativePrompt,
          taskId: currentIgvg.taskId,
          isFinish: true,
          style: currentIgvg.style,
          imageUrls: imageUrls,
          videoCoverImageUrls: coverUrls,
          videoUrls: videoUrls,
          gmtCreate: DateTime.now(),
          llmSpec: currentIgvg.llmSpec,
          modelType: currentIgvg.modelType,
        );
      });

      await dbHelper.updateIGVGResultById(currentIgvg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.label}详情'),
      ),
      body: Container(
        // height: MediaQuery.of(context).size.height / 4 * 3,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15.sp),
            topRight: Radius.circular(15.sp),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                // 模型表格，用Table和DataTable全看洗好，都留着
                child: Padding(
                  padding: EdgeInsets.all(5.sp),
                  child: buildDetailColumn(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildDetailColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentIgvg.modelType != LLModelType.ttv &&
            currentIgvg.imageUrls != null &&
            currentIgvg.imageUrls!.isNotEmpty)
          Wrap(
            children: buildImageResult(
              context,
              currentIgvg.imageUrls!,
              "${currentIgvg.llmSpec?.platform.name}_${currentIgvg.llmSpec?.name}",
            ),
          ),
        if (currentIgvg.modelType == LLModelType.ttv &&
            currentIgvg.videoCoverImageUrls != null &&
            currentIgvg.videoCoverImageUrls!.isNotEmpty &&
            currentIgvg.videoUrls != null &&
            currentIgvg.videoUrls!.isNotEmpty)
          Wrap(
            children: buildVideoResult(
              currentIgvg.videoUrls!,
              currentIgvg.videoCoverImageUrls!,
            ),
          ),

        /// 将生成的信息放在下方，因为可能长度很多，要滚动才能显示完整，但图片和视频就最多一行，高度比较固定
        Table(
          // 设置表格边框
          border: TableBorder.all(
            color: Theme.of(context).disabledColor,
          ),
          // 设置每列的宽度占比
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(7),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // 基础栏位
            _buildTableRow(
                "平台", CP_NAME_MAP[currentIgvg.llmSpec?.platform] ?? ""),
            _buildTableRow("模型", currentIgvg.llmSpec?.name ?? ""),
            _buildTableRow("任务类型", MT_NAME_MAP[currentIgvg.modelType] ?? ""),
            _buildTableRow("任务编号", currentIgvg.taskId ?? ""),
            _buildTableRow("是否完成", currentIgvg.isFinish.toString()),
            _buildTableRow("风格", currentIgvg.style ?? ""),
            _buildTableRow("创建时间",
                DateFormat(constDatetimeFormat).format(currentIgvg.gmtCreate)),

            _buildTableRow("正向提示词", currentIgvg.prompt),
            _buildTableRow("反向提示词", currentIgvg.negativePrompt ?? ""),
            _buildTableRow("参考图地址", currentIgvg.refImageUrls?.join(",") ?? ""),
          ],
        ),
      ],
    );
  }

  _buildTableRow(String label, String value, {Color? color}) {
    return TableRow(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Padding(
          padding: EdgeInsets.only(left: 5.sp),
          child: Text(
            value,
            style: TextStyle(color: color),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}
