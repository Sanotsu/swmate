import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_file_picker/form_builder_file_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../common/utils/db_tools/db_life_tool_helper.dart';
import '../../../common/utils/tools.dart';
import '../../../models/life_tools/dish_state.dart';

class DishModify extends StatefulWidget {
  // 新增菜品不会传，但修改菜品会传
  final Dish? dish;

  const DishModify({this.dish, super.key});

  @override
  State<DishModify> createState() => _DishModifyState();
}

class _DishModifyState extends State<DishModify> {
  final DBLifeToolHelper _dbHelper = DBLifeToolHelper();

  // 菜品基础信息的formbuilder的表单key
  final _dishFormKey = GlobalKey<FormBuilderState>();
  // 菜品分类下拉多选弹窗的key
  final _dishTagsSelectKey = GlobalKey<FormFieldState>();
  // 菜品餐次下拉多选弹窗的key
  final _dishCatesSelectKey = GlobalKey<FormFieldState>();

  // 如果有菜品示意图，要显示
  List<PlatformFile> initImages = [];
  // 2024-03-12 上面那个用在本地上传文件的图片初始化，这个用在网络图片的地址展示
  List<String> initNetworkImages = [];

  // 被选中的菜品的分类和餐次类型
  List<dynamic> selectedDishTags = [];
  List<dynamic> selectedDishCates = [];

  // 用户头像路径
  String? _recipePicturePath;

  // 2024-06-26 数据库中已经存在+预设的分类，修改时才好匹配上
  List<CusLabel> allDishCates = [];
  List<CusLabel> allDishTags = [];

  @override
  void initState() {
    setState(() {
      getAllDishCatesTags();
    });

    super.initState();

    // (不能放在下面那个callback中，会在表单初始化完成之后再赋值，那就没有意义了)
    setState(() {
      initSelectedTagCate();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 如果有传表单的初始对象值，就显示该值
      if (widget.dish != null) {
        // 注意，dish不能直接显示到form表单中，要转为map
        setState(() {
          //  因为表单中图片栏位的name是images而不是photos，这里赋值时匹配不上会忽略，就不会有
          // type 'String' is not a subtype of type 'List<PlatformFile>?' of 'value' 错误了。
          // 而实际的图片地址初始化，在上面已经赋值过了
          _dishFormKey.currentState?.patchValue(widget.dish!.toMap());
        });
      }
    });
  }

  // 初始化所有的分类和餐次类型(预设的+数据库中的)
  initSelectedTagCate() async {
    // 需要等拿到所有分类之后，再渲染
    await getAllDishCatesTags();

    if (widget.dish != null) {
      // 如果有菜品有图片，则显示图片
      if (widget.dish!.photos != null && widget.dish!.photos != "") {
        // 2024-03-12 获取所有图片地址，再根据前缀拆为网络图片和本地图片
        List<String> imageUrls = widget.dish!.photos!.split(',');

        // 如果本身就是空字符串，直接返回空平台文件数组
        if (widget.dish!.photos!.trim().isEmpty || imageUrls.isEmpty) {
          initImages = [];
          return;
        }

        // 如果有图片，网络图片部分直接过滤出来，直接显示地址即可
        initNetworkImages = imageUrls
            .where((e) => e.startsWith("http") || e.startsWith("https"))
            .toList();

        // 剩下的部分就转为平台文件格式，配合组件可以预览图片
        List<String> restImages = imageUrls
            .where((e) => !(e.startsWith("http") || e.startsWith("https")))
            .toList();

        for (var imageUrl in restImages) {
          PlatformFile file = PlatformFile(
            name: imageUrl,
            path: imageUrl,
            size: 32, // 假设图片地址即为文件路径
          );
          initImages.add(file);
        }
      }

      // 如果有分类，显示被选中的分类
      if (widget.dish!.tags != null && widget.dish!.tags != "") {
        selectedDishTags = genSelectedCusLabelOptions(
          widget.dish!.tags!,
          allDishTags,
        );
      }
      // 如果有餐次，显示被选中的餐次
      if (widget.dish!.mealCategories != null &&
          widget.dish!.mealCategories != "") {
        selectedDishCates = genSelectedCusLabelOptions(
          widget.dish!.mealCategories!,
          allDishCates,
        );
      }

      // 2024-03-22 如果有菜谱图片，也显示
      if (widget.dish!.recipePicture != null &&
          widget.dish!.recipePicture != "") {
        _recipePicturePath = widget.dish!.recipePicture!;
      }
    }
  }

