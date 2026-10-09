import '../models/transaction.dart';

class CategoryDetector {
  static const Map<String, List<String>> _keywords = {
    'food': [
      'cafe', 'coffee', 'restaurant', 'pizza', 'burger', 'juice', 'lunch', 'dinner',
      'kaldi', 'tomoca', 'food', 'eat', 'meal', 'breakfast', 'snack', 'grocery',
      'supermarket', 'market', 'bakery', ' confectionery'
    ],
    'transport': [
      'taxi', 'ride', 'fuel', 'benzine', 'bus', 'bolt', 'uber', 'car', 'gas',
      'transport', 'fare', 'trip', 'journey', 'petrol', 'diesel'
    ],
    'shopping': [
      'supermarket', 'shola', 'fantu', 'mariam', 'shop', 'mart', 'mall',
      'store', 'buy', 'purchase', 'retail', 'clothing', 'fashion'
    ],
    'bills': [
      'ethio telecom', 'etu', 'water', 'rent', 'insurance', 'safaricom',
      'electricity', 'bill', 'payment', 'airtime', 'data', 'internet'
    ],
    'subscription': [
      'netflix', 'spotify', 'youtube', 'dstv', 'vpn', 'icloud', 'amazon',
      'prime', 'disney', 'hulu', 'subscription', 'monthly', 'annual'
    ],
    'entertainment': [
      'cinema', 'movie', 'game', 'concert', 'club', 'bar', 'pub', 'sport',
      'fitness', 'gym', 'music', 'entertainment', 'leisure'
    ],
  };

  TransactionCategory detect(String merchant) {
    final lowerMerchant = merchant.toLowerCase();

    for (final entry in _keywords.entries) {
      final categoryName = entry.key;
      final keywords = entry.value;

      for (final keyword in keywords) {
        if (lowerMerchant.contains(keyword)) {
          return _categoryFromString(categoryName);
        }
      }
    }

    final fuzzyMatch = _fuzzyMatch(lowerMerchant);
    if (fuzzyMatch != null) {
      return fuzzyMatch;
    }

    return TransactionCategory.other;
  }

  TransactionCategory? _fuzzyMatch(String merchant) {
    for (final entry in _keywords.entries) {
      final keywords = entry.value;

      for (final keyword in keywords) {
        if (_levenshteinDistance(merchant, keyword) <= 3) {
          return _categoryFromString(entry.key);
        }
      }
    }
    return null;
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> prevRow = List<int>.generate(s2.length + 1, (i) => i);
    List<int> currentRow = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      currentRow[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        int insertions = prevRow[j + 1] + 1;
        int deletions = currentRow[j] + 1;
        int substitutions = prevRow[j] + (s1[i] == s2[j] ? 0 : 1);

        currentRow[j + 1] = [insertions, deletions, substitutions].reduce((a, b) => a < b ? a : b);
      }

      final temp = prevRow;
      prevRow = currentRow;
      currentRow = temp;
    }

    return prevRow[s2.length];
  }

  static TransactionCategory _categoryFromString(String name) {
    switch (name) {
      case 'food':
        return TransactionCategory.food;
      case 'transport':
        return TransactionCategory.transport;
      case 'shopping':
        return TransactionCategory.shopping;
      case 'bills':
        return TransactionCategory.bills;
      case 'subscription':
        return TransactionCategory.subscription;
      case 'entertainment':
        return TransactionCategory.entertainment;
      default:
        return TransactionCategory.other;
    }
  }
}
