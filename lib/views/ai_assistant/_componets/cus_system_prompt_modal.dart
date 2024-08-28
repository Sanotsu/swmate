import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/llm_spec/cus_llm_model.dart';

///
/// 显示预设系统角色列表、或者文生图图生图的预设prompt等
///
void showCusSysRoleList(
  BuildContext context,
  List<CusSysRoleSpec> ccSysRoleList,
  Function(CusSysRoleSpec) onRoleSelected,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return CusSysRoleListModal(
        ccSysRoleList: ccSysRoleList,
        onRoleSelected: onRoleSelected,
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

  const CusSysRoleListModal({
    super.key,
    required this.ccSysRoleList,
    required this.onRoleSelected,
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
                        "预设系统角色说明",
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
                  """不是所有模型都支持，不是所有预设角色都能按预期执行。\n先选择好平台和模型，再选择预设角色，角色才会生效。
                            """,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp),
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
