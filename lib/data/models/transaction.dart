import 'package:isar/isar.dart';

part 'transaction.g.dart';

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

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  late double amount;

  late String merchant;

  @enumerated
  late TransactionCategory category;

  late DateTime timestamp;

  @enumerated
  late TransactionSource source;

  late bool isWaste;

  String? wasteReason;

  String? rawText;

  @Index()
  late DateTime date;
}
