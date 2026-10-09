import 'package:hive/hive.dart';
import 'transaction.dart';

class TransactionCategoryAdapter extends TypeAdapter<TransactionCategory> {
  @override
  final int typeId = 0;

  @override
  TransactionCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionCategory.food;
      case 1:
        return TransactionCategory.transport;
      case 2:
        return TransactionCategory.shopping;
      case 3:
        return TransactionCategory.bills;
      case 4:
        return TransactionCategory.subscription;
      case 5:
        return TransactionCategory.entertainment;
      case 6:
        return TransactionCategory.other;
      default:
        return TransactionCategory.other;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionCategory obj) {
    switch (obj) {
      case TransactionCategory.food:
        writer.writeByte(0);
        break;
      case TransactionCategory.transport:
        writer.writeByte(1);
        break;
      case TransactionCategory.shopping:
        writer.writeByte(2);
        break;
      case TransactionCategory.bills:
        writer.writeByte(3);
        break;
      case TransactionCategory.subscription:
        writer.writeByte(4);
        break;
      case TransactionCategory.entertainment:
        writer.writeByte(5);
        break;
      case TransactionCategory.other:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionSourceAdapter extends TypeAdapter<TransactionSource> {
  @override
  final int typeId = 1;

  @override
  TransactionSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionSource.sms;
      case 1:
        return TransactionSource.manual;
      case 2:
        return TransactionSource.receipt;
      default:
        return TransactionSource.manual;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionSource obj) {
    switch (obj) {
      case TransactionSource.sms:
        writer.writeByte(0);
        break;
      case TransactionSource.manual:
        writer.writeByte(1);
        break;
      case TransactionSource.receipt:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 2;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction()
      ..amount = fields[0] as double
      ..merchant = fields[1] as String
      ..category = fields[2] as TransactionCategory
      ..timestamp = fields[3] as DateTime
      ..source = fields[4] as TransactionSource
      ..isWaste = fields[5] as bool
      ..wasteReason = fields[6] as String?
      ..rawText = fields[7] as String?
      ..date = fields[8] as DateTime;
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.merchant)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.source)
      ..writeByte(5)
      ..write(obj.isWaste)
      ..writeByte(6)
      ..write(obj.wasteReason)
      ..writeByte(7)
      ..write(obj.rawText)
      ..writeByte(8)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
