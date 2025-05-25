class CardModel {
  final String code;      // e.g., "AS", "2H", "QD"
  final String suit;      // "SPADES", "HEARTS", etc.
  final String value;     // "ACE", "2", "QUEEN", etc.
  final String image;     // URL to card image
  final int numericValue; // Numeric representation for comparison

  CardModel({
    required this.code,
    required this.suit,
    required this.value,
    required this.image,
  }) : numericValue = _getNumericValue(value);

  static int _getNumericValue(String value) {
    const values = {
      'ACE': 14, 'KING': 13, 'QUEEN': 12, 'JACK': 11,
      '10': 10, '9': 9, '8': 8, '7': 7, '6': 6,
      '5': 5, '4': 4, '3': 3, '2': 2
    };
    return values[value.toUpperCase()] ?? 0;
  }

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      code: json['code'],
      suit: json['suit'],
      value: json['value'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'suit': suit,
    'value': value,
    'image': image,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModel &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          suit == other.suit;

  @override
  int get hashCode => code.hashCode ^ suit.hashCode;
}