import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../utils/tools.dart';

/// 构建AI对话云平台入口按钮
buildToolEntrance(
  String label, {
  String? subtitle,
  Icon? icon,
  Color? color,
  void Function()? onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      // padding: EdgeInsets.all(2.sp),
      decoration: BoxDecoration(
        // 设置圆角半径为10
        borderRadius: BorderRadius.all(Radius.circular(15.sp)),
        color: color ?? Colors.teal[200],
        // 添加阴影效果
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // 阴影颜色
            spreadRadius: 2, // 阴影的大小
            blurRadius: 5, // 阴影的模糊程度
            offset: Offset(0, 2.sp), // 阴影的偏移量
          ),
        ],
      ),
      child: Center(
        child: ListTile(
          // dense: true,
          leading: icon ?? const Icon(Icons.chat, color: Colors.blue),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 20.sp,
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  // style: TextStyle(fontSize: 15.sp, color: Colors.grey),
                  maxLines: 10,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                )
              : null,
        ),
      ),
    ),
  );
}

// 绘制转圈圈
Widget buildLoader(bool isLoading) {
  if (isLoading) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  } else {
    return Container();
  }
}

commonHintDialog(
  BuildContext context,
  String title,
  String message, {
  double? msgFontSize,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(
          message,
          style: TextStyle(fontSize: msgFontSize ?? 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("确定"),
          ),
        ],
      );
    },
  );
}

commonMarkdwonHintDialog(
  BuildContext context,
  String title,
  String message, {
  double? msgFontSize,
}) async {
  unfocusHandle();
  // 强行停200毫秒(100还不够)，密码键盘未收起来就显示弹窗出现布局溢出的问题
  // 上面直接的commonHintDialog没问题，这里主要是MarkdownBody的问题
  await Future.delayed(const Duration(milliseconds: 200));

  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: MarkdownBody(
          data: message,
          selectable: true,
          // 设置Markdown文本全局样式
          styleSheet: MarkdownStyleSheet(
            // 普通段落文本颜色(假定用户输入就是普通段落文本)
            p: const TextStyle(color: Colors.black),
            // ... 其他级别的标题样式
            // 可以继续添加更多Markdown元素的样式
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("确定"),
          ),
        ],
      );
    },
  );
}

// 显示底部提示条(默认都是出错或者提示的)
void showSnackMessage(
  BuildContext context,
  String message, {
  Color? backgroundColor = Colors.red,
}) {
  var snackBar = SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 3),
    backgroundColor: backgroundColor,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

/// 构建文本生成的图片结果列表
/// 点击预览，长按下载
buildNetworkImageViewGrid(
  BuildContext context,
  List<String> urls, {
  int? crossAxisCount,
  String? prefix, // 如果有保存图片，这个可以是图片明前缀
}) {
  return GridView.count(
    crossAxisCount: crossAxisCount ?? 2,
    shrinkWrap: true,
    mainAxisSpacing: 5.sp,
    crossAxisSpacing: 5.sp,
    physics: const NeverScrollableScrollPhysics(),
    children: buildImageList(context, urls, prefix: prefix),
  );
}

// 在photovivew中，不同图片不同的provider
ImageProvider _getImageProvider(String imagePath) {
  if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
    return NetworkImage(imagePath);
  } else {
    return FileImage(File(imagePath));
  }
}

_buildPhotoView(ImageProvider imageProvider, {bool? enableRotation}) {
  return PhotoView(
    imageProvider: imageProvider,
    // 设置图片背景为透明
    backgroundDecoration: const BoxDecoration(
      color: Colors.transparent,
    ),
    // 可以旋转
    enableRotation: enableRotation ?? true,
    // 缩放的最大最小限制
    minScale: PhotoViewComputedScale.contained * 0.8,
    maxScale: PhotoViewComputedScale.covered * 2,
    errorBuilder: (context, url, error) => const Icon(Icons.error),
  );
}

// 2024-06-27 在小米6中此放在上面imageViewGrid没问题，但Z60U就报错；因为无法调试，错误原因不知
// 所以在文生图历史记录中点击某个记录时，不使用上面那个，而使用这个
buildImageList(
  BuildContext context,
  List<String> urls, {
  String? prefix,
}) {
  return List.generate(urls.length, (index) {
    return GridTile(
      child: GestureDetector(
        // 单击预览
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent, // 设置背景透明
                child: _buildPhotoView(_getImageProvider(urls[index])),
              );
            },
          );
        },
        // 长按保存到相册
        onLongPress: () async {
          if (urls[index].startsWith("/storage/")) {
            EasyLoading.showToast("图片已保存到${urls[index]}");
            return;
          }

          // 网络图片就保存都指定位置
          await saveTtiImageToLocal(urls[index],
              prefix: prefix == null
                  ? null
                  : (prefix.endsWith("_") ? prefix : "${prefix}_"));
        },
        // 默认缓存展示
        child: SizedBox(
          height: 0.2.sw,
          child: buildNetworkOrFileImage(urls[index], fit: BoxFit.cover),
        ),
      ),
    );
  }).toList();
}

