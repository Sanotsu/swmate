import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/llm_spec/cus_llm_model.dart';

///
/// 显示预设系统角色列表、或者文生图图生图的预设prompt等
///
void showCusSysRoleList(
  BuildContext context,
  List<CusSysRoleSpec> ccSysRoleList,
  Function(CusSysRoleSpec) onRoleSelected, {
  String? title,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return CusSysRoleListModal(
        ccSysRoleList: ccSysRoleList,
        onRoleSelected: onRoleSelected,
        title: title,
      );
    },
  ).then((value) {
    if (value != null && value is CusSysRoleSpec) {
      onRoleSelected(value);
    }
  });
}

class CusSysRoleListModal extends StatelessWidget {
  final List<CusSysRoleSpec> ccSysRoleList;
  final Function(CusSysRoleSpec) onRoleSelected;
  final String? title;

  const CusSysRoleListModal({
    super.key,
    required this.ccSysRoleList,
    required this.onRoleSelected,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 4 * 3,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.sp),
          topRight: Radius.circular(15.sp),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 100.sp,
            margin: EdgeInsets.fromLTRB(20, 0, 10.sp, 0.sp),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "预设${title ?? '系统角色'}说明",
                        style: TextStyle(fontSize: 18.sp),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("关闭"),
                    )
                  ],
                ),
                Text(
                  "不是所有模型都支持，不是所有${title ?? '角色'}都能按预期执行。",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp),
                ),
                Text(
                  "先选好平台和模型，再选择${title ?? '角色'}，${title ?? '角色'}才会生效。",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(height: 10.sp, thickness: 1.sp),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: ccSysRoleList.length,
              itemBuilder: (BuildContext context, int index) {
                var a = ccSysRoleList[index];
                return Card(
                  child: ListTile(
                    title: Text(a.label),
                    subtitle: a.subtitle != null ? Text(a.subtitle!) : null,
                    dense: true,
                    onTap: () {
                      Navigator.pop(context, a);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
