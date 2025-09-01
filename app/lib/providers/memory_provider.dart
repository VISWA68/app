import 'dart:io';
import 'package:app/utils/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/memory_model.dart';

// HTTP client for Google Drive API
class GoogleAuthHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

enum MemoryFilterType {
  newest,
  oldest,
  thisMonth,
  lastMonth,
  thisYear,
  byAuthor,
}

class MemoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Memory> _memories = [];
  bool _isLoading = false;
  String? _errorMessage;
  MemoryFilterType _currentFilter = MemoryFilterType.newest;
  String? _authorFilter;

  List<Memory> get memories => _getFilteredMemories();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MemoryFilterType get currentFilter => _currentFilter;
  String? get authorFilter => _authorFilter;

  List<Memory> _getFilteredMemories() {
    List<Memory> filtered = List.from(_memories);

    // Apply author filter first if set
    if (_authorFilter != null && _authorFilter!.isNotEmpty) {
      filtered = filtered
          .where((memory) => memory.author == _authorFilter)
          .toList();
    }

    // Apply sorting based on current filter
    switch (_currentFilter) {
      case MemoryFilterType.newest:
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case MemoryFilterType.oldest:
        filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case MemoryFilterType.thisMonth:
        final now = DateTime.now();
        filtered = filtered.where((memory) {
          return memory.timestamp.year == now.year &&
              memory.timestamp.month == now.month;
        }).toList();
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case MemoryFilterType.lastMonth:
        final lastMonth = DateTime.now().subtract(const Duration(days: 30));
        filtered = filtered.where((memory) {
          return memory.timestamp.year == lastMonth.year &&
              memory.timestamp.month == lastMonth.month;
        }).toList();
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case MemoryFilterType.thisYear:
        final now = DateTime.now();
        filtered = filtered.where((memory) {
          return memory.timestamp.year == now.year;
        }).toList();
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case MemoryFilterType.byAuthor:
        // Already handled by author filter above
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
    }

    return filtered;
  }

  void setFilter(MemoryFilterType filter, {String? author}) {
    _currentFilter = filter;
    _authorFilter = author;
    notifyListeners();
  }

  void clearFilters() {
    _currentFilter = MemoryFilterType.newest;
    _authorFilter = null;
    notifyListeners();
  }

  // Upload images to Google Drive
  Future<List<String>> _uploadImagesToDrive(
    List<XFile> images,
    Map<String, String> authHeaders,
  ) async {
    final httpClient = GoogleAuthHttpClient(authHeaders);
    final driveApi = drive.DriveApi(httpClient);

    List<String> imageUrls = [];

    for (var image in images) {
      try {
        final file = drive.File();
        file.name =
            'OurLittleWorld_Memory_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final result = await driveApi.files.create(
          file,
          uploadMedia: drive.Media(
            File(image.path).openRead(),
            File(image.path).lengthSync(),
          ),
        );

        if (result.id == null) {
          debugPrint('Failed to upload image: ${image.path}');
          continue;
        }

        // Make the file public and get the public URL
        await driveApi.permissions.create(
          drive.Permission(role: 'reader', type: 'anyone'),
          result.id!,
        );

        // Create the direct download URL
        final directUrl =
            'https://drive.google.com/uc?export=view&id=${result.id}';
        imageUrls.add(directUrl);
        debugPrint('Successfully uploaded image with direct URL: $directUrl');
      } catch (e) {
        debugPrint('Failed to upload individual image: $e');
        // Continue with other images
      }
    }

    return imageUrls;
  }

  // Add a new memory with image upload
  Future<void> addMemory({
    required String author,
    required String text,
    required List<XFile> images,
    required Map<String, String> authHeaders,
    double? latitude,
    double? longitude,
  }) async {
    if (images.isEmpty) {
      throw Exception('At least one image is required');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final imageUrls = await _uploadImagesToDrive(images, authHeaders);

      if (imageUrls.isEmpty) {
        throw Exception('Failed to upload any images');
      }

      final memory = {
        'author': author,
        'text': text,
        'photoUrls': imageUrls,
        'timestamp': DateTime.now(),
        'latitude': latitude,
        'longitude': longitude,
      };

      await _firestore.collection('memories').add(memory);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Add memory with single photo URL (for compatibility)
  Future<void> addMemoryWithUrl({
    required String author,
    required String text,
    required String photoUrl,
    double? latitude,
    double? longitude,
  }) async {
    final memory = Memory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: author,
      text: text,
      photoUrls: [photoUrl],
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
    );

    try {
      await DatabaseHelper().insertMemory(memory);
      _memories.add(memory);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Fetch memories from database
  Future<void> fetchMemories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('memories').get();
      _memories = snapshot.docs.map((doc) {
        final data = doc.data();
        return Memory(
          id: doc.id,
          author: data['author'],
          text: data['text'],
          photoUrls: List<String>.from(data['photoUrls']),
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          latitude: data['latitude'],
          longitude: data['longitude'],
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Delete a memory
  Future<void> deleteMemory(String memoryId) async {
    try {
      await _firestore.collection('memories').doc(memoryId).delete();
      _memories.removeWhere((memory) => memory.id == memoryId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get memories by author
  List<Memory> getMemoriesByAuthor(String author) {
    return _memories.where((memory) => memory.author == author).toList();
  }

  // Get memories count
  int get memoriesCount => _memories.length;

  // Get unique authors
  List<String> get uniqueAuthors {
    return _memories.map((memory) => memory.author).toSet().toList();
  }

}
