class Memory {
  final String id;
  final String author;
  final String text;
  final String photoUrl;
  final DateTime timestamp;

  Memory({
    required this.id,
    required this.author,
    required this.text,
    required this.photoUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author': author,
      'text': text,
      'photoUrl': photoUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Memory.fromMap(Map<String, dynamic> map) {
    return Memory(
      id: map['id'],
      author: map['author'],
      text: map['text'],
      photoUrl: map['photoUrl'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}