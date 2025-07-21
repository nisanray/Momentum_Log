import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:hive/hive.dart';
import '../models/user_prefs.dart';
import '../main.dart'; // For userPrefsBoxName

class AuthController with ChangeNotifier {
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  fb_auth.User? _firebaseUserInternal;
  UserPrefs? _userPrefs;

  static const String _userPrefsKey = 'currentUserPreferences_v1';

  String? get userId => _firebaseUserInternal?.uid ?? _userPrefs?.lastUserId;
  String? get userEmail => _firebaseUserInternal?.email;
  String? get displayName => _firebaseUserInternal?.displayName;
  bool get isAuthenticated => _firebaseUserInternal != null;

  fb_auth.User? get firebaseUserDebug => _firebaseUserInternal;

  AuthController() {
    debugPrint("AuthController: Initializing...");
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
    loadUserOnStartup();
  }

  Future<void> _onAuthStateChanged(fb_auth.User? user) async {
    debugPrint("AuthController: _onAuthStateChanged triggered. User UID: ${user?.uid}, IsNull: ${user == null}, CurrentDisplayName: ${user?.displayName}");
    final bool wasAuthenticated = _firebaseUserInternal != null;

    _firebaseUserInternal = user;

    if (user != null) {
      if (_userPrefs == null || _userPrefs!.lastUserId != user.uid || _userPrefs!.lastUserEmail != user.email) {
        await _saveUserPrefs(user.uid, user.email);
      }
    } else {
      await _clearUserPrefs();
    }

    final bool isCurrentlyAuthenticated = _firebaseUserInternal != null;
    // Notify if authentication state truly changed OR if user object identity changed (e.g. reloaded user instance)
    if (wasAuthenticated != isCurrentlyAuthenticated || (user != null && _firebaseUserInternal?.uid == user.uid /* Potentially new user object for same UID */) ) {
      debugPrint("AuthController: Auth state or user object changed (wasAuth: $wasAuthenticated, isAuth: $isCurrentlyAuthenticated). Notifying listeners.");
      notifyListeners();
    }
  }

  Future<void> loadUserOnStartup() async {
    debugPrint("AuthController: loadUserOnStartup called.");
    try {
      final box = Hive.box<UserPrefs>(userPrefsBoxName);
      if (box.containsKey(_userPrefsKey)) {
        _userPrefs = box.get(_userPrefsKey);
        debugPrint("AuthController: Loaded UserPrefs from Hive - ID: ${_userPrefs?.lastUserId}");
      } else {
        _userPrefs = null;
        debugPrint("AuthController: No UserPrefs found in Hive.");
      }
    } catch (e) {
      debugPrint("AuthController: Error loading UserPrefs from Hive: $e");
      _userPrefs = null;
    }

    final currentFbUser = _firebaseAuth.currentUser;
    if (currentFbUser != null) {
      debugPrint("AuthController: Firebase currentUser exists (UID: ${currentFbUser.uid}). Attempting reload.");
      try {
        await currentFbUser.reload();
        final latestUser = _firebaseAuth.currentUser; // Get the reloaded user object

        if (latestUser != null) {
          bool userChanged = _firebaseUserInternal == null ||
              _firebaseUserInternal!.uid != latestUser.uid ||
              _firebaseUserInternal!.displayName != latestUser.displayName ||
              _firebaseUserInternal!.email != latestUser.email;

          if (userChanged) {
            _firebaseUserInternal = latestUser; // Update internal state
            debugPrint("AuthController: User data reloaded. New DisplayName: ${latestUser.displayName}. Notifying listeners.");

            // Update UserPrefs if necessary
            if (_userPrefs == null || _userPrefs!.lastUserId != latestUser.uid || _userPrefs!.lastUserEmail != latestUser.email) {
              await _saveUserPrefs(latestUser.uid, latestUser.email);
            }
            notifyListeners(); // Notify about the updated user state
          } else {
            debugPrint("AuthController: User data reloaded, but no change detected in key fields.");
          }
        }
      } catch (e) {
        debugPrint("AuthController: Error reloading Firebase user: $e");
        // If reload fails, the existing _firebaseUserInternal (if any) or the stream's next emission will prevail.
        // We might be offline, or token might be expired.
        if (e is fb_auth.FirebaseAuthException && e.code == 'user-token-expired') {
          debugPrint("AuthController: User token expired. User needs to re-login.");
          // Force logout locally if token is expired
          _firebaseUserInternal = null;
          await _clearUserPrefs();
          notifyListeners();
        }
      }
    } else {
      // If no firebase user, ensure local state is also null
      if (_firebaseUserInternal != null) {
        _firebaseUserInternal = null;
        await _clearUserPrefs(); // Also clear prefs if we thought user was logged in
        debugPrint("AuthController: No Firebase user on startup, cleared local auth state. Notifying listeners.");
        notifyListeners();
      } else {
        _firebaseUserInternal = null; // Ensure it's null
      }
    }
  }

