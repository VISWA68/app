import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String authorRole;
  final String description;
  final double latitude;
  final double longitude;
  final String imageUrl;

  Place({
    required this.id,
    required this.authorRole,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
  });

  // Factory constructor to create a Place object from a Firestore document
  factory Place.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Place(
      id: doc.id,
      authorRole: data['authorRole'] as String,
      description: data['description'] as String,
      latitude: data['latitude'] as double,
      longitude: data['longitude'] as double,
      imageUrl: data['imageUrl'] as String,
    );
  }

  // Method to convert a Place object into a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'authorRole': authorRole,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}