/// 构建图片预览，可点击放大
/// 注意限定传入的图片类型，要在这些条件之中
Widget buildImageView(
  dynamic image,
  BuildContext context, {
  // 是否是本地文件地址(暂时没使用到网络地址)
  bool? isFileUrl = false,
  String imagePlaceholder = "请选择图片",
}) {
  // 如果没有图片数据，直接返回文提示
  if (image == null) {
    return Center(
      child: Text(
        imagePlaceholder,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  ImageProvider imageProvider;
  // 只有base64的字符串或者文件格式
  if (image.runtimeType == String && isFileUrl == false) {
    imageProvider = MemoryImage(base64Decode(image));
  }
  if (image.runtimeType == String && isFileUrl == true) {
    imageProvider = FileImage(File(image));
  } else {
    // 如果直接传文件，那就是文件
    imageProvider = FileImage(image);
  }

  return GridTile(
    child: GestureDetector(
      // 单击预览
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent, // 设置背景透明
              child: _buildPhotoView(imageProvider),
            );
          },
        );
      },
      // 默认显示文件图片
      child: RepaintBoundary(
        child: Center(
          child: Image(image: imageProvider, fit: BoxFit.scaleDown),
        ),
      ),
    ),
  );
}

// 生成随机颜色
Color genRandomColor() =>
    Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

// 生成随机颜色带透明度
Color genRandomColorWithOpacity({double? opacity}) =>
    Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
        .withOpacity(opacity ?? math.Random().nextDouble());

// 指定长度的随机字符串
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
math.Random _rnd = math.Random();
String getRandomString(int length) {
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
    ),
  );
}

// 指定长度的范围的随机字符串(包含上面那个，最大最小同一个值即可)
String generateRandomString(int minLength, int maxLength) {
  int length = minLength + _rnd.nextInt(maxLength - minLength + 1);

  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
    ),
  );
}

// 异常弹窗
commonExceptionDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("确定"),
          ),
        ],
      );
    },
  );
}

///
/// form builder 库中文本栏位和下拉选择框组件的二次封装
///
// 构建表单的文本输入框
Widget cusFormBuilerTextField(String name,
    {String? initialValue,
    double? valueFontSize,
    int? maxLines,
    String? hintText, // 可不传提示语
    TextStyle? hintStyle,
    String? labelText, // 可不传栏位标签，在输入框前面有就行
    String? Function(Object?)? validator,
    bool? isOutline = false, // 输入框是否有线条
    bool isReadOnly = false, // 输入框是否有只读
    TextInputType? keyboardType,
    void Function(String?)? onChanged,
    List<TextInputFormatter>? inputFormatters}) {
  return Padding(
    padding: EdgeInsets.all(5.sp),
    child: FormBuilderTextField(
      name: name,
      initialValue: initialValue,
      maxLines: maxLines,
      readOnly: isReadOnly,
      style: TextStyle(fontSize: valueFontSize),
      // 2023-12-04 没有传默认使用name，原本默认的.text会弹安全键盘，可能无法输入中文
      // 2023-12-21 enableSuggestions 设为 true后键盘类型为text就正常了。
      // 注意：如果有最大行超过1的话，默认启用多行的键盘类型
      enableSuggestions: true,
      keyboardType: keyboardType ??
          ((maxLines != null && maxLines > 1)
              ? TextInputType.multiline
              : TextInputType.text),

      decoration: _buildInputDecoration(
        isOutline,
        isReadOnly,
        labelText,
        hintText,
        hintStyle,
      ),
      validator: validator,
      onChanged: onChanged,
      // 输入的格式限制
      inputFormatters: inputFormatters,
    ),
  );
}

