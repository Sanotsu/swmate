import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/components/tool_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../common/utils/db_tools/db_life_tool_helper.dart';
import '../../../common/utils/tools.dart';
import '../../../models/life_tools/dish_state.dart';
import 'dish_detail.dart';
import 'dish_json_import.dart';
import 'dish_modify.dart';

/// 菜品列表，点击进入详情；长按删除弹窗。
/// 顶部按钮：切换列表展示样式(图片/文字)、导入json文件、新增菜品
class DishList extends StatefulWidget {
  const DishList({super.key});

  @override
  State<DishList> createState() => _DishListState();
}

class _DishListState extends State<DishList> {
  final DBLifeToolHelper _dbHelper = DBLifeToolHelper();

  List<Dish> dishItems = [];
  // 食物的总数(查询时则为符合条件的总数，默认一页只有10条，看不到总数量)
  int itemsCount = 0;
  int currentPage = 1; // 数据库查询的时候会从0开始offset
  int pageSize = 10;
  bool isLoading = false;
  ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  String query = '';

  // 当前网络状态相关栏位
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // 默认不使用卡片列表，节约流量
  bool isDishCardList = false;

  // 是否授权访问存储
  bool isPermissionGranted = false;

  @override
  void initState() {
    super.initState();

    _getPermission();

    _loadDishData();

    scrollController.addListener(_scrollListener);

    initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    searchController.dispose();

    _connectivitySubscription.cancel();
    super.dispose();
  }

  _getPermission() async {
    bool flag = await requestStoragePermission();
    setState(() {
      isPermissionGranted = flag;
    });
  }

