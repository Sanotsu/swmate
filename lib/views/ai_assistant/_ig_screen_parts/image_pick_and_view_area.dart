import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../common/components/tool_widget.dart';

class ImagePickAndViewArea extends StatelessWidget {
  final Function(ImageSource) imageSelectedHandle;
  final Function() imageClearHandle;
  final File? selectedImage;
  final String imagePlaceholder;

  const ImagePickAndViewArea({
    super.key,
    required this.imageSelectedHandle,
    required this.imageClearHandle,
    required this.selectedImage,
    this.imagePlaceholder = "请选择参考图",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.sp,
      margin: EdgeInsets.fromLTRB(5.sp, 5.sp, 5.sp, 0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1.sp),
        borderRadius: BorderRadius.circular(5.sp),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      "选择图片来源",
                      style: TextStyle(fontSize: 18.sp),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          imageSelectedHandle(ImageSource.camera);
                        },
                        child: Text(
                          "拍照",
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          imageSelectedHandle(ImageSource.gallery);
                        },
                        child: Text(
                          "相册",
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.file_upload),
          ),
          Expanded(
            flex: 3,
            child: buildImageView(
              selectedImage,
              context,
              imagePlaceholder: imagePlaceholder,
            ),
          ),
          if (selectedImage != null)
            IconButton(
              onPressed: imageClearHandle,
              icon: const Icon(Icons.clear),
            ),
        ],
      ),
    );
  }
}