/// 构建下拉多选弹窗模块栏位(主要为了样式统一)
Widget buildModifyMultiSelectDialogField(
  BuildContext context, {
  required List<CusLabel> items,
  GlobalKey<FormFieldState<dynamic>>? key,
  List<dynamic> initialValue = const [],
  String? labelText,
  String? hintText,
  String? Function(List<dynamic>?)? validator,
  required void Function(List<dynamic>) onConfirm,
}) {
  // 把预设的基础活动选项列表转化为 MultiSelectDialogField 支持的列表
  final formattedItems = items
      .map<MultiSelectItem<CusLabel>>(
          (opt) => MultiSelectItem<CusLabel>(opt, opt.cnLabel))
      .toList();

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 10.sp),
    child: MultiSelectDialogField(
      key: key,
      items: formattedItems,
      // ？？？？ 好像是不带validator用了这个初始值就会报错
      initialValue: initialValue,
      title: Text(hintText ?? ''),
      // selectedColor: Colors.blue,
      decoration: BoxDecoration(
        // color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.all(Radius.circular(5.sp)),
        border: Border.all(
          width: 2.sp,
          color: Theme.of(context).disabledColor,
        ),
      ),
      // buttonIcon: const Icon(Icons.fitness_center, color: Colors.blue),
      buttonIcon: const Icon(Icons.restaurant_menu),
      buttonText: Text(
        labelText ?? "",
        style: TextStyle(
          // color: Colors.blue[800],
          fontSize: 12.sp,
        ),
      ),
      // searchable: true,
      validator: validator,
      onConfirm: onConfirm,
      cancelText: const Text("取消"),
      confirmText: const Text("确认"),
    ),
  );
}

// formbuilder 下拉框和文本输入框的样式等内容
InputDecoration _buildInputDecoration(
  bool? isOutline,
  bool isReadOnly,
  String? labelText,
  String? hintText,
  TextStyle? hintStyle,
) {
  final contentPadding = isOutline != null && isOutline
      ? EdgeInsets.symmetric(horizontal: 5.sp, vertical: 15.sp)
      : EdgeInsets.symmetric(horizontal: 5.sp, vertical: 5.sp);

  return InputDecoration(
    isDense: true,
    labelText: labelText,
    hintText: hintText,
    hintStyle: hintStyle,
    contentPadding: contentPadding,
    border: isOutline != null && isOutline
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          )
        : isReadOnly
            ? InputBorder.none
            : null,
    // 设置透明底色
    filled: true,
    fillColor: Colors.transparent,
  );
}

buildSmallChip(
  String labelText, {
  Color? bgColor,
  double? labelTextSize,
}) {
  return Chip(
    label: Text(labelText),
    backgroundColor: bgColor,
    labelStyle: TextStyle(fontSize: labelTextSize),
    labelPadding: EdgeInsets.zero,
    // 设置负数会报错，但好像看到有点效果呢
    // labelPadding: EdgeInsets.fromLTRB(0, -6.sp, 0, -6.sp),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

// 用一个按钮假装是一个标签，用来展示
Widget buildSmallButtonTag(
  String labelText, {
  Color? bgColor,
  double? labelTextSize,
}) {
  return RawMaterialButton(
    onPressed: () {},
    constraints: const BoxConstraints(),
    padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
    fillColor: bgColor ?? Colors.grey[300],
    child: Text(
      labelText,
      style: TextStyle(fontSize: labelTextSize ?? 12.sp),
    ),
  );
}

// 一般当做标签用，比上面个还小
// 传入的字体最好不超过10
buildTinyButtonTag(
  String labelText, {
  Color? bgColor,
  double? labelTextSize,
}) {
  return SizedBox(
    // 传入大于12的字体，修正为12；不传则默认12
    height: ((labelTextSize != null && labelTextSize > 10.sp)
            ? 10.sp
            : labelTextSize ?? 10.sp) +
        10.sp,
    child: RawMaterialButton(
      onPressed: () {},
      constraints: const BoxConstraints(),
      padding: EdgeInsets.fromLTRB(4.sp, 2.sp, 4.sp, 2.sp),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.sp),
      ),
      fillColor: bgColor ?? Colors.grey[300],
      child: Text(
        labelText,
        style: TextStyle(
          // 传入大于10的字体，修正为10；不传则默认10
          fontSize: (labelTextSize != null && labelTextSize > 10.sp)
              ? 10.sp
              : labelTextSize ?? 10.sp,
        ),
      ),
    ),
  );
}

// 带有横线滚动条的datatable
buildDataTableWithHorizontalScrollbar({
  required ScrollController scrollController,
  required List<DataColumn> columns,
  required List<DataRow> rows,
}) {
  return Scrollbar(
    thickness: 5,
    // 设置交互模式后，滚动条和手势滚动方向才一致
    interactive: true,
    radius: Radius.circular(5.sp),
    // 不设置这个，滚动条默认不显示，在滚动时才显示
    thumbVisibility: true,
    // trackVisibility: true,
    // 滚动条默认在右边，要改在左边就配合Transform进行修改(此例没必要)
    // 刻意预留一点空间给滚动条
    controller: scrollController,
    child: SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: DataTable(
        // dataRowHeight: 10.sp,
        dataRowMinHeight: 60.sp, // 设置行高范围
        dataRowMaxHeight: 100.sp,
        headingRowHeight: 25, // 设置表头行高
        horizontalMargin: 10, // 设置水平边距
        columnSpacing: 20.sp, // 设置列间距
        columns: columns,
        rows: rows,
      ),
    ),
  );
}

