import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/transaction.dart';
import 'sms_parser.dart';
import 'category_detector.dart';
import '../repositories/transaction_repository.dart';

class SmsSyncService {
  final TransactionRepository _transactionRepo;
  final CategoryDetector _categoryDetector;
  final List<String> _bankSenders;

  SmsSyncService(this._transactionRepo, this._categoryDetector, this._bankSenders);

  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<int> syncSmsMessages() async {
    if (!await Permission.sms.isGranted) {
      final granted = await requestPermission();
      if (!granted) return 0;
    }

    final messages = await _fetchMessages();
    int newCount = 0;

    for (final message in messages) {
      final address = message.address ?? '';
      if (!BankSmsParser.isBankSms(address, _bankSenders)) continue;

      final transaction = BankSmsParser.parse(message.body ?? '', address);
      if (transaction == null) continue;

      if (await _transactionRepo.isDuplicate(transaction.rawText ?? '')) continue;

      transaction.category = _categoryDetector.detect(transaction.merchant);
      await _transactionRepo.addTransaction(transaction);
      newCount++;
    }

    return newCount;
  }

  Future<List<SmsMessage>> _fetchMessages() async {
    final SmsQuery query = SmsQuery();
    final messages = await query.getAllSms;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    return messages.where((msg) {
      final date = msg.date;
      if (date == null) return false;
      return date.isAfter(thirtyDaysAgo);
    }).toList();
  }
}
