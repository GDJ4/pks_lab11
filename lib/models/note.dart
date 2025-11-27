class Note {
  final int id;
  final String title;
  final String body;

  const Note({required this.id, required this.title, required this.body});

  factory Note.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId = rawId is int
        ? rawId
        : rawId is String
        ? int.tryParse(rawId) ?? 0
        : 0;

    return Note(
      id: parsedId,
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body};
}