  // 获取数据库中+预设的所有分类和标签
  getAllDishCatesTags() async {
    CusDataResult temp = await _dbHelper.queryDishList(
      page: 1,
      pageSize: 10000, // 应该查询所有
    );

    var newData = temp.data as List<Dish>;

    List<String> tempCates = [];
    List<String> tempTags = [];

    for (var e in newData) {
      var a = (e.mealCategories?.split(","));
      var b = (e.tags?.split(","));
      // 合并两个列表, Set()字面量去除重复，然后转回List
      tempCates = <String>{...tempCates, ...?a}.toSet().toList();
      tempTags = <String>{...tempTags, ...?b}.toSet().toList();
    }

    // 移除已经存在的分类和标签
    for (var e in dishCateOptions) {
      if (tempCates.contains(e.cnLabel)) {
        tempCates.remove(e.cnLabel);
      }
    }
    for (var e in dishTagOptions) {
      if (tempTags.contains(e.cnLabel)) {
        tempTags.remove(e.cnLabel);
      }
    }

    // 再将标签和分类字符串简单转为对象列表
    allDishCates = tempCates
        .map((e) => CusLabel(value: e, enLabel: e, cnLabel: e))
        .toList();
    allDishTags = tempTags
        .map((e) => CusLabel(value: e, enLabel: e, cnLabel: e))
        .toList();

    // 最后合并预设的和导入时存入数据库中的
    setState(() {
      allDishCates = <CusLabel>{...dishCateOptions, ...allDishCates}.toList();
      allDishTags = <CusLabel>{...dishTagOptions, ...allDishTags}.toList();
    });
  }

