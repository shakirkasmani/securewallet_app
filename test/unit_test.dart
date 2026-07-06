import 'package:flutter_test/flutter_test.dart';
import 'package:credit_card_app/models/credit_card.dart';

void main() {
  group('CreditCard Model Tests', () {
    test('Detect Card Brand correctly', () {
      expect(CreditCard.detectBrand('4111 2222 3333 4444'), CardBrand.visa);
      expect(CreditCard.detectBrand('5105 1234 5678 9012'), CardBrand.mastercard);
      expect(CreditCard.detectBrand('3782 822463 10005'), CardBrand.amex);
      expect(CreditCard.detectBrand('6011 1111 2222 3333'), CardBrand.discover);
      expect(CreditCard.detectBrand('1234 5678 9012 3456'), CardBrand.unknown);
    });

    test('Format Card Number correctly with spaces (Visa/Mastercard)', () {
      final card = CreditCard(
        id: '1',
        cardNumber: '4111222233334444',
        cardHolder: 'John Doe',
        expiryDate: '12/29',
        cvv: '123',
        brand: CardBrand.visa,
        cardStyleIndex: 0,
      );
      expect(card.formattedCardNumber, '4111 2222 3333 4444');
    });

    test('Format Amex Card Number correctly (4-6-5 format)', () {
      final card = CreditCard(
        id: '2',
        cardNumber: '378282246310005',
        cardHolder: 'John Doe',
        expiryDate: '12/29',
        cvv: '1234',
        brand: CardBrand.amex,
        cardStyleIndex: 0,
      );
      expect(card.formattedCardNumber, '3782 822463 10005');
    });

    test('Mask Card Number correctly', () {
      final visa = CreditCard(
        id: '1',
        cardNumber: '4111222233334444',
        cardHolder: 'John Doe',
        expiryDate: '12/29',
        cvv: '123',
        brand: CardBrand.visa,
        cardStyleIndex: 0,
      );
      expect(visa.maskedCardNumber, '•••• •••• •••• 4444');

      final amex = CreditCard(
        id: '2',
        cardNumber: '378282246310005',
        cardHolder: 'John Doe',
        expiryDate: '12/29',
        cvv: '1234',
        brand: CardBrand.amex,
        cardStyleIndex: 0,
      );
      expect(amex.maskedCardNumber, '•••• •••••• •0005');
    });
  });
}
