// 食物
class Dish {
  String dishId; // 用uuid生成
  String dishName; // 名称
  String? description; // 一两句的介绍描述
  String? recipe; // 菜谱
  // 2024-03-22 输入菜谱可能太慢了，可以拍照片，但固定只能一张照片
  String? recipePicture; // 菜谱照片地址
  // 照片、类型、餐次一个食物可以对应多个
  String? photos; // 食物照片。实际照片缓存内部或者网页照片，这里是地址列表
  String? videos; // 食物视频。这里是地址，外部访问
  String? tags; // 食物类型，比如凉菜、汤菜、煎、炒、烹、炸、焖、溜、熬、炖、汆等
  String? mealCategories; // 早餐、午餐、下午茶、晚餐、夜宵、甜点

  Dish({
    required this.dishId,
    required this.dishName,
    this.description,
    this.photos,
    this.videos,
    this.tags,
    this.mealCategories,
    this.recipe,
    this.recipePicture,
  });

  Map<String, dynamic> toMap() {
    return {
      'dish_id': dishId,
      'dish_name': dishName,
      'description': description,
      'photos': photos,
      'videos': videos,
      'tags': tags,
      'meal_categories': mealCategories,
      'recipe': recipe,
      'recipe_picture': recipePicture,
    };
  }

// 用于从数据库行映射到 ServingInfo 对象的 fromMap 方法
  factory Dish.fromMap(Map<String, dynamic> map) {
    return Dish(
      dishId: map['dish_id'] as String,
      dishName: map['dish_name'] as String,
      description: map['description'] as String?,
      photos: map['photos'] as String?,
      videos: map['videos'] as String?,
      tags: map['tags'] as String?,
      mealCategories: map['meal_categories'] as String?,
      recipe: map['recipe'] as String?,
      recipePicture: map['recipe_picture'] as String?,
    );
  }

  @override
  String toString() {
    return '''
    Food{
      dishId: $dishId, dishName: $dishName, description:$description, 
      photos: $photos, videos: $videos, recipePicture: $recipePicture,
      tags: $tags, mealCategories: $mealCategories, recipe: $recipe,
    }
    ''';
  }
}

/// json 文件转换时对应的类

class JsonFileDish {
  String? dishId; // 用uuid生成 (就是上面的food，后面再改)
  String? dishName; // 名称
  String? description; // 一两句的介绍描述
  // 照片、类型、餐次一个食物可以对应多个
  String? tags; // 食物类型，比如凉菜、汤菜、煎、炒、烹、炸、焖、溜、熬、炖、汆等
  String? mealCategories; // 早餐、午餐、下午茶、晚餐、夜宵、甜点
  List<String>? recipe; // 菜谱,用字符串数组装步骤了
  // 2024-03-22 输入菜谱可能太慢了，可以拍照片，但固定只能一张照片
  String? recipePicture; // 菜谱照片地址
  List<String>? images; // 食物照片。照片地址也用字符串数组
  List<String>? videos; // 食物视频。视频地址也用字符串数组

  JsonFileDish({
    this.dishId,
    this.dishName,
    this.description,
    this.tags,
    this.mealCategories,
    this.recipe,
    this.recipePicture,
    this.images,
    this.videos,
  });

  JsonFileDish.fromJson(Map<String, dynamic> json) {
    dishId = json['dish_id'];
    dishName = json['dish_name'] ?? "";
    description = json['description'];
    tags = json['tags'];
    mealCategories = json['meal_categories'];
    recipe = json['recipe']?.cast<String>();
    recipePicture = json['recipe_picture'];
    images = json['images']?.cast<String>();
    videos = json['videos']?.cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['dish_id'] = dishId;
    data['dish_name'] = dishName;
    data['description'] = description;
    data['tags'] = tags;
    data['meal_categories'] = mealCategories;
    data['recipe'] = recipe;
    data['recipe_picture'] = recipePicture;
    data['images'] = images;
    data['videos'] = videos;

    return data;
  }
}
