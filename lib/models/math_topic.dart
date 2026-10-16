class MathTopic {
  const MathTopic({
    required this.id,
    required this.title,
    required this.description,
    this.levelIds = const [],
  });
  final String id;
  final String title;
  final String description;
  final List<String> levelIds;
  bool get isAvailable => levelIds.isNotEmpty;
}
