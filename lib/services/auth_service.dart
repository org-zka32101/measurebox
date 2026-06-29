import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'hive_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(displayName);

    // Create user document in Firestore
    final userModel = UserModel(
      uid: credential.user!.uid,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
      calibration: 0.0,
    );

    await _firestore.collection('users').doc(credential.user!.uid).set({
      'email': email,
      'displayName': displayName,
      'createdAt': DateTime.now(),
      'calibration': 0.0,
    });

    // Save to Hive
    await HiveService.getUserBox().put(credential.user!.uid, userModel);

    return credential;
  }

  // Log in with email and password
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Load user from Firestore and cache locally
    final doc =
        await _firestore.collection('users').doc(credential.user!.uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final userModel = UserModel(
        uid: credential.user!.uid,
        email: data['email'] ?? '',
        displayName: data['displayName'] as String?,
        createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
        calibration: (data['calibration'] as num?)?.toDouble() ?? 0.0,
      );
      await HiveService.getUserBox().put(credential.user!.uid, userModel);
    }

    return credential;
  }

  // Log out
  Future<void> logout() async {
    await _auth.signOut();
    // Optional: clear local cache
    // await HiveService.clearAllBoxes();
  }

  // Get cached user from Hive
  UserModel? getCachedUser(String uid) {
    return HiveService.getUserBox().get(uid);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Delete account
  Future<void> deleteAccount(String uid) async {
    // Delete user document from Firestore
    await _firestore.collection('users').doc(uid).delete();

    // Delete auth user
    await currentUser?.delete();
  }

  // Update user display name
  Future<void> updateDisplayName(String displayName) async {
    await currentUser?.updateDisplayName(displayName);

    // Update in Firestore
    if (currentUser != null) {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update({'displayName': displayName});

      // Update in Hive
      final cached = getCachedUser(currentUser!.uid);
      if (cached != null) {
        final updated = cached.copyWith(displayName: displayName);
        await HiveService.getUserBox()
            .put(currentUser!.uid, updated);
      }
    }
  }

  // Update calibration
  Future<void> updateCalibration(double calibration) async {
    if (currentUser != null) {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update({'calibration': calibration});

      // Update in Hive
      final cached = getCachedUser(currentUser!.uid);
      if (cached != null) {
        final updated = cached.copyWith(calibration: calibration);
        await HiveService.getUserBox()
            .put(currentUser!.uid, updated);
      }
    }
  }
}

