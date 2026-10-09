import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class CategoryIcon extends StatelessWidget {
  final dynamic category;
  final double size;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    String categoryName;
    if (category is String) {
      categoryName = category;
    } else {
      categoryName = category.name;
    }

    final colorHex = AppConstants.categoryColors[categoryName] ?? 0xFF607D8B;
    final iconCode = AppConstants.categoryIcons[categoryName] ?? 0xe8fe;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(colorHex).withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        IconData(iconCode, fontFamily: 'MaterialIcons'),
        color: Color(colorHex),
        size: size * 0.5,
      ),
    );
  }
}
