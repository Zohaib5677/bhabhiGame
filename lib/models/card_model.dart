

class CardModel {
  final String code;
  final String suit;
  final String value;
  final String image;

  CardModel({
    required this.code,
    required this.suit,
    required this.value,
    required this.image,
  });

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
}