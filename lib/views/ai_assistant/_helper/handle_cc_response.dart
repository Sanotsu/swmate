// llm_utils.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:uuid/uuid.dart';

import '../../../apis/chat_completion/common_cc_apis.dart';
import '../../../common/llm_spec/cc_spec.dart';
import '../../../models/chat_competion/com_cc_resp.dart';
import '../../../models/chat_competion/com_cc_state.dart';

///
/// 获取流式响应句柄
/// 通过已有的对话列表、选中的平台和模型、是否图片、是否流式响应等，获取API 自定义SSE响应
///
/// SWC - StreamWithCancel
Future<StreamWithCancel<ComCCResp>> getCCResponseSWC({
  required List<ChatMessage> messages,
  required ApiPlatform selectedPlatform,
  required String selectedModel,
  bool isStream = true,
  // 如果是图像理解，还需要图片文件、和图片解析出错的回调
  bool isVision = false,
  File? selectedImage,
  // 图像理解但没图像的提示
  Function(String)? onNotImageHint,
  // 有图像但转base64报错
  Function(String)? onImageError,
}) async {
  // 将已有的消息处理成大模型的消息列表格式(构建查询条件时要删除占位的消息)
  List<CCMessage> msgs = messages
      .map(
        (e) => CCMessage(content: e.content, role: e.role),
      )
      .toList();

  // 如果是图像理解、但没有传入图片，模拟模型返回异常信息
  if (selectedImage == null && isVision) {
    var hintInfo = "图像理解模式下，必须选择图片";
    if (onNotImageHint != null) {
      onNotImageHint(hintInfo);
    } else {
      EasyLoading.showError(hintInfo);
    }

    // return StreamWithCancel<ComCCResp>(const Stream.empty(), () async {});
    return StreamWithCancel.empty();
  }

  // 可能会出现不存在的图片路径，那边这里转base64就会报错，那么就弹窗提示一下
  try {
    if (isVision) {
      var tempBase64Str = base64Encode((await selectedImage!.readAsBytes()));
      String? imageBase64String = "data:image/jpeg;base64,$tempBase64Str";

      msgs = messages
          .map((e) => CCMessage(
                content: (e.role == "assistant")
                    ? e.content
                    // 这里不能直接是String，但不必新搞一个类，直接拼接json
                    : [
                        {
                          "type": "image_url",
                          "image_url": {"url": imageBase64String}
                        },
                        {"type": "text", "text": e.content},
                      ],
                role: e.role,
              ))
          .toList();
    }

    StreamWithCancel<ComCCResp> tempStream;
    if (selectedPlatform == ApiPlatform.lingyiwanwu) {
      tempStream = await lingyiwanwuCCRespWithCancel(
        msgs,
        model: selectedModel,
        stream: isStream,
      );
    } else {
      tempStream = await siliconFlowCCRespWithCancel(
        msgs,
        model: selectedModel,
        stream: isStream,
      );
    }

    return tempStream;
  } catch (e) {
    if (onImageError != null) {
      onImageError(e.toString());
    } else {
      EasyLoading.showError(e.toString());
    }

    // return StreamWithCancel<ComCCResp>(const Stream.empty(), () async {});
    return StreamWithCancel.empty();
  }
}

///
/// 处理流式响应数据
///
void handleCCResponseSWC({
  required StreamWithCancel<ComCCResp> swc,
  required Function(ComCCResp) onData,
  required Function() onDone,
  required Function(Object) onError,
}) {
  swc.stream.listen(
    (crb) {
      onData(crb);
    },
    onDone: onDone,
    onError: onError,
  );
}

///
/// handleCCResponseSWC 中通用的 onData 处理逻辑
///
void commonOnDataHandler({
  required ComCCResp crb,
  required ChatMessage csMsg,
  // 当响应完成时，需要做的操作(流式和非流式的操作内容是一样的，但位置不同)
  required Function() onStreamDone,
  // 流式处理，每更新一点，就要滚动一下到底部
  Function()? scrollToBottom,
  // 在响应进行中，时刻保持当前为机器响应状态
  required Function() setIsResponsing,
}) {
  if (crb.cusText == '[DONE]') {
    onStreamDone();
  } else {
    // 为了每次有消息都能更新页面状态
    setIsResponsing();

    // 更新响应文本
    csMsg.content += crb.cusText;
    // csMsg!.content = crb.content ?? "";

    // 更新token信息
    csMsg.promptTokens = (crb.usage?.promptTokens ?? 0);
    csMsg.completionTokens = (crb.usage?.completionTokens ?? 0);
    csMsg.totalTokens = (crb.usage?.totalTokens ?? 0);

    // 更新引用情况
    if (crb.choices != null &&
        crb.choices?.first != null &&
        crb.choices?.first.delta != null &&
        crb.choices!.first.delta?.quote != null) {
      csMsg.quotes = crb.choices!.first.delta!.quote!;
    }

    // 滚动到最下方
    if (scrollToBottom != null) scrollToBottom();
  }
}

///
/// 流式响应时，都会先要一个空的占位对话消息实例
///
buildEmptyAssistantChatMessage() {
  return ChatMessage(
    messageId: const Uuid().v4(),
    role: "assistant",
    content: "",
    contentVoicePath: "",
    dateTime: DateTime.now(),
  );
}
