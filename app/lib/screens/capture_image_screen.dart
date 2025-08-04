import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../utils/database_helper.dart';

class CaptureImageScreen extends StatefulWidget {
  const CaptureImageScreen({super.key});

  @override
  _CaptureImageScreenState createState() => _CaptureImageScreenState();
}

class _CaptureImageScreenState extends State<CaptureImageScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _takePicture();
  }

  Future<void> _loadUserRole() async {
    final role = await DatabaseHelper().getCharacterChoice();
    if (mounted) {
      _userRole = role;
    }
  }

  Future<void> _takePicture() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _savePlace() async {
    if (_image == null || _userRole == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await context.read<MapProvider>().addPlace(
        authorRole: _userRole!,
        imageFile: _image!,
        description: _descriptionController.text.isEmpty
            ? 'A place we captured!'
            : _descriptionController.text,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving place: $e')),
        );
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Capture a Memory', style: Theme.of(context).textTheme.headlineLarge),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_image != null)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(_image!, fit: BoxFit.cover),
                          ),
                        )
                      else
                        Text('No image captured.', style: Theme.of(context).textTheme.bodyLarge),
                      
                      const SizedBox(height: 24),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Add a description (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _image != null ? _savePlace : null,
                        child: const Text('Save Place'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}