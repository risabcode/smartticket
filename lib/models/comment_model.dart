class CommentModel {
  final String id;
  final String text;
  final String author;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
  });
}
