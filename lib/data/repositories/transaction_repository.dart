import 'package:isar/isar.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final Isar _isar;

  TransactionRepository(this._isar);

  Future<List<Transaction>> getAllTransactions() async {
    return await _isar.transactions.where().sortByTimestampDesc().findAll();
  }

  Stream<List<Transaction>> watchAllTransactions() {
    return _isar.transactions.where().sortByTimestampDesc().watch(fireImmediately: true);
  }

  Future<List<Transaction>> getTransactionsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return await _isar.transactions
        .filter()
        .dateBetween(startOfDay, endOfDay, includeUpper: false)
        .sortByTimestampDesc()
        .findAll();
  }

  Stream<List<Transaction>> watchTransactionsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _isar.transactions
        .filter()
        .dateBetween(startOfDay, endOfDay, includeUpper: false)
        .sortByTimestampDesc()
        .watch(fireImmediately: true);
  }

  Future<List<Transaction>> getTransactionsForDateRange(DateTime start, DateTime end) async {
    return await _isar.transactions
        .filter()
        .dateBetween(start, end)
        .sortByTimestampDesc()
        .findAll();
  }

  Future<List<Transaction>> getTransactionsForWeek(DateTime date) async {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));
    return await _isar.transactions
        .filter()
        .dateBetween(start, end)
        .sortByTimestampDesc()
        .findAll();
  }

  Future<List<Transaction>> getTransactionsForMonth(DateTime date) async {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 1);
    return await _isar.transactions
        .filter()
        .dateBetween(start, end)
        .sortByTimestampDesc()
        .findAll();
  }

  Future<void> addTransaction(Transaction transaction) async {
    transaction.date = DateTime(
      transaction.timestamp.year,
      transaction.timestamp.month,
      transaction.timestamp.day,
    );
    await _isar.writeTxn(() async {
      await _isar.transactions.put(transaction);
    });
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _isar.writeTxn(() async {
      await _isar.transactions.put(transaction);
    });
  }

  Future<void> deleteTransaction(int id) async {
    await _isar.writeTxn(() async {
      await _isar.transactions.delete(id);
    });
  }

  Future<bool> isDuplicate(String rawText) async {
    if (rawText.isEmpty) return false;
    final existing = await _isar.transactions
        .filter()
        .rawTextEqualTo(rawText)
        .findFirst();
    return existing != null;
  }

  Future<int> getTransactionCount() async {
    return await _isar.transactions.count();
  }

  Future<double> getTotalSpentForDate(DateTime date) async {
    final transactions = await getTransactionsForDate(date);
    return transactions.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Future<double> getTotalWastedForDate(DateTime date) async {
    final transactions = await getTransactionsForDate(date);
    return transactions
        .where((tx) => tx.isWaste)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }
}
