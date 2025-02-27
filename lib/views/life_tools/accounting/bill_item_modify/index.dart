import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../common/components/tool_widget.dart';
import '../../../../common/constants.dart';
import '../../../../common/utils/db_tools/db_life_tool_helper.dart';
import '../../../../models/base_model/brief_accounting_state.dart';

///
/// 新增账单条目的简单布局：
///
/// 收入/支出选项(switch之类也行)
/// 选择大分类 category
/// 输入细项 item
/// 输入金额 value
/// 指定日期 datetime picker，默认当前，但也可以是添加以前的流水项目
///
class BillEditPage extends StatefulWidget {
  // 列表页面长按修改的时候可能会传账单条目
  final BillItem? billItem;

  const BillEditPage({super.key, this.billItem});

  @override
  State createState() => _BillEditPageState();
}

class _BillEditPageState extends State<BillEditPage> {
  final DBLifeToolHelper _dbHelper = DBLifeToolHelper();

  // 表单的全局key
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  // 表单输入金额是否有错
  bool _amountHasError = false;

  // 保存中
  bool isLoading = false;

  void _onChanged(dynamic val) => debugPrint(val.toString());

  // 这些选项都是FormBuilderChipOption类型
  String selectedCategoryType = "支出";
  var categoryList = [
    // 2024-06-03 现在使用大分类(会修改测试数据，即旧的资料，别再动力)
    "餐饮", "交通", "购物", "服饰", "水果", "住宿",
    "娱乐", "缴费", "数码", "运动", "旅行", "宠物",
    "教育", "医疗", "红包", "转账", "人情", "轻奢",
    "美容", "亲子", "保险", "公益", "服务", "其他",
    // 之前旧的分类，留存
    // // 饮食
    // "三餐", "外卖", "零食", "夜宵", "烟酒", "饮料",
    // // 购物
    // "购物", "买菜", "日用", "水果", "买花", "服装",
    // // 娱乐
    // "娱乐", "电影", "旅行", "运动", "纪念", "充值",
    // // 住、行
    // "交通", "住房", "房租", "房贷",
    // // 生活
    // "理发", "还款",
  ];
  var incomeCategoryList = [
    // 收入
    "工资", "奖金", "生意", "摆摊", "红包", "转账",
    "投资", "炒股", "基金", "人情", "退款", "其他",
  ];

