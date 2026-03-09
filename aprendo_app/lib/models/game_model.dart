class Game {
  final String title;
  final String emoji;
  final String idName;
  final String description;

  Game({
    required this.title,
    required this.emoji,
    required this.idName,
    required this.description,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      title: json['title'],
      emoji: json['emoji'],
      idName: json['id_name'],
      description: json['description'],
    );
  }
}