/// ----
///
// 图片轮播
buildImageCarouselSlider(
  List<String> imageList, {
  bool isNoImage = false, // 是否不显示图片，默认就算无图片也显示占位图片
  int type = 3, // 轮播图是否可以点击预览图片，预设为3(具体类型参看下方实现方法)
}) {
  return CarouselSlider(
    options: CarouselOptions(
      autoPlay: true, // 自动播放
      enlargeCenterPage: true, // 居中图片放大
      aspectRatio: 16 / 9, // 图片宽高比
      viewportFraction: 1, // 图片占屏幕宽度的比例
      // 只有一张图片时不滚动
      enableInfiniteScroll: imageList.length > 1,
    ),
    // 除非指定不显示图片，否则没有图片也显示一张占位图片
    items: isNoImage
        ? null
        : imageList.isEmpty
            ? [Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown)]
            : imageList.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return _buildImageCarouselSliderType(
                      type,
                      context,
                      imageUrl,
                      imageList,
                    );
                  },
                );
              }).toList(),
  );
}

// 2024-03-12 根据图片地址前缀来区分是否是网络图片，使用不同的方式展示图片
Widget buildNetworkOrFileImage(String imageUrl, {BoxFit? fit}) {
  if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      // progressIndicatorBuilder: (context, url, progress) => Center(
      //   child: CircularProgressIndicator(
      //     value: progress.progress,
      //   ),
      // ),

      /// placeholder 和 progressIndicatorBuilder 只能2选1
      placeholder: (context, url) => Center(
        child: SizedBox(
          width: 50.sp,
          height: 50.sp,
          child: const CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Center(
        child: Icon(Icons.error, size: 36.sp),
      ),
    );

    // 2024-03-29 这样每次都会重新请求图片，网络图片都不小的，流量顶不住。用上面的
    // return Image.network(
    //   imageUrl,
    //   errorBuilder: (context, error, stackTrace) {
    //     return Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown);
    //   },
    //   fit: fit,
    // );
  } else {
    return Image.file(
      File(imageUrl),
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown);
      },
      fit: fit,
    );
  }
}

// 2024-03-12 根据图片地址前缀来区分是否是网络图片
bool isNetworkImageUrl(String imageUrl) {
  return (imageUrl.startsWith('http') || imageUrl.startsWith('https'));
}

ImageProvider getImageProvider(String imageUrl) {
  if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
    return CachedNetworkImageProvider(imageUrl);
    // return NetworkImage(imageUrl);
  } else {
    return FileImage(File(imageUrl));
  }
}

/// 2023-12-26
/// 现在设计轮播图3种形态:
///   1 点击某张图片，可以弹窗显示该图片并进行缩放预览
///   2 点击某张图片，可以跳转新页面对该图片并进行缩放预览
///   3 点击某张图片，可以弹窗对该图片所在整个列表进行缩放预览(默认选项)
///   default 单纯的轮播展示,点击图片无动作
_buildImageCarouselSliderType(
  int type,
  BuildContext context,
  String imageUrl,
  List<String> imageList,
) {
  buildCommonImageWidget(Function() onTap) =>
      GestureDetector(onTap: onTap, child: buildNetworkOrFileImage(imageUrl));

  switch (type) {
    // 这个直接弹窗显示图片可以缩放
    case 1:
      return buildCommonImageWidget(() {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent, // 设置背景透明
              child: _buildPhotoView(getImageProvider(imageUrl)),
            );
          },
        );
      });
    case 2:
      return buildCommonImageWidget(() {
        // 这个是跳转到新的页面去
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _buildPhotoView(getImageProvider(imageUrl)),
          ),
        );
      });
    case 3:
      return buildCommonImageWidget(() {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            // 这个弹窗默认是无法全屏的，上下左右会留点空，点击这些空隙可以关闭弹窗
            return Dialog(
              backgroundColor: Colors.transparent,
              child: PhotoViewGallery.builder(
                itemCount: imageList.length,
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: getImageProvider(imageList[index]),
                    errorBuilder: (context, url, error) =>
                        const Icon(Icons.error),
                  );
                },
                // enableRotation: true,
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                loadingBuilder: (BuildContext context, ImageChunkEvent? event) {
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            );
          },
        );
      });
    default:
      return Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: const BoxDecoration(color: Colors.grey),
        child: buildNetworkOrFileImage(imageUrl),
      );
  }
}