  Future<void> _saveUserPrefs(String uid, String? email) async {
    try {
      final box = Hive.box<UserPrefs>(userPrefsBoxName);
      _userPrefs = UserPrefs(lastUserId: uid, lastUserEmail: email);
      await box.put(_userPrefsKey, _userPrefs!);
      debugPrint("AuthController: UserPrefs saved successfully - UID: $uid");
    } catch (e) {
      debugPrint("AuthController: Error saving UserPrefs to Hive: $e");
    }
  }

  Future<void> _clearUserPrefs() async {
    try {
      final box = Hive.box<UserPrefs>(userPrefsBoxName);
      if (box.containsKey(_userPrefsKey)) {
        await box.delete(_userPrefsKey);
        debugPrint("AuthController: UserPrefs deleted successfully.");
      }
    } catch (e) {
      debugPrint("AuthController: Error clearing UserPrefs from Hive: $e");
    }
    _userPrefs = null; // Ensure local cache is cleared
  }

  Future<String?> signUp(String name, String email, String password) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedName.isEmpty) return "Full name cannot be empty.";
    if (trimmedEmail.isEmpty) return "Email cannot be empty.";
    if (trimmedPassword.isEmpty) return "Password cannot be empty.";
    if (trimmedPassword.length < 6) return "Password must be at least 6 characters long.";

    debugPrint("AuthController: Attempting signUp for email: $trimmedEmail");
    try {
      fb_auth.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(trimmedName);
        await userCredential.user!.reload();
        // _onAuthStateChanged will handle updating _firebaseUserInternal and notifying.
      }
      return null;
    } on fb_auth.FirebaseAuthException catch (e) {
      debugPrint("AuthController: SignUp FirebaseAuthException: Code: ${e.code}, Message: ${e.message}");
      if (e.code == 'weak-password') return 'The password provided is too weak.';
      if (e.code == 'email-already-in-use') return 'An account already exists for that email.';
      if (e.code == 'invalid-email') return 'The email address is not valid.';
      return e.message ?? "An error occurred during sign up.";
    } catch (e, stackTrace) {
      debugPrint("AuthController: SignUp unexpected error: $e\nStackTrace: $stackTrace");
      return "An unexpected error occurred. Please check your connection and try again.";
    }
  }

  Future<String?> login(String email, String password) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty) return "Email cannot be empty.";
    if (trimmedPassword.isEmpty) return "Password cannot be empty.";

    debugPrint("AuthController: Attempting login for email: $trimmedEmail");
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
      if (_firebaseAuth.currentUser != null) {
        await _firebaseAuth.currentUser!.reload();
        // _onAuthStateChanged will handle updating _firebaseUserInternal and notifying.
      }
      return null;
    } on fb_auth.FirebaseAuthException catch (e) {
      debugPrint("AuthController: Login FirebaseAuthException: Code: ${e.code}, Message: ${e.message}");
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') return 'Invalid email or password.';
      if (e.code == 'invalid-email') return 'The email address is not valid.';
      if (e.code == 'user-disabled') return 'This user account has been disabled.';
      return e.message ?? "An error occurred during login.";
    } catch (e, stackTrace) {
      debugPrint("AuthController: Login unexpected error: $e\nStackTrace: $stackTrace");
      return "An unexpected error occurred. Please check your connection and try again.";
    }
  }

  Future<void> logout() async {
    final String? loggedOutUserId = _firebaseUserInternal?.uid;
    debugPrint("AuthController: Attempting logout for user: $loggedOutUserId");
    try {
      await _firebaseAuth.signOut();
      // Firebase signOut is complete. _onAuthStateChanged should be triggered shortly.
      // To ensure the UI reacts as quickly as possible, we can preemptively update local state
      // and notify, especially if the stream has any slight delay.
      if (_firebaseUserInternal != null) { // Check if state was indeed logged-in
        _firebaseUserInternal = null; // Explicitly set internal state
        await _clearUserPrefs();      // Clear local preferences
        debugPrint("AuthController: Firebase signOut successful. Local state forced to logged-out. Notifying listeners.");
        notifyListeners();            // Notify listeners immediately
      } else {
        // This means _firebaseUserInternal was already null, _onAuthStateChanged might have already run.
        debugPrint("AuthController: Firebase signOut successful. _firebaseUserInternal was already null (likely handled by _onAuthStateChanged).");
        // If _onAuthStateChanged already handled it and notified, this notifyListeners might be redundant but harmless.
        // If it hadn't notified for some reason, this ensures it does.
        if (isAuthenticated) { // Double check if isAuthenticated is somehow still true
          debugPrint("AuthController: WARNING - isAuthenticated still true after _firebaseUserInternal was null in logout. Forcing notify.");
          _firebaseUserInternal = null; // Ensure
          notifyListeners();
        }
      }
    } catch (e, stackTrace) {
      debugPrint("AuthController: Error during firebase signOut: $e\nStackTrace: $stackTrace");
      // Even if signOut itself fails, force local state to reflect logout for UI consistency.
      _firebaseUserInternal = null;
      await _clearUserPrefs();
      debugPrint("AuthController: Error during signOut, but local state forced to logged-out. Notifying listeners.");
      notifyListeners();
    }
  }
}