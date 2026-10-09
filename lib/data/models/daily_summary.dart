import 'package:hive/hive.dart';
import 'transaction.dart';

class DailySummaryAdapter extends TypeAdapter<DailySummary> {
  @override
  final int typeId = 4;

  @override
  DailySummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailySummary()
      ..date = fields[0] as DateTime
      ..totalSpent = fields[1] as double
      ..totalWasted = fields[2] as double
      ..transactionCount = fields[3] as int
      ..topCategoryIndex = fields[4] as int?;
  }

  @override
  void write(BinaryWriter writer, DailySummary obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.totalSpent)
      ..writeByte(2)
      ..write(obj.totalWasted)
      ..writeByte(3)
      ..write(obj.transactionCount)
      ..writeByte(4)
      ..write(obj.topCategoryIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailySummary extends HiveObject {
  late DateTime date;
  late double totalSpent;
  late double totalWasted;
  late int transactionCount;
  int? topCategoryIndex;
}
