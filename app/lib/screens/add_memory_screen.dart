import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/memory_provider.dart';
import '../providers/auth_provider.dart';

class AddMemoryScreen extends StatefulWidget {
  final String? userRole;

  const AddMemoryScreen({super.key, this.userRole});

  @override
  _AddMemoryScreenState createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  List<XFile>? _images;
  bool _isLoading = false;
  LatLng? _selectedLocation;
  bool _includeLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _selectedLocation = const LatLng(
            12.9716,
            77.5946,
          ); // Default to Bangalore
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _selectedLocation = const LatLng(12.9716, 77.5946);
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _selectedLocation = const LatLng(12.9716, 77.5946);
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _selectedLocation = const LatLng(12.9716, 77.5946);
      });
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
        SnackBar(
          content: Row(
            children: [
              Text(widget.userRole == 'Panda' ? '🐼' : '🐧'),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Capture a new moment'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 75,
                    maxWidth: 1024,
                    maxHeight: 1024,
                  );
                  if (image != null && mounted) {
                    setState(() {
                      _images = [image];
                    });
                  }
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select one or multiple photos'),
                onTap: () async {
                  Navigator.pop(context);
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
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error picking images: $e');
      _showErrorSnackBar('Failed to pick images. Please try again.');
    }
  }

  Future<void> _saveMemory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final memoryProvider = Provider.of<MemoryProvider>(context, listen: false);

    // Validate inputs
    if (widget.userRole == null) {
      _showErrorSnackBar('User role not loaded. Please restart the app.');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please add a description for this memory.');
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
      final authHeaders = await authProvider.getAuthorizationHeaders();
      if (authHeaders == null) {
        throw Exception('Failed to get authorization headers');
      }

      await memoryProvider.addMemory(
        author: widget.userRole!,
        text: _descriptionController.text.trim(),
        images: _images!,
        authHeaders: authHeaders,
        latitude: _includeLocation ? _selectedLocation?.latitude : null,
        longitude: _includeLocation ? _selectedLocation?.longitude : null,
      );

      _showSuccessSnackBar('Memory saved successfully! 💕');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error saving memory: $e');
      _showErrorSnackBar('Error saving memory: ${e.toString()}');
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
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  widget.userRole == 'Panda'
                      ? 'assets/images/panda_avatar.png'
                      : 'assets/images/penguin_avatar.png',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 8),
                const Text('New Memory'),
              ],
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
          ),
          body: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Creating your beautiful memory...',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.userRole == 'Panda' ? '🐼💕' : '🐧💕',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Auth status card
                        _buildAuthStatusCard(authProvider),
                        const SizedBox(height: 16),

                        // Image selection
                        _buildImageSection(),
                        const SizedBox(height: 24),

                        // Description input
                        _buildDescriptionSection(),
                        const SizedBox(height: 24),

                        // Location section
                        _buildLocationSection(),
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

  Widget _buildAuthStatusCard(AuthProvider authProvider) {
    IconData icon;
    Color color;
    String title;
    String subtitle;

    if (!authProvider.isSignedIn) {
      icon = Icons.account_circle_outlined;
      color = Colors.grey;
      title = 'Not signed in';
      subtitle = 'Sign in with Google to save memories';
    } else if (!authProvider.isAuthorized) {
      icon = Icons.cloud_off;
      color = Colors.orange;
      title = 'Drive access needed';
      subtitle = 'Authorize Google Drive to save images';
    } else {
      icon = Icons.cloud_done;
      color = Colors.green;
      title = 'Ready to create memories';
      subtitle = 'All permissions granted';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: authProvider.isSignedIn && authProvider.isAuthorized
            ? Text(
                widget.userRole == 'Panda' ? '🐼✨' : '🐧✨',
                style: const TextStyle(fontSize: 20),
              )
            : null,
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_camera,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Memory Photos',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_images != null && _images!.isNotEmpty)
          _buildImagePreview()
        else
          _buildImagePlaceholder(),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images!.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(_images![index].path),
                          fit: BoxFit.cover,
                          width: 150,
                          height: 200,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 150,
                              height: 200,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error, color: Colors.red),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _images!.removeAt(index);
                            if (_images!.isEmpty) {
                              _images = null;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text('Add More Photos (${_images!.length}/10)'),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return GestureDetector(
      onTap: _isLoading ? null : _pickImages,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 60,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to add photos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Camera or Gallery',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.edit_note,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Memory Description',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: widget.userRole == 'Panda'
                ? 'What made this moment special? 🐼💕'
                : 'Share this beautiful memory! 🐧💕',
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            prefixIcon: Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          maxLines: 4,
          enabled: !_isLoading,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Location',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Switch(
              value: _includeLocation,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _includeLocation = value;
                      });
                    },
              activeColor: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_includeLocation && _selectedLocation != null) ...[
          Text(
            'Tap on the map to adjust location:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 250,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _selectedLocation!,
                    initialZoom: 15,
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              widget.userRole == 'Panda'
                                  ? 'assets/images/panda_avatar.png'
                                  : 'assets/images/penguin_avatar.png',
                              width: 32,
                              height: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else if (_includeLocation) ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.location_searching, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(child: Text('Getting your location...')),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.location_off, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Location will not be saved with this memory'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton(AuthProvider authProvider) {
    final canSave =
        authProvider.isSignedIn &&
        authProvider.isAuthorized &&
        !_isLoading &&
        _images != null &&
        _images!.isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      child: ElevatedButton(
        onPressed: canSave ? _saveMemory : null,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          backgroundColor: canSave
              ? Theme.of(context).colorScheme.secondary
              : Colors.grey,
          elevation: canSave ? 8 : 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (canSave) ...[
              Text(widget.userRole == 'Panda' ? '🐼' : '🐧'),
              const SizedBox(width: 8),
            ],
            Text(
              canSave ? 'Save This Memory' : 'Complete setup to save',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (canSave) ...[const SizedBox(width: 8), const Text('💕')],
          ],
        ),
      ),
    );
  }
}
