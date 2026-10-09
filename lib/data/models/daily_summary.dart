import 'package:isar/isar.dart';

part 'daily_summary.g.dart';

@collection
class DailySummary {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime date;

  late double totalSpent;

  late double totalWasted;

  late int transactionCount;

  int? topCategoryIndex;
}