  // 平台消息是异步的，因此我们使用异步方法进行初始化。
  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    // 平台消息可能会失败，因此我们使用try/catch PlatformException。
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      developer.log('Couldn\'t check connectivity status', error: e);
      return;
    }

    // 如果在异步平台消息运行时从树中删除了小部件，希望是丢弃回复，而不是调用setState来更新我们不存在的外观。
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  Future<void> _loadDishData() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    CusDataResult temp = await _dbHelper.queryDishList(
      dishName: query,
      page: currentPage,
      pageSize: pageSize,
    );

    var newData = temp.data as List<Dish>;

    setState(() {
      dishItems.addAll(newData);
      itemsCount = temp.total;

      currentPage++;
      isLoading = false;
    });
  }

  void _scrollListener() {
    if (isLoading) return;

    final maxScrollExtent = scrollController.position.maxScrollExtent;
    final currentPosition = scrollController.position.pixels;
    final delta = 50.0.sp;

    if (maxScrollExtent - currentPosition <= delta) {
      // 2024-03-22 没有达到最大值时滚动才加载更多
      if (itemsCount > dishItems.length) {
        _loadDishData();
      }
    }
  }

  void _handleSearch() {
    setState(() {
      dishItems.clear();
      currentPage = 1;
      query = searchController.text;
    });
    // 在当前上下文中查找最近的 FocusScope 并使其失去焦点，从而收起键盘。
    FocusScope.of(context).unfocus();

    _loadDishData();
  }

  // 进入json文件导入前，先获取权限
  clickExerciseImport() {
    // 用户授权了访问内部存储权限，可以跳转到导入
    if (isPermissionGranted) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DishJsonImport(),
        ),
      ).then((value) {
        setState(() {
          dishItems.clear();
          currentPage = 1;
        });
        _loadDishData();
      });
    } else {
      showSnackMessage(context, "无权访问内部存储！");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "菜品",
                style: TextStyle(
                  fontSize: 20.sp,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              TextSpan(
                text: "\n数量 $itemsCount 已加载 ${dishItems.length}",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.bug_report),
          //   onPressed: () {
          //     insertDemoDish(size: 5);

          //     setState(() {
          //       dishItems.clear();
          //       currentPage = 1;
          //     });
          //     _loadDishData();
          //   },
          // ),
          IconButton(
            icon: Icon(isDishCardList ? Icons.list : Icons.grid_3x3),
            onPressed: () {
              // 如果不是卡片列表，不是wifi状态 但要切到卡片列表
              if (!isDishCardList &&
                  !(_connectionStatus.contains(ConnectivityResult.wifi))) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("流量预警"),
                      content: const Text(
                        "当前非wifi环境，切换卡片列表会加载图片，注意流量消耗!\n网络图片会优先使用本地缓存。",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: const Text("取消"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: const Text("确认"),
                        ),
                      ],
                    );
                  },
                ).then((value) {
                  if (value == true) {
                    setState(() {
                      isDishCardList = !isDishCardList;
                    });
                  }
                });
              } else {
                // 是wifi的话切来切去无所谓的
                setState(() {
                  isDishCardList = !isDishCardList;
                });
              }
            },
          ),
          // 导入
          /// 导入json文件
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: clickExerciseImport,
          ),
          // 新增
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DishModify(),
                ),
              ).then((value) {
                if (value != null && value == true) {
                  setState(() {
                    dishItems.clear();
                    currentPage = 1;
                  });
                  _loadDishData();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.sp),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "菜品名称关键字",
                      // 设置透明底色
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _handleSearch,
                  child: const Text("搜索"),
                ),
              ],
            ),
          ),
          Expanded(
            child: isDishCardList
                ? buildDishCardList(dishItems)
                : builDishTileList(dishItems),
          ),
        ],
      ),
    );
  }

  /// 卡片列表形式的菜品信息
  buildDishCardList(List<Dish> dishes) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 4, // 初始卡片宽高比例
      ),
      itemCount: dishes.length, // 假设有10个菜谱
      itemBuilder: (context, index) {
        if (index == dishItems.length) {
          return buildLoader(isLoading);
        }

        Dish dish = dishes[index];

        List<String> imageList = [];
        // 先要排除image是个空字符串在分割
        if (dish.photos != null && dish.photos!.trim().isNotEmpty) {
          imageList = dish.photos!.split(",");
        }

        // 获取菜品图片
        var imageUrl = imageList.isNotEmpty ? imageList[0] : null;

        return InkWell(
          // 点击跳转菜品详情
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DishDetail(dishItem: dish),
              ),
            ).then((value) {
              // 从详情页返回后需要重新查询，因为不知道在内部是不是有变动单份营养素。
              // 有变动，退出不刷新，再次进入还是能看到旧的；但是返回就刷新对于只是浏览数据不友好。
              // 因此，详情页会有一个是否被异动的标志，返回true则重新查询；否则就不更新
              if (value != null && value == true) {
                setState(() {
                  dishItems.clear();
                  currentPage = 1;
                });
                _loadDishData();
              }
            });
          },
          // 长按点击弹窗提示是否删除
          onLongPress: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("是否删除该菜品？"),
                  content: Text("菜品名称：${dish.dishName}"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false);
                      },
                      child: const Text("取消"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text("确认"),
                    ),
                  ],
                );
              },
            ).then((value) async {
              if (value != null && value) {
                try {
                  await _dbHelper.deleteDishById(dish.dishId);

                  // 删除后重新查询
                  setState(() {
                    dishItems.clear();
                    currentPage = 1;
                  });
                  _loadDishData();
                } catch (e) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  commonExceptionDialog(context, "异常提醒", e.toString());
                }
              }
            });
          },
          child: Card(
            elevation: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 2024-04-09 使用expanded，会使得描述不一样行数时，拉高图片，减少空白；
                // Expanded(
                //   child: AspectRatio(
                //     aspectRatio: 4 / 3, // 设置图片宽高比例
                //     child: imageUrl == null
                //         ? Image.asset(placeholderImageUrl,
                //             fit: BoxFit.scaleDown)
                //         : buildNetworkOrFileImage(imageUrl, fit: BoxFit.cover),
                //   ),
                // ),
                // 如果没有，则图片都一样大，可能有不少空白
                AspectRatio(
                  aspectRatio: 4 / 3, // 设置图片宽高比例
                  child: imageUrl == null
                      ? Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown)
                      : buildNetworkOrFileImage(imageUrl, fit: BoxFit.cover),
                ),
                Padding(
                  padding: EdgeInsets.all(5.0.sp),
                  child: Text(
                    dish.dishName,
                    style: TextStyle(
                      fontSize: 15.0.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(5.sp, 0, 5.0.sp, 5.0.sp),
                  child: Text(
                    "${dish.description}",
                    style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      controller: scrollController,
    );
  }

  /// 列表形式的菜品信息(列表没有预览图，更省流量)
  builDishTileList(List<Dish> dishes) {
    return ListView.builder(
      itemCount: dishes.length + 1,
      itemBuilder: (context, index) {
        if (index == dishes.length) {
          return buildLoader(isLoading);
        } else {
          Dish dish = dishes[index];

          // 先排除原本就是空字符串
          var initTags = (dish.tags != null && dish.tags!.trim().isNotEmpty)
              ? dish.tags!.trim().split(",")
              : [];

          var initCates = (dish.mealCategories != null &&
                  dish.mealCategories!.trim().isNotEmpty)
              ? dish.mealCategories!.trim().split(",")
              : [];

          return Card(
            elevation: 5,
            child: Column(
              children: [
                ListTile(
                  // 菜品名称
                  title: Text(
                    "${index + 1} - ${dish.dishName}",
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  // 菜品简介
                  subtitle: Text(
                    "${dish.description}",
                    style: TextStyle(fontSize: 12.sp),
                    maxLines: 3,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 点击跳转菜品详情
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DishDetail(dishItem: dish),
                      ),
                    ).then((value) {
                      // 从详情页返回后需要重新查询，因为不知道在内部是不是有变动单份营养素。
                      // 有变动，退出不刷新，再次进入还是能看到旧的；但是返回就刷新对于只是浏览数据不友好。
                      // 因此，详情页会有一个是否被异动的标志，返回true则重新查询；否则就不更新
                      if (value != null && value == true) {
                        setState(() {
                          dishItems.clear();
                          currentPage = 1;
                        });
                        _loadDishData();
                      }
                    });
                  },
                  // 长按点击弹窗提示是否删除
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("是否删除该菜品？"),
                          content: Text("菜品名称：${dish.dishName}"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, false);
                              },
                              child: const Text("取消"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              child: const Text("确认"),
                            ),
                          ],
                        );
                      },
                    ).then((value) async {
                      if (value != null && value) {
                        try {
                          await _dbHelper.deleteDishById(dish.dishId);

                          // 删除后重新查询
                          setState(() {
                            dishItems.clear();
                            currentPage = 1;
                          });
                          _loadDishData();
                        } catch (e) {
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          commonExceptionDialog(context, "异常提醒", e.toString());
                        }
                      }
                    });
                  },
                ),

                /// Wrap最小高度48吧，调不了，在外面限制一个box高度
                // 2024-03-10 分类和餐次各占一行吧，但这样列表太高了，不好看
                SizedBox(
                  height: 28.sp,
                  child: Wrap(
                    // spacing: 5,
                    alignment: WrapAlignment.spaceAround,
                    children: [
                      ...[
                        // 如果标签很多，只显示4个，然后整体剩下的用一个数字代替
                        ...initCates
                            .map((mood) {
                              return buildSmallButtonTag(
                                mood,
                                bgColor: Colors.lightBlue,
                                labelTextSize: 12,
                              );
                            })
                            .toList()
                            .sublist(
                              0,
                              initCates.length > 4 ? 4 : initCates.length,
                            ),
                      ],
                      if (initCates.length > 4)
                        buildSmallButtonTag(
                          '+${initCates.length - 4}',
                          bgColor: Colors.grey,
                          labelTextSize: 12,
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 28.sp,
                  child: Wrap(
                    // spacing: 5,
                    alignment: WrapAlignment.spaceAround,
                    children: [
                      ...[
                        // 如果标签很多，只显示4个，然后整体剩下的用一个数字代替
                        ...initTags
                            .map((tag) {
                              return buildSmallButtonTag(
                                tag,
                                bgColor: Colors.lightGreen,
                                labelTextSize: 12,
                              );
                            })
                            .toList()
                            .sublist(
                              0,
                              initTags.length > 4 ? 4 : initTags.length,
                            ),
                      ],
                      if (initTags.length > 4)
                        buildSmallButtonTag(
                          '+${initTags.length - 4}',
                          bgColor: Colors.grey,
                          labelTextSize: 12,
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 20.sp)
              ],
            ),
          );
        }
      },
      controller: scrollController,
    );
  }
}
