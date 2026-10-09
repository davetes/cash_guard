import 'package:flutter_test/flutter_test.dart';
import 'package:cash_guardian/data/services/category_detector.dart';
import 'package:cash_guardian/data/models/transaction.dart';

void main() {
  late CategoryDetector detector;

  setUp(() {
    detector = CategoryDetector();
  });

  group('CategoryDetector', () {
    group('detect', () {
      group('food', () {
        test('detects cafe', () {
          expect(detector.detect('Kaldi Cafe'), TransactionCategory.food);
          expect(detector.detect('Tomoca Coffee'), TransactionCategory.food);
        });

        test('detects restaurant', () {
          expect(detector.detect('Addis Restaurant'), TransactionCategory.food);
          expect(detector.detect('Yohannes Pizza'), TransactionCategory.food);
        });

        test('detects burger places', () {
          expect(detector.detect('Burger King'), TransactionCategory.food);
          expect(detector.detect('Hamburger House'), TransactionCategory.food);
        });

        test('detects grocery and market', () {
          expect(detector.detect('Shola Supermarket'), TransactionCategory.food);
          expect(detector.detect('Fantu Grocery'), TransactionCategory.food);
        });
      });

      group('transport', () {
        test('detects taxi and ride', () {
          expect(detector.detect('Taxi Service'), TransactionCategory.transport);
          expect(detector.detect('Ride Share'), TransactionCategory.transport);
        });

        test('detects fuel and gas', () {
          expect(detector.detect('Fuel Station'), TransactionCategory.transport);
          expect(detector.detect('Benzine Shop'), TransactionCategory.transport);
        });

        test('detects ride sharing apps', () {
          expect(detector.detect('Bolt Ride'), TransactionCategory.transport);
          expect(detector.detect('Uber Trip'), TransactionCategory.transport);
        });

        test('detects bus', () {
          expect(detector.detect('Bus Ticket'), TransactionCategory.transport);
        });
      });

      group('shopping', () {
        test('detects shopping terms', () {
          expect(detector.detect('Shopping Mall'), TransactionCategory.shopping);
          expect(detector.detect('Clothing Store'), TransactionCategory.shopping);
        });

        test('detects supermarket', () {
          expect(detector.detect('Super Mart'), TransactionCategory.shopping);
        });
      });

      group('bills', () {
        test('detects ethio telecom', () {
          expect(detector.detect('Ethio Telecom'), TransactionCategory.bills);
        });

        test('detects utilities', () {
          expect(detector.detect('EEU Bill'), TransactionCategory.bills);
          expect(detector.detect('Water Service'), TransactionCategory.bills);
        });

        test('detects insurance', () {
          expect(detector.detect('Insurance Payment'), TransactionCategory.bills);
        });
      });

      group('subscription', () {
        test('detects streaming services', () {
          expect(detector.detect('Netflix'), TransactionCategory.subscription);
          expect(detector.detect('Spotify'), TransactionCategory.subscription);
          expect(detector.detect('YouTube Premium'), TransactionCategory.subscription);
        });

        test('detects dstv', () {
          expect(detector.detect('DSTV Payment'), TransactionCategory.subscription);
        });

        test('detects vpn', () {
          expect(detector.detect('VPN Subscription'), TransactionCategory.subscription);
        });
      });

      group('entertainment', () {
        test('detects cinema and movies', () {
          expect(detector.detect('Cinema'), TransactionCategory.entertainment);
          expect(detector.detect('Movie Theater'), TransactionCategory.entertainment);
        });

        test('detects games', () {
          expect(detector.detect('Game Center'), TransactionCategory.entertainment);
        });

        test('detects concerts', () {
          expect(detector.detect('Concert Ticket'), TransactionCategory.entertainment);
        });
      });

      group('other', () {
        test('returns other for unknown merchants', () {
          expect(detector.detect('Random Store'), TransactionCategory.other);
          expect(detector.detect('XYZ Company'), TransactionCategory.other);
        });

        test('handles case insensitivity', () {
          expect(detector.detect('NETFLIX'), TransactionCategory.subscription);
          expect(detector.detect('cafÃ©'), TransactionCategory.food);
        });
      });
    });

    group('fuzzy matching', () {
      test('matches with Levenshtein distance <= 3', () {
        expect(detector.detect('Nettflix'), TransactionCategory.subscription);
        expect(detector.detect('Spotfy'), TransactionCategory.subscription);
        expect(detector.detect('Cinee'), TransactionCategory.entertainment);
      });

      test('does not match with distance > 3', () {
        expect(detector.detect('Netfliixxxxx'), TransactionCategory.other);
      });
    });
  });
}
