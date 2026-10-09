import '../models/transaction.dart';

class BankSmsParser {
  static final RegExp _transferPattern = RegExp(
    r'You have transferred\s+ETB\s+([\d,]+\.?\d*)\s+to\s+(.+?)(?:\s*on|\s*at|\s*$)',
    caseSensitive: false,
  );

  static final RegExp _debitedPattern = RegExp(
    r'account\s+has\s+been\s+debited\s+with\s+ETB\s+([\d,]+\.?\d*)',
    caseSensitive: false,
  );

  static final RegExp _paidPattern = RegExp(
    r'You\s+have\s+paid\s+ETB\s+([\d,]+\.?\d*)\s+to\s+(.+?)(?:\s*for|\s*on|\s*at|\s*$)',
    caseSensitive: false,
  );

  static final RegExp _telebirrSentPattern = RegExp(
    r'Telebirr:?\s*You\s+have\s+sent\s+ETB\s+([\d,]+\.?\d*)\s+to\s+(.+?)(?:\s*on|\s*at|\s*$)',
    caseSensitive: false,
  );

  static final RegExp _mpesaReceivedPattern = RegExp(
    r'You\s+have\s+received\s+ETB\s+([\d,]+\.?\d*)\s+from\s+(.+?)(?:\s*on|\s*at|\s*$)',
    caseSensitive: false,
  );

  static final RegExp _cbeDebitPattern = RegExp(
    r'ETB\s+([\d,]+\.?\d*)\s+debited\s+from\s+your\s+account',
    caseSensitive: false,
  );

  static Transaction? parse(String sms, String sender) {
    final cleanSms = sms.trim();
    double? amount;
    String? merchant;
    DateTime timestamp = DateTime.now();

    final amountMatch = _extractAmount(cleanSms);
    if (amountMatch != null) {
      amount = amountMatch;
    } else {
      return null;
    }

    merchant = _extractMerchant(cleanSms, sender);

    if (amount == null || amount <= 0) {
      return null;
    }

    return Transaction()
      ..amount = amount
      ..merchant = merchant
      ..category = TransactionCategory.other
      ..timestamp = timestamp
      ..source = TransactionSource.sms
      ..isWaste = false
      ..rawText = '$sender|$cleanSms';
  }

  static double? _extractAmount(String sms) {
    List<RegExp> patterns = [
      _transferPattern,
      _debitedPattern,
      _paidPattern,
      _telebirrSentPattern,
      _mpesaReceivedPattern,
      _cbeDebitPattern,
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(sms);
      if (match != null && match.groupCount >= 1) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }
    return null;
  }

  static String _extractMerchant(String sms, String sender) {
    final transferMatch = _transferPattern.firstMatch(sms);
    if (transferMatch != null && transferMatch.groupCount >= 2) {
      return transferMatch.group(2)?.trim() ?? sender;
    }

    final paidMatch = _paidPattern.firstMatch(sms);
    if (paidMatch != null && paidMatch.groupCount >= 2) {
      return paidMatch.group(2)?.trim() ?? sender;
    }

    final telebirrMatch = _telebirrSentPattern.firstMatch(sms);
    if (telebirrMatch != null && telebirrMatch.groupCount >= 2) {
      return telebirrMatch.group(2)?.trim() ?? 'Telebirr';
    }

    final mpesaMatch = _mpesaReceivedPattern.firstMatch(sms);
    if (mpesaMatch != null && mpesaMatch.groupCount >= 2) {
      return mpesaMatch.group(2)?.trim() ?? 'M-Pesa';
    }

    return sender;
  }

  static bool isBankSms(String sender, List<String> knownBanks) {
    final upperSender = sender.toUpperCase();
    for (final bank in knownBanks) {
      if (upperSender.contains(bank.toUpperCase())) {
        return true;
      }
    }
    return false;
  }
}
