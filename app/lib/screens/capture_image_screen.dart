import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../providers/map_provider.dart';
import '../utils/database_helper.dart';

/// Authenticated HTTP client for Google Drive
class GoogleAuthHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();
  GoogleAuthHttpClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest req) {
    req.headers.addAll(_headers);
    return _inner.send(req);
  }
}

class CaptureImageScreen extends StatefulWidget {
  const CaptureImageScreen({super.key});

  @override
  State<CaptureImageScreen> createState() => _CaptureImageScreenState();
}

class _CaptureImageScreenState extends State<CaptureImageScreen> {
  final _descCtrl = TextEditingController();
  File? _image;
  bool _isSaving = false;
  String? _userRole;

  // Updated scopes for Google Drive
  static const List<String> _scopes = <String>[
    'email',
    'https://www.googleapis.com/auth/drive.file',
  ];

  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;

  // Stream subscription for proper cleanup
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
    _loadRole();
    _takePicture();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeGoogleSignIn() async {
    final GoogleSignIn signIn = GoogleSignIn.instance;

    // Initialize with your client IDs (replace with actual values)
    await signIn.initialize(
      clientId: null, // Replace with your client ID
      serverClientId: null, // Replace with your server client ID
    );

    // Listen to authentication events (v7.x+ approach) with proper cleanup
    _authSubscription = signIn.authenticationEvents.listen(
      (event) {
        if (mounted) {
          _handleAuthenticationEvent(event);
        }
      },
      onError: (error) {
        debugPrint('Auth error: $error');
        if (mounted) {
          setState(() {
            _currentUser = null;
            _isAuthorized = false;
          });
        }
      },
    );

    // Attempt silent authentication on launch
    try {
      await signIn.attemptLightweightAuthentication();
    } catch (e) {
      debugPrint('Silent auth failed: $e');
    }
  }

  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    if (!mounted) return;

    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    // Check for existing authorization
    GoogleSignInClientAuthorization? authorization;
    if (user != null) {
      try {
        authorization = await user.authorizationClient.authorizationForScopes(
          _scopes,
        );
      } catch (e) {
        debugPrint('Authorization check failed: $e');
      }
    }

    if (mounted) {
      setState(() {
        _currentUser = user;
        _isAuthorized = authorization != null;
      });
    }
  }

  Future<void> _loadRole() async {
    final role = await DatabaseHelper().getCharacterChoice();
    if (mounted) setState(() => _userRole = role);
  }

  Future<void> _handleSignIn() async {
    if (GoogleSignIn.instance.supportsAuthenticate()) {
      try {
        await GoogleSignIn.instance.authenticate();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
        }
      }
    } else if (kIsWeb) {
      // On web, use official web button rendering
      debugPrint('On web, render the GSI button from google_sign_in_web.');
    }
  }

  Future<void> _handleAuthorizeScopes(GoogleSignInAccount user) async {
    try {
      final GoogleSignInClientAuthorization authorization = await user
          .authorizationClient
          .authorizeScopes(_scopes);

      // Suppress unused variable warning
      // ignore: unnecessary_statements
      authorization;

      setState(() {
        _isAuthorized = true;
      });
    } on GoogleSignInException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authorization failed: ${e.description}')),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (file == null) {
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _image = File(file.path));
    }
  }

  Future<String?> _uploadToDrive() async {
    if (_currentUser == null || _image == null || !_isAuthorized) return null;

    try {
      // Get authorization headers
      final Map<String, String>? headers = await _currentUser!
          .authorizationClient
          .authorizationHeaders(_scopes);

      if (headers == null) {
        throw Exception('Failed to get authorization headers');
      }

      final client = GoogleAuthHttpClient(headers);
      final driveApi = drive.DriveApi(client);

      final fileMeta = drive.File()
        ..name = 'Memory_${DateTime.now().toIso8601String()}.jpg';

      final result = await driveApi.files.create(
        fileMeta,
        uploadMedia: drive.Media(_image!.openRead(), _image!.lengthSync()),
      );

      // Make public and fetch webViewLink
      await driveApi.permissions.create(
        drive.Permission(type: 'anyone', role: 'reader'),
        result.id!,
      );

      final drive.File fileDetail =
          await driveApi.files.get(result.id!, $fields: 'webViewLink')
              as drive.File;

      return fileDetail.webViewLink;
    } catch (e) {
      debugPrint('Drive upload error: $e');
      rethrow;
    }
  }

  Future<void> _saveMemory() async {
    if (_image == null || _userRole == null) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in with Google first.')),
      );
      return;
    }

    if (!_isAuthorized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please authorize Google Drive access first.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final link = await _uploadToDrive();
      if (link != null) {
        await context.read<MapProvider>().addPlaceWithUrls(
          authorRole: _userRole!,
          imageUrls: [link],
          description: _descCtrl.text.isEmpty
              ? 'A captured memory!'
              : _descCtrl.text,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture a Memory')),
      body: Center(
        child: _isSaving
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving your memory...'),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_image != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_image!),
                      )
                    else
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.camera_alt, size: 50),
                              SizedBox(height: 16),
                              Text('No image captured yet.'),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Description (optional)',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // User status display
                    if (_currentUser != null) ...[
                      Card(
                        child: ListTile(
                          leading: GoogleUserCircleAvatar(
                            identity: _currentUser!,
                          ),
                          title: Text(_currentUser!.displayName ?? ''),
                          subtitle: Text(_currentUser!.email),
                          trailing: _isAuthorized
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : const Icon(Icons.warning, color: Colors.orange),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Sign-in button
                    if (_currentUser == null)
                      ElevatedButton(
                        onPressed: _handleSignIn,
                        child: const Text('Sign in with Google'),
                      ),

                    // Authorization button
                    if (_currentUser != null && !_isAuthorized)
                      ElevatedButton(
                        onPressed: () => _handleAuthorizeScopes(_currentUser!),
                        child: const Text('Authorize Google Drive Access'),
                      ),

                    // Action buttons
                    if (_image != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _takePicture,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Retake'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_currentUser != null && _isAuthorized)
                                  ? _saveMemory
                                  : null,
                              child: const Text('Save Memory'),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      ElevatedButton(
                        onPressed: _takePicture,
                        child: const Text('Take Picture'),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
