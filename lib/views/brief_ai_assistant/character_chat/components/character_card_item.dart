import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import '../../../../models/brief_ai_tools/character_chat/character_card.dart';

class CharacterCardItem extends StatelessWidget {
  final CharacterCard character;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CharacterCardItem({
    super.key,
    required this.character,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 角色头像
            avatarArea(),

            SizedBox(height: 4.sp),

            // 角色信息
            infoArea(),
          ],
        ),
      ),
    );
  }

  Widget avatarArea() {
    return Expanded(
      flex: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.sp),
          topRight: Radius.circular(12.sp),
        ),
        child: _buildAvatar(),
      ),
    );
  }

  Widget infoArea() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 角色名称和系统标签
            Row(
              children: [
                Expanded(
                  child: Text(
                    character.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (character.isSystem)
                  Container(
                    padding: EdgeInsets.all(2.sp),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.sp),
                    ),
                    child: Text(
                      '系统',
                      style: TextStyle(fontSize: 10.sp, color: Colors.blue),
                    ),
                  ),
              ],
            ),

            // 角色描述
            Expanded(
              child: Text(
                character.description,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 18.sp),
                  // padding: EdgeInsets.zero,
                  // constraints: BoxConstraints(),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18.sp),
                  // padding: EdgeInsets.zero,
                  // constraints: BoxConstraints(),
                  onPressed: character.isSystem ? null : onDelete,
                  color: character.isSystem ? Colors.grey : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (character.avatar.startsWith('assets/')) {
      return Image.asset(
        character.avatar,
        fit: BoxFit.cover,
      );
    } else if (character.avatar.startsWith('/')) {
      return Image.file(
        File(character.avatar),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Icon(
              Icons.person,
              size: 50.sp,
              color: Colors.grey[600],
            ),
          );
        },
      );
    } else {
      return Container(
        color: Colors.grey[300],
        child: Icon(
          Icons.person,
          size: 50.sp,
          color: Colors.grey[600],
        ),
      );
    }
  }
}
