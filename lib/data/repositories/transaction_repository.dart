import 'package:hive/hive.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final Box<Transaction> _box;

  TransactionRepository(this._box);

  List<Transaction> getAllTransactions() {
    return _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Stream<List<Transaction>> watchAllTransactions() {
    return _box.watch().map((_) => getAllTransactions());
  }

  List<Transaction> getTransactionsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _box.values
        .where((tx) =>
            tx.timestamp.isAfter(startOfDay) && tx.timestamp.isBefore(endOfDay))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Stream<List<Transaction>> watchTransactionsForDate(DateTime date) {
    return _box.watch().map((_) => getTransactionsForDate(date));
  }

  List<Transaction> getTransactionsForDateRange(DateTime start, DateTime end) {
    return _box.values
        .where((tx) => tx.timestamp.isAfter(start) && tx.timestamp.isBefore(end))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<Transaction> getTransactionsForWeek(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));
    return getTransactionsForDateRange(start, end);
  }

  List<Transaction> getTransactionsForMonth(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 1);
    return getTransactionsForDateRange(start, end);
  }

  Future<void> addTransaction(Transaction transaction) async {
    transaction.date = DateTime(
      transaction.timestamp.year,
      transaction.timestamp.month,
      transaction.timestamp.day,
    );
    await _box.add(transaction);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await transaction.save();
  }

  Future<void> deleteTransaction(int index) async {
    await _box.deleteAt(index);
  }

  bool isDuplicate(String rawText) {
    if (rawText.isEmpty) return false;
    return _box.values.any((tx) => tx.rawText == rawText);
  }

  int getTransactionCount() {
    return _box.length;
  }

  double getTotalSpentForDate(DateTime date) {
    final transactions = getTransactionsForDate(date);
    return transactions.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getTotalWastedForDate(DateTime date) {
    final transactions = getTransactionsForDate(date);
    return transactions
        .where((tx) => tx.isWaste)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }
}
