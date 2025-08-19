class Memory {
  final String id;
  final String author;
  final String text;
  final List<String>? photoUrls;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  Memory({
    required this.id,
    required this.author,
    required this.text,
    this.photoUrls,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  String? get photoUrl =>
      photoUrls?.isNotEmpty == true ? photoUrls!.first : null;

  bool get hasLocation => latitude != null && longitude != null;

  int get photoCount => photoUrls?.length ?? 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'text': text,
      'photoUrls': photoUrls,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create Memory from JSON
  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      author: json['author'] as String,
      text: json['text'] as String,
      photoUrls: json['photoUrls'] != null
          ? List<String>.from(json['photoUrls'])
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }

  factory Memory.fromLegacyJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      author: json['author'] as String,
      text: json['text'] as String,
      photoUrls: json['photoUrl'] != null ? [json['photoUrl'] as String] : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }

  Memory copyWith({
    String? id,
    String? author,
    String? text,
    List<String>? photoUrls,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
  }) {
    return Memory(
      id: id ?? this.id,
      author: author ?? this.author,
      text: text ?? this.text,
      photoUrls: photoUrls ?? this.photoUrls,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  String toString() {
    return 'Memory{id: $id, author: $author, text: $text, photoCount: $photoCount, timestamp: $timestamp, hasLocation: $hasLocation}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Memory && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
