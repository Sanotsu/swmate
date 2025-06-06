// llm_utils.dart

// ignore_for_file: camel_case_types

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:uuid/uuid.dart';

import '../../apis/chat_completion/common_cc_apis.dart';
import '../constants/constants.dart';
import '../llm_spec/cus_brief_llm_model.dart';
import '../../models/brief_ai_tools/chat_competion/com_cc_resp.dart';
import '../../models/brief_ai_tools/chat_competion/com_cc_state.dart';

// 调用对话模型时，可能是处理单纯的聊天、文档解读、图片解读
// 不同的内容通用处理有一些差别
enum CC_SWC_TYPE {
  chat,
  doc,
  image,
}

///
/// 获取流式响应句柄
/// 通过已有的对话列表、选中的平台和模型、是否图片、是否流式响应等，获取API 自定义SSE响应
///
/// SWC - StreamWithCancel
Future<StreamWithCancel<ComCCResp>> getCCResponseSWC({
  required List<ChatMessage> messages,
  required CusBriefLLMSpec selectedLlmSpec,
  bool isStream = true,
  // 如果是图像理解，还需要图片文件、和图片解析出错的回调
  /// 目前文本对话、文档解读、图片解读都会调用这个函数
  /// 区分3者尽量简单一点:chat、doc、image
  CC_SWC_TYPE useType = CC_SWC_TYPE.chat,
  File? selectedImage,
  // 2024-09-13 也考虑可能直接传网络图片地址
  String? selectedImageUrl,
  // 图像理解但没图像的提示
  Function(String)? onNotImageHint,
  // 有图像但转base64报错
  Function(String)? onImageError,

  // 如果是文档解读，还需文档内容、和文档为空的出错的回调
  String? docContent,
  Function(String)? onNotDocHint,
}) async {
  // 正常的文本对话，将已有的消息处理成大模型的消息列表格式(构建查询条件时要删除占位的消息)
  List<CCMessage> msgs = messages
      .map(
        (e) => CCMessage(content: e.content, role: e.role),
      )
      .toList();

  // 如果是图像理解、但没有传入图片，模拟模型返回异常信息
  if (selectedImage == null &&
      selectedImageUrl == null &&
      useType == CC_SWC_TYPE.image) {
    var hintInfo = "图像理解模式下，必须选择图片";
    if (onNotImageHint != null) {
      onNotImageHint(hintInfo);
    } else {
      EasyLoading.showError(hintInfo);
    }

    return StreamWithCancel.empty();
  }

  // 如果是文档解析，但没有传入文档内容(文档解析提取文字部分在其他地方)，模拟模型返回异常信息
  if (useType == CC_SWC_TYPE.doc) {
    if ((docContent == null || docContent.isEmpty)) {
      var hintInfo = "文档解读模式下，必须输入文档内容";
      if (onNotDocHint != null) {
        onNotDocHint(hintInfo);
      } else {
        EasyLoading.showError(hintInfo);
      }
      return StreamWithCancel.empty();
    } else if (docContent.length > 8000) {
      var hintInfo = "文档内容太长(${docContent.length}字符)，暂不支持超过8000字符的文档处理，请谅解。";
      if (onNotDocHint != null) {
        onNotDocHint(hintInfo);
      } else {
        EasyLoading.showError(hintInfo);
      }
      return StreamWithCancel.empty();
    }
  }

  // 可能会出现不存在的图片路径，那边这里转base64就会报错，那么就弹窗提示一下
  try {
    // 如果图片解析，要对传入的对话参数做一些调整
    if (useType == CC_SWC_TYPE.image) {
      String? imageString = "";
      // 如果直接是图片文件，传base64
      if (selectedImage != null) {
        var tempBase64Str = base64Encode((await selectedImage.readAsBytes()));
        imageString = "data:image/jpeg;base64,$tempBase64Str";
      } else if (selectedImageUrl != null) {
        // 如果是图片地址，直接传地址
        imageString = selectedImageUrl;
      }

      messages.firstWhere((e) => e.role == CusRole.user.name);

      // 遍历消息，把第一个user信息替换成图片结构，后面的保留原本输入字符
      for (int i = 0; i < msgs.length; i++) {
        var e = msgs[i];

        // 找到并替换第一个满足条件的对象
        if (e.role == CusRole.user.name) {
          e.content = [
            {
              "type": "image_url",
              "image_url": {"url": imageString}
            },
            {"type": "text", "text": e.content},
          ];
          break; // 找到第一个满足条件的对象后退出循环
        }
      }
    }

    // 如果图片解析，要对传入的对话参数做一些调整
    if (useType == CC_SWC_TYPE.doc) {
      messages.firstWhere((e) => e.role == CusRole.user.name);

      // 遍历消息，把第一个user信息替换成图片结构，后面的保留原本输入字符
      for (int i = 0; i < msgs.length; i++) {
        var e = msgs[i];

        // 找到并替换第一个满足条件的对象(文档内容+用户输入)
        if (e.role == CusRole.user.name) {
          e.content = docContent! + e.content;
          break;
        }
      }
    }

    StreamWithCancel<ComCCResp> tempStream = await getCCRespWithCancel(
      msgs,
      selectedLlmSpec,
      stream: isStream,
    );

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
  // 百度的响应最后一条没有DONE关键字，我在处理流式响应时，完成的回调手动添加了DONE
  if (crb.cusText.contains('[DONE]')) {
    onStreamDone();
  } else {
    // 为了每次有消息都能更新页面状态
    setIsResponsing();

    // 更新响应文本
    // 2024-11-04 讯飞星火，虽然成功返回，还是会有message栏位，其他的是出错了才有该栏位
    // 所以需要判断该errorMsg的值
    if ((crb.errorMsg != null && crb.errorMsg?.toLowerCase() != "success") ||
        crb.tencentErrorMsg != null) {
      csMsg.content += """后台响应报错:
          \n\n错误代码: ${crb.errorCode ?? crb.tencentErrorMsg?.code}
          \n\n错误原因: ${crb.errorMsg ?? crb.tencentErrorMsg?.message}
          """;
      onStreamDone();
    } else {
      csMsg.content += crb.cusText;
    }

    // 更新token信息
    csMsg.promptTokens = (crb.usage?.promptTokens ?? 0);
    csMsg.completionTokens = (crb.usage?.completionTokens ?? 0);
    csMsg.totalTokens = (crb.usage?.totalTokens ?? 0);

    // 零一万物RAG 更新引用情况
    if (crb.choices != null &&
        crb.choices!.isNotEmpty &&
        crb.choices!.first.delta != null &&
        crb.choices!.first.delta?.quote != null) {
      csMsg.quotes = crb.choices!.first.delta!.quote!;
    }

    // GLM4 更新引用情况
    if (crb.webSearch != null) {
      // 要转成之前旧的CCQuote形式(因为在messageItem中已经订好了，暂时不改)
      csMsg.quotes = crb.webSearch!
          .map((e) => CCQuote(title: e.title, url: e.link))
          .toList();
    }

    // 滚动到最下方
    if (scrollToBottom != null) scrollToBottom();
  }
}

///
/// 流式响应时，都会先要一个空的占位对话消息实例
/// @modelLabel 2024-08-18 群聊的时候，需要保存每个对话的模型名称
///
ChatMessage buildEmptyAssistantChatMessage({String? modelLabel}) {
  return ChatMessage(
    messageId: const Uuid().v4(),
    role: CusRole.assistant.name,
    content: "",
    contentVoicePath: "",
    dateTime: DateTime.now(),
    modelLabel: modelLabel,
  );
}
