import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/place_model.dart';

class MapProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  List<Place> _places = [];
  List<Place> get places => _places;

  // This method listens to the 'places' collection in real-time
  void fetchPlaces() {
    _firestore.collection('places').snapshots().listen((snapshot) {
      _places = snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  Future<void> addPlaceWithUrl({
    required String authorRole,
    required String imageUrl,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final newPlace = Place(
        id: '', // Firestore will generate this
        authorRole: authorRole,
        description: description,
        latitude: latitude,
        longitude: longitude,
        imageUrl: imageUrl,
      );

      await _firestore.collection('places').add(newPlace.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error adding place with URL: $e');
      }
    }
  }

  // This method adds a new place with an image to Firestore and Storage
  Future<void> addPlace({
    required String authorRole,
    required File imageFile,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // 1. Upload the image to Firebase Storage
      final String imagePath = 'places/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(imagePath);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String imageUrl = await snapshot.ref.getDownloadURL();

      // 2. Create the Place object
      final newPlace = Place(
        id: '', // Firestore will generate this
        authorRole: authorRole,
        description: description,
        latitude: latitude,
        longitude: longitude,
        imageUrl: imageUrl,
      );

      // 3. Add the place data to Firestore
      await _firestore.collection('places').add(newPlace.toMap());
      
      // The `fetchPlaces` stream will automatically update the UI after this.

    } catch (e) {
      if (kDebugMode) {
        print('Error adding place: $e');
      }
      // You could handle errors here, like showing a snackbar to the user
    }
  }
}