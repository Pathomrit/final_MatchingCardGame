class AppData {
  String id;
  String level;
  String image;
  String meaning;
  String word;
  String wordImage;

  AppData({
    required this.id,
    required this.level,
    required this.image,
    required this.meaning,
    required this.word,
    required this.wordImage,
  });

  factory AppData.fromMap(Map<String, dynamic> data) {
    return AppData(
      id: data["id"]!,
      level: data["level"]!,
      image: data["image"]!,
      meaning: data["meaning"]!,
      word: data["word"]!,
      wordImage: data["wordImage"]!,
    );
  }
}