// 将图片字符串，转为文件多选框中支持的图片平台文件
// formbuilder的图片地址拼接的字符串，要转回平台文件列表
List<PlatformFile> convertStringToPlatformFiles(String imagesString) {
  List<String> imageUrls = imagesString.split(','); // 拆分字符串
  // 如果本身就是空字符串，直接返回空平台文件数组
  if (imagesString.trim().isEmpty || imageUrls.isEmpty) {
    return [];
  }

  List<PlatformFile> platformFiles = []; // 存储 PlatformFile 对象的列表

  for (var imageUrl in imageUrls) {
    PlatformFile file = PlatformFile(
      name: imageUrl,
      path: imageUrl,
      size: 32, // 假设图片地址即为文件路径
    );
    platformFiles.add(file);
  }

  return platformFiles;
}

/// 显示本地路径图片，点击可弹窗显示并缩放
buildClickImageDialog(BuildContext context, String imageUrl) {
  return GestureDetector(
    onTap: () {
      // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
      unfocusHandle();
      // 这个直接弹窗显示图片可以缩放
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent, // 设置背景透明
            child: _buildPhotoView(FileImage(File(imageUrl))),
          );
        },
      );
    },
    child: Padding(
      padding: EdgeInsets.all(20.sp),
      child: SizedBox(
        width: 0.8.sw,
        child: buildNetworkOrFileImage(imageUrl),
      ),
    ),
  );
}

// 调用外部浏览器打开url
Future<void> launchStringUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}

/// 强制收起键盘
unfocusHandle() {
  // 这个不一定有用，比如下面原本键盘弹出来了，跳到历史记录页面，回来之后还是弹出来的
  // FocusScope.of(context).unfocus();

  FocusManager.instance.primaryFocus?.unfocus();
}

///
/// 使用 DropdownButton2 构建的自定义下拉框
///
Widget buildDropdownButton2<T>({
  required List<T> items,
  T? value,
  Function(T?)? onChanged,
  // 如何从传入的类型中获取显示的字符串
  final String Function(dynamic)? itemToString,
  // 下拉框的高度
  double? height,
  // 选项列表的最大高度
  double? itemMaxHeight,
  // 标签的字号
  double? labelSize,
  // 标签对齐方式(默认居中，像模型列表靠左，方便对比)
  AlignmentGeometry? alignment,
}) {
  return DropdownButtonHideUnderline(
    child: DropdownButton2<T>(
      isExpanded: true,
      // 下拉选择
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                alignment: alignment ?? AlignmentDirectional.center,
                child: Text(
                  itemToString != null ? itemToString(e) : e.toString(),
                  style: TextStyle(
                    fontSize: labelSize ?? 15.sp,
                    color: Colors.blue,
                  ),
                ),
              ))
          .toList(),
      // 下拉按钮当前被选中的值
      value: value,
      // 当值切换时触发的函数
      onChanged: onChanged,
      // 默认的按钮的样式(下拉框旋转的样式)
      buttonStyleData: ButtonStyleData(
        height: height ?? 30.sp,
        // width: 190.sp,
        padding: EdgeInsets.all(0.sp),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.sp),
          border: Border.all(color: Colors.black26),
          // color: Colors.blue[50],
          color: Colors.white,
        ),
        elevation: 0,
      ),
      // 按钮后面的图标的样式(默认也有个下三角)
      iconStyleData: IconStyleData(
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 20.sp,
        iconEnabledColor: Colors.blue,
        iconDisabledColor: Colors.grey,
      ),
      // 下拉选项列表区域的样式
      dropdownStyleData: DropdownStyleData(
        maxHeight: itemMaxHeight ?? 300.sp,
        // 不设置且isExpanded为true就是外部最宽
        // width: 190.sp, // 可以根据下面的offset偏移和上面按钮的长度来调整
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.sp),
          color: Colors.white,
        ),
        // offset: const Offset(-20, 0),
        offset: const Offset(0, 0),
        scrollbarTheme: ScrollbarThemeData(
          radius: Radius.circular(40.sp),
          thickness: WidgetStateProperty.all(6.sp),
          thumbVisibility: WidgetStateProperty.all(true),
        ),
      ),
      // 下拉选项单个选项的样式
      menuItemStyleData: MenuItemStyleData(
        height: 48.sp, // 方便超过1行的模型名显示，所有设置高点
        padding: EdgeInsets.symmetric(horizontal: 5.sp),
      ),
    ),
  );
}