  // 将菜品信息保存到数据库中
  _saveDishInfoToDb() async {
    var flag1 = _dishTagsSelectKey.currentState?.validate();
    var flag2 = _dishCatesSelectKey.currentState?.validate();
    var flag3 = _dishFormKey.currentState!.saveAndValidate();

    // 如果表单验证都通过了，保存数据到数据库，并返回上一页
    if (flag1! && flag2! && flag3) {
      var temp = _dishFormKey.currentState;
      // ？？？2023-10-15 这里取值是不是刻意直接使用temp而不是按照每个栏位名称呢

      // 2023-03-12 图片部分要网络图片和本地图片联合起来
      String? netImage = temp?.fields["network_images"]?.value;
      List<PlatformFile> locImages = temp?.fields['images']?.value ?? [];
      String locImage = locImages.map((e) => e.path).join(",");

      var totalImage = [
        if (netImage != null) ...netImage.split(",").where((e) => e != ""),
        ...locImage.split(",").where((e) => e != "")
      ];

      Dish dish = Dish(
        dishId: const Uuid().v1(),
        dishName: temp?.fields['dish_name']?.value,
        description: temp?.fields['description']?.value,
        recipe: temp?.fields['recipe']?.value,
        tags: selectedDishTags.isNotEmpty
            ? selectedDishTags
                .map((opt) => (opt as CusLabel).value)
                .toList()
                .join(',')
            : null,
        mealCategories: selectedDishCates.isNotEmpty
            ? (selectedDishCates)
                .map((opt) => (opt as CusLabel).value)
                .toList()
                .join(',')
            : null,
        photos: totalImage.join(","),
        recipePicture: _recipePicturePath,
      );

      try {
        // 有旧菜品信息就是修改；没有就是新增
        if (widget.dish != null) {
          // 修改的话要保留原本的编号
          dish.dishId = widget.dish!.dishId;

          await _dbHelper.updateDish(dish);
        } else {
          await _dbHelper.insertDishList([dish]);
        }

        if (mounted) {
          // 2023-12-21 不报错就当作修改成功，直接返回
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (!mounted) return;
        // 2023-12-21 插入失败上面弹窗显示
        commonExceptionDialog(context, "异常提醒", e.toString());
      }
    }
  }

// 选择图片来源
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _recipePicturePath = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.dish != null ? "修改" : "新增"}菜品信息'),
        actions: [
          IconButton(
            onPressed: _saveDishInfoToDb,
            icon: const Icon(Icons.save),
          )
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(10.sp),
            child: SingleChildScrollView(
              child: FormBuilder(
                key: _dishFormKey,
                initialValue: widget.dish != null ? widget.dish!.toMap() : {},
                child: Column(
                  children: [
                    ...buildDishModifyFormColumns(
                      context,
                      initImages: initImages.isEmpty ? null : initImages,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20.sp),
        ],
      ),
    );
  }

  // 构建菜品编辑表单栏位
  buildDishModifyFormColumns(
    BuildContext context, {
    List<PlatformFile>? initImages,
  }) {
    return [
      cusFormBuilerTextField(
        "dish_name",
        labelText: '*菜品名称',
        validator: FormBuilderValidators.required(),
      ),
      cusFormBuilerTextField("description", labelText: '菜品简介', maxLines: 3),
      const SizedBox(height: 10),
      // 菜品标签(多选)
      buildModifyMultiSelectDialogField(
        context,
        items: allDishTags,
        key: _dishTagsSelectKey,
        initialValue: selectedDishTags,
        labelText: "*菜品标签",
        validator: FormBuilderValidators.required(),
        onConfirm: (results) {
          selectedDishTags = results;
          // 从多选框弹窗回来不聚焦
          FocusScope.of(context).requestFocus(FocusNode());
        },
      ),
      const SizedBox(height: 10),
      // 菜品餐次(多选)
      buildModifyMultiSelectDialogField(
        context,
        items: allDishCates,
        key: _dishCatesSelectKey,
        initialValue: selectedDishCates,
        labelText: "*菜品餐次",
        validator: FormBuilderValidators.required(),
        onConfirm: (results) {
          selectedDishCates = results;
          // 从多选框弹窗回来不聚焦
          FocusScope.of(context).requestFocus(FocusNode());
        },
      ),
      cusFormBuilerTextField(
        "videos",
        labelText: '视频地址(推荐使用单个网址)',
        maxLines: 5,
        valueFontSize: 14,
      ),
      cusFormBuilerTextField(
        "network_images",
        labelText: '网络图片地址(用英文逗号分割, 且结尾不要有逗号)',
        maxLines: 5,
        initialValue: initNetworkImages.join(","),
        valueFontSize: 14,
      ),
      SizedBox(height: 10.sp),
      // 上传菜品图片（静态图或者gif）
      FormBuilderFilePicker(
        /// 2024-03-10 注意，这个图片上传的name命名很重要，【不能】和model中的photos属性一样。
        /// 因为在修改菜品时，会patchValue，而此处需要的是List<PlatformFile>?，同名了传来的就会是String，
        /// 则报错：type 'String' is not a subtype of type 'List<PlatformFile>?' of 'value'
        name: 'images',
        decoration: const InputDecoration(
          labelText: "菜品图片",
          // 设置透明底色
          filled: true,
          fillColor: Colors.transparent,
        ),
        initialValue: initImages,
        maxFiles: null,
        allowMultiple: true,
        previewImages: true,
        // onChanged: (val) => debugPrint(val.toString()),
        typeSelectors: const [
          TypeSelector(
            type: FileType.image,
            selector: Row(
              children: <Widget>[
                Icon(Icons.file_upload),
                Text("上传菜品图片"),
              ],
            ),
          )
        ],
        customTypeViewerBuilder: (children) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: children,
        ),
        // onFileLoading: (val) => debugPrint(val.toString()),
      ),

      cusFormBuilerTextField(
        "recipe",
        labelText: '菜谱',
        maxLines: 10,
      ),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      "菜谱图片上传方式",
                      style: TextStyle(fontSize: 20.sp),
                    ),
                    content: const Text("注意，仅支持单张图片！"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _pickImage(ImageSource.camera);
                        },
                        child: const Text("拍照"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _pickImage(ImageSource.gallery);
                        },
                        child: const Text("相册"),
                      ),
                    ],
                  );
                },
              );
            },
            child: Text(
              "上传菜谱图片",
              style: TextStyle(fontSize: 15.sp),
            ),
          ),
          TextButton(
            onPressed: _recipePicturePath != null
                ? () {
                    setState(() {
                      _recipePicturePath = null;
                    });
                  }
                : null,
            child: Text(
              "移除菜谱图片",
              style: TextStyle(fontSize: 15.sp),
            ),
          ),
        ],
      ),

      if (_recipePicturePath != null && _recipePicturePath!.isNotEmpty)
        buildClickImageDialog(context, _recipePicturePath!)
    ];
  }
}
