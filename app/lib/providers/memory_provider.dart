import 'package:flutter/foundation.dart';
import '../models/memory_model.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Uncomment this
// import 'package:firebase_storage/firebase_storage.dart'; // Uncomment this

class MemoryProvider with ChangeNotifier {
  List<Memory> _memories = [];

  List<Memory> get memories => _memories;

  // Add a new memory to both Firebase and the local DB
  Future<void> addMemory(Memory memory) async {
    // 1. Upload image to Firebase Storage
    // 2. Add memory to Firebase Firestore
    // 3. Add memory to local SQLite DB for caching

    // For now, let's just add it locally
    _memories.add(memory);
    notifyListeners();
  }

  // Fetch memories from Firebase and cache them locally
  Future<void> fetchMemories() async {
    // 1. Fetch memories from Firebase Firestore
    // 2. Update the local SQLite DB
    // 3. Update the provider's state

    // Dummy data for now
    _memories = [
      Memory(
        id: '1',
        author: 'V', // You
        text: "Our first trip to the mountains!",
        photoUrl: 'https://picsum.photos/id/14/200/300',
        timestamp: DateTime.now().subtract(Duration(days: 5)),
      ),
      Memory(
        id: '2',
        author: 'S', // Her
        text: "My favorite dinner date with you.",
        photoUrl: 'https://picsum.photos/id/14/200/300',
        timestamp: DateTime.now().subtract(Duration(days: 2)),
      ),
    ];
    notifyListeners();
  }
}
