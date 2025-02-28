import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/constants.dart';
import '../../models/brief_ai_tools/chat_competion/com_cc_resp.dart';
import '../../models/brief_ai_tools/chat_competion/com_cc_state.dart';
import 'voice_chat_bubble.dart';

class MessageItem extends StatelessWidget {
  final ChatMessage message;
  // 2024-07-26 是否头像在顶部
  // (默认头像在左右两侧，就像对话一样。如果在顶部，文本内容更宽一点)
  final bool isAvatarTop;

  // 2024-08-12 流式响应时，数据是逐步增加的，如果还在响应中加个符号
  final bool? isBotThinking;

  // 2024-08-18 是否显示模型名称
  final bool isShowModelLable;

  const MessageItem({
    super.key,
    required this.message,
    this.isAvatarTop = false,
    this.isBotThinking = false,
    this.isShowModelLable = false,
  });

  @override
  Widget build(BuildContext context) {
    // 根据是否是用户输入跳转文本内容布局
    bool isFromUser = message.role == CusRole.user.name ||
        message.role == CusRole.system.name;

    // 如果是用户输入，头像显示在右边
    CrossAxisAlignment crossAlignment =
        isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    // 所有的文字颜色，暂定用户蓝色AI黑色(系统角色为绿色)
    Color textColor = message.role == CusRole.user.name
        ? Colors.blue
        : message.role == CusRole.system.name
            ? Colors.green
            : Colors.black;

    /// 这里暂时不考虑外边框的距离，使用时在外面加padding之类的
    /// 如果头像在上方，那么头像和正文是两行放在一个column中
    /// 否则，就是头像和正文放在一个row中
    return isAvatarTop
        ? Column(
            crossAxisAlignment: crossAlignment,
            children: [
              /// 头像和时间戳
              _buildAvatarAndTimestamp(context, isFromUser, textColor),

              /// 消息内容
              Column(
                crossAxisAlignment: crossAlignment,
                children: [
                  // 消息正文
                  _buildMessageContent(context, textColor),
                  // 消息引用
                  if (message.quotes != null && message.quotes!.isNotEmpty)
                    ..._buildQuotes(context, message.quotes!),
                ],
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 头像，根据是否用户输入放在左边或右边
              if (!isFromUser) _buildAvatar(isFromUser),
              SizedBox(width: 3.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: crossAlignment,
                  children: [
                    /// 模型名
                    if (isShowModelLable && message.role != CusRole.user.name)
                      _buildModelLabel(context),

                    /// 时间戳
                    _buildTimestamp(context, textColor),

                    /// 消息正文
                    _buildMessageContent(context, textColor),

                    /// 消息引用
                    if (message.quotes != null && message.quotes!.isNotEmpty)
                      ..._buildQuotes(context, message.quotes!),
                  ],
                ),
              ),
              if (isFromUser) _buildAvatar(isFromUser),
            ],
          );
  }

  Widget _buildAvatarAndTimestamp(
      BuildContext context, bool isFromUser, Color textColor) {
    return MediaQuery(
      // 头像旁边的时间和模型标签(智能群聊时)不缩放，避免显示溢出
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1),
      ),
      child: SizedBox(
        height: 40.sp,
        child: Row(
          // 来自用户，头像在右边；不是来自用户头像在左边。对齐方向同理
          mainAxisAlignment:
              isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,

          children: [
            if (!isFromUser) _buildAvatar(isFromUser),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.sp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isShowModelLable && message.role != CusRole.user.name)
                    Text(
                      message.modelLabel ?? "<无模型名称>",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  Text(
                    DateFormat(constDatetimeFormat).format(message.dateTime),
                    style: TextStyle(fontSize: 12.sp, color: textColor),
                  ),
                ],
              ),
            ),
            if (isFromUser) _buildAvatar(isFromUser),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isFromUser) {
    return CircleAvatar(
      radius: 18.sp,
      backgroundColor: isFromUser ? Colors.lightBlue : Colors.grey,
      child: Icon(isFromUser ? Icons.person : Icons.code),
    );
  }

  Widget _buildModelLabel(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.sp),
      child: Text(
        message.modelLabel ?? "<无模型名称>",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
        textAlign: TextAlign.start,
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context, Color textColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.sp),
      child: Text(
        DateFormat(constDatetimeFormat).format(message.dateTime),
        style: TextStyle(fontSize: 12.sp, color: textColor),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, Color textColor) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(5.sp),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 显示对话正文内容
              MarkdownBody(
                data: message.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: textColor),
                ),
              ),
              // 如果是流式加载中，显示一个加载圈
              if (message.role != CusRole.user.name && isBotThinking == true)
                SizedBox(
                  width: 16.sp,
                  height: 16.sp,
                  child: CircularProgressIndicator(strokeWidth: 2.sp),
                ),
              // 如果是语音输入，显示语言文件，可点击播放
              // Text(message.contentVoicePath ?? ''),
              if (message.contentVoicePath != null &&
                  message.contentVoicePath!.trim() != "")
                VoiceWaveBubble(
                  path: message.contentVoicePath!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildQuotes(BuildContext context, List<CCQuote> quotes) {
    return List.generate(
      quotes.length,
      (index) => GestureDetector(
        onTap: () =>
            quotes[index].url != null ? _launchUrl(quotes[index].url!) : null,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 5.sp),
          child: Text(
            '${index + 1}. ${quotes[index].title}',
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).primaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }
}


// 如果是占位的消息，则显示转圈圈(2024-08-14 新设计应该没有了)
// ? Builder(
//     builder: (context) {
//       // RichText 组件允许在文本中嵌入其他小部件，并应用文本缩放因子。
//       // 因为richtext无法自动获取到缩放因子，所以需要手动获取全局的文本缩放因子
//       return RichText(
//         // 应用文本缩放因子
//         textScaler: MediaQuery.of(context).textScaler,
//         text: TextSpan(
//           children: [
//             TextSpan(
//               text: message.content,
//               style: const TextStyle(color: Colors.black),
//             ),
//             // 设置一个固定宽度，以确保 CircularProgressIndicator 不会占用太多空间
//             WidgetSpan(
//               child: SizedBox(
//                 width: 15.sp,
//                 height: 15.sp,
//                 child: CircularProgressIndicator(strokeWidth: 2.sp),
//               ),
//             ),
//           ],
//         ),
//       );
//     },
//   )