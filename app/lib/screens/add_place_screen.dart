import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../providers/map_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/database_helper.dart';

// A simple HTTP client to use with the Google Drive API
class GoogleAuthHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class AddPlaceScreen extends StatefulWidget {
  final LatLng currentLocation;
  const AddPlaceScreen({super.key, required this.currentLocation});

  @override
  _AddPlaceScreenState createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  LatLng? _selectedLocation;
  String? _userRole;
  List<XFile>? _images;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation;
    _loadUserRole();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadUserRole() async {
    try {
      final role = await DatabaseHelper().getCharacterChoice();
      if (mounted) {
        setState(() {
          _userRole = role;
        });
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn();

      if (authProvider.isSignedIn) {
        _showSuccessSnackBar('Successfully signed in!');
      }
    } catch (error) {
      debugPrint('Sign-in error: $error');
      _showErrorSnackBar('Sign-in failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAuthorizeScopes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.authorizeGoogleDrive();

      if (authProvider.isAuthorized) {
        _showSuccessSnackBar('Google Drive access authorized successfully!');
      }
    } catch (error) {
      debugPrint('Authorization error: $error');
      _showErrorSnackBar('Authorization failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile>? images = await picker.pickMultiImage(
        imageQuality: 75,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (images != null && mounted) {
        setState(() {
          _images = images;
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      _showErrorSnackBar('Failed to pick images. Please try again.');
    }
  }

  Future<List<String>> _uploadImagesToDrive() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isSignedIn ||
        _images == null ||
        !authProvider.isAuthorized) {
      throw Exception('Prerequisites not met for upload');
    }

    try {
      // Get authorization headers
      final Map<String, String>? headers = await authProvider
          .getAuthorizationHeaders();

      if (headers == null) {
        throw Exception('Failed to get authorization headers');
      }

      final httpClient = GoogleAuthHttpClient(headers);
      final driveApi = drive.DriveApi(httpClient);

      List<String> imageUrls = [];

      for (var image in _images!) {
        try {
          final file = drive.File();
          file.name =
              'Our Little World - ${DateTime.now().toIso8601String()}.jpg';

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

          // Create the direct download URL instead of view URL
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
    } catch (e) {
      debugPrint('Drive upload error: $e');
      rethrow;
    }
  }

  Future<void> _savePlace() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Validate inputs
    if (_userRole == null) {
      _showErrorSnackBar('User role not loaded. Please restart the app.');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please add a description for this place.');
      return;
    }

    if (_images == null || _images!.isEmpty) {
      _showErrorSnackBar('Please select at least one image.');
      return;
    }

    if (!authProvider.isSignedIn) {
      _showErrorSnackBar('Please sign in with Google first.');
      return;
    }

    if (!authProvider.isAuthorized) {
      _showErrorSnackBar('Please authorize Google Drive access first.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<String> imageUrls = await _uploadImagesToDrive();

      if (imageUrls.isNotEmpty) {
        await context.read<MapProvider>().addPlaceWithUrls(
          authorRole: _userRole!,
          imageUrls: imageUrls,
          description: _descriptionController.text.trim(),
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
        );
        _showSuccessSnackBar('Place saved successfully!');
        if (mounted) Navigator.of(context).pop();
      } else {
        _showErrorSnackBar(
          'Failed to upload images to Google Drive. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('Error saving place: $e');
      _showErrorSnackBar('Error saving place: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Add a New Place',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
          ),
          body: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing...'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // User status display
                        if (authProvider.isSignedIn) ...[
                          _buildUserStatusCard(authProvider),
                          const SizedBox(height: 16),
                        ],

                        // Auth status info card
                        _buildAuthStatusCard(authProvider),
                        const SizedBox(height: 16),

                        // Image selection and display
                        if (_images != null && _images!.isNotEmpty)
                          _buildImagePreview(),
                        const SizedBox(height: 24),

                        // Action buttons
                        _buildActionButtons(authProvider),

                        const SizedBox(height: 24),

                        // Description input
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            hintText: 'What\'s the memory here?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            filled: true,
                          ),
                          maxLines: 3,
                          enabled: !_isLoading,
                        ),

                        const SizedBox(height: 24),

                        // Map section
                        _buildMapSection(),

                        const SizedBox(height: 24),

                        // Save button
                        _buildSaveButton(authProvider),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildUserStatusCard(AuthProvider authProvider) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Text(
            authProvider.currentUser?.displayName
                    ?.substring(0, 1)
                    .toUpperCase() ??
                'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(authProvider.currentUser?.displayName ?? 'Unknown User'),
        subtitle: Text(authProvider.currentUser?.email ?? 'No email'),
        trailing: authProvider.isAuthorized
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.warning, color: Colors.orange),
      ),
    );
  }

  Widget _buildAuthStatusCard(AuthProvider authProvider) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    if (!authProvider.isSignedIn) {
      icon = Icons.account_circle_outlined;
      color = Colors.grey;
      title = 'Not signed in';
      subtitle = 'Sign in with Google to save places';
    } else if (!authProvider.isAuthorized) {
      icon = Icons.cloud_off;
      color = Colors.orange;
      title = 'Drive access needed';
      subtitle = 'Authorize Google Drive to save images';
    } else {
      icon = Icons.cloud_done;
      color = Colors.green;
      title = 'Ready to save';
      subtitle = 'All permissions granted';
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildImagePreview() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images!.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(_images![index].path),
                  fit: BoxFit.cover,
                  width: 150,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(AuthProvider authProvider) {
    return Column(
      children: [
        // Pick images button
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _pickImages,
          icon: const Icon(Icons.photo_library),
          label: const Text('Pick Images from Gallery'),
        ),

        const SizedBox(height: 8),

        // Sign in button (if not signed in)
        if (!authProvider.isSignedIn)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleSignIn,
            icon: const Icon(Icons.account_circle),
            label: const Text('Sign in with Google'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),

        // Authorize button (if signed in but not authorized)
        if (authProvider.isSignedIn && !authProvider.isAuthorized) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleAuthorizeScopes,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Authorize Google Drive Access'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap on the map to set the location:',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _selectedLocation!,
                  initialZoom: 14,
                  onTap: _isLoading
                      ? null
                      : (tapPosition, point) {
                          setState(() {
                            _selectedLocation = point;
                          });
                        },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.our_little_world',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 60.0,
                        height: 60.0,
                        point: _selectedLocation!,
                        child: Image.asset(
                          _userRole == 'Panda'
                              ? 'assets/images/panda_avatar.png'
                              : 'assets/images/penguin_avatar.png',
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AuthProvider authProvider) {
    final canSave =
        authProvider.isSignedIn && authProvider.isAuthorized && !_isLoading;

    return ElevatedButton(
      onPressed: canSave ? _savePlace : null,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      child: Text(
        canSave ? 'Save This Place' : 'Complete setup to save',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: canSave ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}
