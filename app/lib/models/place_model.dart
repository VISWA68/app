import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String authorRole;
  final String description;
  final double latitude;
  final double longitude;
  final List<String> imageUrls; 
  final String? fcmToken;
  final DateTime? timestamp; 

  Place({
    required this.id,
    required this.authorRole,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    this.fcmToken,
    this.timestamp,
  });

  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  
  bool get hasMultipleImages => imageUrls.length > 1;
  
  int get imageCount => imageUrls.length;

  factory Place.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    List<String> urls = [];
    if (data['imageUrls'] != null) {
      urls = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null) {
      urls = [data['imageUrl'] as String];
    }
    
    return Place(
      id: doc.id,
      authorRole: data['authorRole'] as String? ?? '',
      description: data['description'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrls: urls,
      fcmToken: data['fcmToken'] as String?,
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorRole': authorRole,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls, 
      'fcmToken': fcmToken,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  Place copyWith({
    String? id,
    String? authorRole,
    String? description,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    String? fcmToken,
    DateTime? timestamp,
  }) {
    return Place(
      id: id ?? this.id,
      authorRole: authorRole ?? this.authorRole,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      fcmToken: fcmToken ?? this.fcmToken,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'Place(id: $id, authorRole: $authorRole, description: $description, '
           'imageCount: $imageCount, lat: $latitude, lng: $longitude, '
           'timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Place &&
        other.id == id &&
        other.authorRole == authorRole &&
        other.description == description &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        _listEquals(other.imageUrls, imageUrls) &&
        other.fcmToken == fcmToken &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      authorRole,
      description,
      latitude,
      longitude,
      Object.hashAll(imageUrls),
      fcmToken,
      timestamp,
    );
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}