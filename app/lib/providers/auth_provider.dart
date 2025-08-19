import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;
  bool _isInitialized = false;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isAuthorized => _isAuthorized;
  bool get isInitialized => _isInitialized;
  bool get isSignedIn => _currentUser != null;

  static const String _authKey = 'google_auth_data';
  static const String _authorizedKey = 'google_drive_authorized';
  
  static const List<String> _scopes = <String>[
    'email',
    'https://www.googleapis.com/auth/drive.file',
  ];

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _initializeGoogleSignIn();
      await _restoreStoredAuthState();
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _initializeGoogleSignIn() async {
    final GoogleSignIn signIn = GoogleSignIn.instance;

    // Initialize with your client IDs (use the same ones from AddPlaceScreen)
    await signIn.initialize(
      clientId:
          "684009601734-juj1oqfpiukba9nof74n7ponuj687qkq.apps.googleusercontent.com",
      serverClientId:
          "684009601734-juj1oqfpiukba9nof74n7ponuj687qkq.apps.googleusercontent.com",
    );

    // Listen to authentication events (v7.x+ approach)
    _authSubscription?.cancel(); // Cancel any existing subscription
    _authSubscription = signIn.authenticationEvents.listen(
      (event) {
        _handleAuthenticationEvent(event);
      },
      onError: (error) {
        debugPrint('Auth provider error: $error');
        if (error is GoogleSignInException) {
          if (error.code != GoogleSignInExceptionCode.canceled) {
            // Handle non-cancellation errors
            _currentUser = null;
            _isAuthorized = false;
            notifyListeners();
          }
        }
      },
    );

    // Attempt silent authentication on initialization
    try {
      await signIn.attemptLightweightAuthentication();
    } catch (e) {
      debugPrint('Silent auth failed during initialization: $e');
    }
  }

  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
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
        debugPrint('Authorization check failed in provider: $e');
      }
    }

    _currentUser = user;
    _isAuthorized = authorization != null;
    
    // Store the updated state
    if (user != null) {
      await _storeAuthData();
    } else {
      await _clearStoredAuthData();
    }
    
    notifyListeners();
  }

  Future<void> _restoreStoredAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authData = prefs.getString(_authKey);

      if (authData != null) {
        // Try to restore session - the authentication event listener 
        // will handle setting _currentUser if successful
        final GoogleSignIn signIn = GoogleSignIn.instance;
        try {
          await signIn.attemptLightweightAuthentication();
          // After attempting authentication, _currentUser will be set
          // by the authentication event listener if successful
        } catch (e) {
          debugPrint('Failed to restore user session: $e');
          // Clear stored data if restoration fails
          await _clearStoredAuthData();
        }
      }
    } catch (e) {
      debugPrint('Error restoring auth state: $e');
      await _clearStoredAuthData();
    }
  }

  Future<void> signIn() async {
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception('Google Sign-In is not supported on this device');
    }

    try {
      await GoogleSignIn.instance.authenticate();
      // The authentication event listener will handle the rest
    } catch (error) {
      debugPrint('Sign in error in provider: $error');
      
      if (error is GoogleSignInException) {
        switch (error.code) {
          case GoogleSignInExceptionCode.canceled:
            // User cancelled - don't throw error
            debugPrint('User cancelled sign-in in provider');
            return;
          case GoogleSignInExceptionCode.unknownError:
            throw Exception('Network error. Please check your connection and try again.');
          case GoogleSignInExceptionCode.canceled:
            throw Exception('Sign-in required. Please try again.');
          default:
            throw Exception('Google Sign-In failed: ${error.description ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Google Sign-In failed: $error');
      }
    }
  }

  Future<void> authorizeGoogleDrive() async {
    if (_currentUser == null) {
      throw Exception('No user signed in');
    }

    try {
      final GoogleSignInClientAuthorization authorization = await _currentUser!
          .authorizationClient
          .authorizeScopes(_scopes);

      // Suppress unused variable warning
      // ignore: unnecessary_statements
      authorization;

      _isAuthorized = true;
      await _storeAuthData();
      notifyListeners();
    } on GoogleSignInException catch (e) {
      debugPrint('Authorization error in provider: $e');
      
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          // User cancelled - don't throw error
          debugPrint('User cancelled authorization in provider');
          return;
        default:
          throw Exception('Authorization failed: ${e.description ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('Unexpected authorization error in provider: $e');
      throw Exception('Authorization failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;
      await signIn.signOut();
      
      // The authentication event listener will handle clearing the state
      // But we'll also clear it here for immediate feedback
      _currentUser = null;
      _isAuthorized = false;
      
      await _clearStoredAuthData();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error in provider: $e');
      // Even if sign out fails, clear local state
      _currentUser = null;
      _isAuthorized = false;
      await _clearStoredAuthData();
      notifyListeners();
    }
  }

  Future<void> _storeAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null) {
        await prefs.setString(_authKey, _currentUser!.email);
        await prefs.setBool(_authorizedKey, _isAuthorized);
        debugPrint('Auth data stored for: ${_currentUser!.email}');
      }
    } catch (e) {
      debugPrint('Error storing auth data: $e');
    }
  }

  Future<void> _clearStoredAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authKey);
      await prefs.remove(_authorizedKey);
      debugPrint('Auth data cleared from storage');
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
    }
  }

  Future<void> changeAccount() async {
    try {
      await signOut();
      // Add a small delay to ensure sign out completes
      await Future.delayed(const Duration(milliseconds: 500));
      await signIn();
    } catch (e) {
      debugPrint('Error changing account: $e');
      rethrow;
    }
  }

  /// Check if the user has valid authorization for the required scopes
  Future<bool> checkAuthorization() async {
    if (_currentUser == null) return false;

    try {
      final authorization = await _currentUser!
          .authorizationClient
          .authorizationForScopes(_scopes);
      
      final hasAuth = authorization != null;
      if (_isAuthorized != hasAuth) {
        _isAuthorized = hasAuth;
        await _storeAuthData();
        notifyListeners();
      }
      
      return hasAuth;
    } catch (e) {
      debugPrint('Error checking authorization: $e');
      _isAuthorized = false;
      notifyListeners();
      return false;
    }
  }

  /// Get authorization headers for API calls
  Future<Map<String, String>?> getAuthorizationHeaders() async {
    if (_currentUser == null || !_isAuthorized) return null;

    try {
      return await _currentUser!
          .authorizationClient
          .authorizationHeaders(_scopes);
    } catch (e) {
      debugPrint('Error getting authorization headers: $e');
      return null;
    }
  }

  /// Force refresh the authorization status
  Future<void> refreshAuthorization() async {
    if (_currentUser == null) return;

    try {
      // Check current authorization status
      await checkAuthorization();
    } catch (e) {
      debugPrint('Error refreshing authorization: $e');
    }
  }
}