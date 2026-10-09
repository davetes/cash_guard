import 'package:hive/hive.dart';

enum TransactionCategory {
  food,
  transport,
  shopping,
  bills,
  subscription,
  entertainment,
  other,
}

enum TransactionSource {
  sms,
  manual,
  receipt,
}

class Transaction extends HiveObject {
  late double amount;
  late String merchant;
  late TransactionCategory category;
  late DateTime timestamp;
  late TransactionSource source;
  late bool isWaste;
  String? wasteReason;
  String? rawText;
  late DateTime date;
}
