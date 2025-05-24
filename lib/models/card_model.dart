class CardModel {
  final String code;
  final String image;
  final String suit;
  final String value;

  CardModel({
    required this.code,
    required this.image,
    required this.suit,
    required this.value,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      code: json['code'],
      image: json['image'],
      suit: json['suit'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'image': image,
      'suit': suit,
      'value': value,
    };
  }

  int get numericValue {
    const valueMap = {
      'ACE': 14,
      'KING': 13,
      'QUEEN': 12,
      'JACK': 11,
      '10': 10,
      '9': 9,
      '8': 8,
      '7': 7,
      '6': 6,
      '5': 5,
      '4': 4,
      '3': 3,
      '2': 2,
    };
    return valueMap[value] ?? 0;
  }
}