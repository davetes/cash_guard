import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  late String name;

  late int iconCode;

  late String colorHex;

  double? dailyBudget;
}
