enum CardBrand {
  visa,
  mastercard,
  amex,
  discover,
  unknown,
}

class CreditCard {
  final String id;
  final String cardNumber;
  final String cardHolder;
  final String expiryDate; // Format: MM/YY
  final String cvv;
  final CardBrand brand;
  final int cardStyleIndex;
  final String? cardNickname;

  CreditCard({
    required this.id,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cvv,
    required this.brand,
    required this.cardStyleIndex,
    this.cardNickname,
  });

  // Format credit card number with spacing (e.g. 4111 2222 3333 4444)
  String get formattedCardNumber {
    // Remove all non-digits
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    final List<String> chunks = [];
    
    // Amex spacing is 4-6-5
    if (brand == CardBrand.amex) {
      if (cleanNumber.length >= 4) {
        chunks.add(cleanNumber.substring(0, 4));
        if (cleanNumber.length >= 10) {
          chunks.add(cleanNumber.substring(4, 10));
          chunks.add(cleanNumber.substring(10, cleanNumber.length));
        } else {
          chunks.add(cleanNumber.substring(4));
        }
      } else {
        chunks.add(cleanNumber);
      }
      return chunks.join(' ');
    }

    // Standard spacing is 4-4-4-4
    for (int i = 0; i < cleanNumber.length; i += 4) {
      final end = (i + 4 < cleanNumber.length) ? i + 4 : cleanNumber.length;
      chunks.add(cleanNumber.substring(i, end));
    }
    return chunks.join(' ');
  }

  // Masked card number (e.g. •••• •••• •••• 4444)
  String get maskedCardNumber {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.length < 4) return cleanNumber;
    
    final lastFour = cleanNumber.substring(cleanNumber.length - 4);
    
    if (brand == CardBrand.amex) {
      // Amex is 15 digits: •••• •••••• •4444
      return '•••• •••••• •$lastFour';
    }
    
    // Standard 16 digits: •••• •••• •••• 4444
    return '•••• •••• •••• $lastFour';
  }

  // Detect card brand from card number prefix
  static CardBrand detectBrand(String number) {
    final cleanNumber = number.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.isEmpty) return CardBrand.unknown;

    if (cleanNumber.startsWith('4')) {
      return CardBrand.visa;
    }
    
    if (cleanNumber.startsWith(RegExp(r'^5[1-5]')) || 
        (cleanNumber.length >= 6 && 
         int.tryParse(cleanNumber.substring(0, 6)) != null && 
         int.parse(cleanNumber.substring(0, 6)) >= 222100 && 
         int.parse(cleanNumber.substring(0, 6)) <= 272099)) {
      return CardBrand.mastercard;
    }
    
    if (cleanNumber.startsWith(RegExp(r'^3[47]'))) {
      return CardBrand.amex;
    }
    
    if (cleanNumber.startsWith('6011') || 
        cleanNumber.startsWith(RegExp(r'^65')) ||
        cleanNumber.startsWith(RegExp(r'^64[4-9]'))) {
      return CardBrand.discover;
    }

    return CardBrand.unknown;
  }

  // Create a copy of the card with modified fields
  CreditCard copyWith({
    String? id,
    String? cardNumber,
    String? cardHolder,
    String? expiryDate,
    String? cvv,
    CardBrand? brand,
    int? cardStyleIndex,
    String? cardNickname,
  }) {
    return CreditCard(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolder: cardHolder ?? this.cardHolder,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      brand: brand ?? this.brand,
      cardStyleIndex: cardStyleIndex ?? this.cardStyleIndex,
      cardNickname: cardNickname ?? this.cardNickname,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardNumber': cardNumber,
      'cardHolder': cardHolder,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'brand': brand.name,
      'cardStyleIndex': cardStyleIndex,
      'cardNickname': cardNickname,
    };
  }

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'] as String,
      cardNumber: json['cardNumber'] as String,
      cardHolder: json['cardHolder'] as String,
      expiryDate: json['expiryDate'] as String,
      cvv: json['cvv'] as String,
      brand: CardBrand.values.firstWhere(
        (b) => b.name == json['brand'],
        orElse: () => CardBrand.unknown,
      ),
      cardStyleIndex: json['cardStyleIndex'] as int,
      cardNickname: json['cardNickname'] as String?,
    );
  }
}
