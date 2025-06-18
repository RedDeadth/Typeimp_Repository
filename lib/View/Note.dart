class Note {
  final String userId;
  final String noteId;
  String title;
  String content;
  String categoryId;
  final String createdAt;
  String updatedAt;

  Note({
    required this.userId,
    required this.noteId,
    required this.title,
    required this.content,
    this.categoryId = 'Uncategorized', // Default value
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      userId: json['userId'] as String,
      noteId: json['noteId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      categoryId: json['categoryId'] as String? ?? 'Uncategorized',
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'noteId': noteId,
      'title': title,
      'content': content,
      'categoryId': categoryId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}