  // 微信账单中的分类
  var outCates = [
    // 第一行
    "餐饮", "交通", "服饰", "购物", "服务", "教育",
    "娱乐", "运动", "生活缴费", "旅行", "宠物", "医疗",
    "保险", "公益", "发红包", "转账", "亲属卡", "其他人情",
    "其他", "服饰美容", "酒店", "亲子", "退还"
  ];
  var inCates = [
    // 第一行
    "生意", "工资", "奖金", "其他人情", "收红包", "收转账",
    "商家转账", "退款", "其他",
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 如果有传表单的初始对象值，就显示该值
      if (widget.billItem != null) {
        setState(() {
          _formKey.currentState?.patchValue(widget.billItem!.toStringMap());
          selectedCategoryType = widget.billItem!.itemType != 0 ? "支出" : "收入";
        });
      }
    });
  }

  // ???初始化之后就不能改了，没法按照收入支出分类切换后更新分类栏位初始化值
  initType() {
    return selectedCategoryType == "收入" ? "工资" : "餐饮";
  }

  // 构建收支条目
  List<FormBuilderChipOption<String>> _categoryChipOptions() {
    return (selectedCategoryType == "支出" ? categoryList : incomeCategoryList)
        .map((e) => FormBuilderChipOption(value: e))
        .toList();
  }

  /// 保存账单条目到数据库
  saveBillItem() async {
    if (_formKey.currentState!.saveAndValidate()) {
      if (isLoading) return;
      setState(() {
        isLoading = true;
      });

      var temp = _formKey.currentState!.value;

      var tempItem = BillItem(
        billItemId: const Uuid().v4(),
        itemType: temp['item_type'] == '收入' ? 0 : 1,
        date: DateFormat(constDateFormat).format(temp['date']),
        category: temp['category'],
        item: temp['item'],
        value: double.tryParse(temp['value']) ?? 0,
        gmtModified: DateFormat(constDatetimeFormat).format(DateTime.now()),
      );

      try {
        // 没传是新增
        if (widget.billItem == null) {
          await _dbHelper.insertBillItemList([tempItem]);
        } else {
          // 有传是修改
          tempItem.billItemId = widget.billItem!.billItemId;
          await _dbHelper.updateBillItem(tempItem);
        }

        if (!mounted) return;
        setState(() {
          isLoading = false;
        });

        /// 这两个个跳转都有问题，打开app时账单列表页面appbar没有返回箭头，从这里跳过去后就会有了。
        ///   Flutter 会根据上下文自动添加一个返回按钮，因为通常当页面不是堆栈中的根页面时，用户期望能够返回到上一个页面。
        ///   即使设置了leading:null也没有效果
        ///
        // 新增或修改成功了，跳转到主页面去(homepage默认是账单列表)
        // 因为可能是修改(从账单列表来的)或者新增(从新增按钮来的)，来源不一样，所以这里不是返回而是替换
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (context) => const HomePage()),
        //   ModalRoute.withName('/'),
        // );

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const HomePage()),
        // );

        /// 这个跳转虽然没有appbar没有箭头了，但数据不会重新加载
        /// 因为pop和popUntil这些操作只是从导航堆栈中移除页面，而不会重新创建它们。
        // Navigator.of(context).popUntil((route) => route.isFirst);

        // 2024-05-29 新增新增账单放到账单列表页面去了，所以修改和新增返回就是到账单列表页面去
        Navigator.of(context).pop(true);
      } catch (e) {
        // 将错误信息展示给用户
        if (!mounted) return;
        commonHintDialog(context, "异常警告", e.toString());
        setState(() {
          isLoading = false;
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.billItem != null ? '修改' : '新增'}账单项目"),
        actions: [
          IconButton(
            onPressed: () async {
              if (_formKey.currentState!.saveAndValidate()) {
                // 处理表单数据，如保存到数据库等
                saveBillItem();
              }
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: FormBuilderChoiceChip<String>(
                        name: 'item_type',
                        initialValue: '支出',
                        // 可让选项居中
                        alignment: WrapAlignment.center,
                        // 选项标签的一些大小修改配置
                        labelStyle: TextStyle(fontSize: 10.sp),
                        labelPadding: EdgeInsets.all(1.sp),
                        options: const [
                          FormBuilderChipOption(value: '支出'),
                          FormBuilderChipOption(value: '收入'),
                        ],
                        decoration: const InputDecoration(
                          // 取消下划线
                          border: InputBorder.none,
                        ),
                        onChanged: (String? val) {
                          if (val != null) {
                            setState(() {
                              selectedCategoryType = val;
                            });
                          }
                        },
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                        ]),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: FormBuilderDateTimePicker(
                        name: 'date',
                        initialEntryMode: DatePickerEntryMode.calendar,
                        initialValue: DateTime.now(),
                        inputType: InputType.both,
                        decoration: const InputDecoration(
                          // labelText: '时间',
                          // // 取消下划线
                          // border: InputBorder.none,
                          // 设置透明底色
                          filled: true,
                          fillColor: Colors.transparent,
                          suffixIcon: Icon(Icons.arrow_drop_down),
                          // // 后置图标点击清空
                          // suffixIcon: IconButton(
                          //   icon: Icon(Icons.close, size: 20.sp),
                          //   onPressed: () {
                          //     _formKey.currentState!.fields['date']
                          //         ?.didChange(null);
                          //   },
                          // ),
                        ),
                        keyboardType: TextInputType.datetime,
                        initialTime: const TimeOfDay(hour: 8, minute: 0),
                        locale: Localizations.localeOf(context),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                        ]),
                      ),
                    ),
                  ],
                ),
                FormBuilderTextField(
                  autovalidateMode: AutovalidateMode.always,
                  name: 'value',
                  decoration: InputDecoration(
                    labelText: '金额',
                    // 设置透明底色
                    filled: true,
                    fillColor: Colors.transparent,
                    prefixIcon: Text(
                      '\u{00A5}', // 人民币符号的unicode编码
                      style: TextStyle(fontSize: 36.sp, color: Colors.black),
                    ),
                    suffixIcon: _amountHasError
                        ? const Icon(Icons.error, color: Colors.red)
                        : const Icon(Icons.check, color: Colors.green),
                  ),
                  onChanged: (val) {
                    setState(() {
                      // 如果金额输入不符合规范，尾部图标会实时切换
                      _amountHasError = !(_formKey.currentState?.fields['value']
                              ?.validate() ??
                          false);
                    });
                  },
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.numeric(),
                  ]),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                FormBuilderTextField(
                  name: 'item',
                  decoration: const InputDecoration(
                    labelText: '项目',
                    // 设置透明底色
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                  enableSuggestions: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                ),
                FormBuilderChoiceChip<String>(
                  decoration: const InputDecoration(
                    labelText: '分类',
                    // 设置透明底色
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  name: 'category',
                  // initialValue: initType(),
                  initialValue: "餐饮",
                  // 可让选项居中
                  alignment: WrapAlignment.center,
                  // 选项标签的一些大小修改配置
                  labelStyle: TextStyle(fontSize: 10.sp),
                  labelPadding: EdgeInsets.all(1.sp),
                  elevation: 5,
                  // padding: EdgeInsets.all(0.sp),
                  // 标签之间垂直的间隔
                  // runSpacing: 10.sp,
                  // 标签之间水平的间隔
                  // spacing: 10.sp,
                  options: _categoryChipOptions(),
                  onChanged: _onChanged,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
