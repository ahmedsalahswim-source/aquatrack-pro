import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:aquatrack_pro/core/constants/firebase_constants.dart';
import 'package:aquatrack_pro/core/errors/exceptions.dart';
import 'package:aquatrack_pro/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> registerWithEmail(String email, String password, String displayName);
  Future<UserModel> loginWithGoogle();
  Future<void> logout();
  Future<UserModel> getCurrentUser();
  Future<void> updateConsent(bool consented);
  Future<void> sendPasswordResetEmail(String email);
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fb_auth.FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final GoogleSignIn? googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.auth,
    required this.firestore,
    this.googleSignIn,
  });

  @override
  Stream<UserModel?> get authStateChanges {
    return auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      try {
        return _getUserFromFirestore(fbUser.uid);
      } catch (e) {
        debugPrint('[Auth] Failed to fetch user data: $e');
        return null;
      }
    });
  }

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _getUserFromFirestore(credential.user!.uid);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(
        message: _mapAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  @override
  Future<UserModel> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(displayName);

      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        hasConsented: false,
        consentTimestamp: null,
        createdAt: DateTime.now(),
      );

      await firestore
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .set(user.toFirestore());

      return user;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(
        message: _mapAuthErrorMessage(e.code),
        code: e.code,
      );
    } catch (e) {
      // Firestore write failed; delete the orphaned Auth user
      try {
        final fbUser = auth.currentUser;
        if (fbUser != null) await fbUser.delete();
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    try {
      fb_auth.UserCredential userCredential;

      if (kIsWeb) {
        final googleProvider = fb_auth.GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await auth.signInWithPopup(googleProvider);
      } else {
        if (googleSignIn == null) {
          throw AuthException(message: 'تسجيل الدخول عبر Google غير متاح', code: 'unavailable');
        }
        final googleAccount = await googleSignIn!.signIn();
        if (googleAccount == null) {
          throw AuthException(message: 'تم إلغاء تسجيل الدخول', code: 'cancelled');
        }
        final googleAuth = await googleAccount.authentication;
        final credential = fb_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await auth.signInWithCredential(credential);
      }

      final doc = await firestore.collection(FirebaseCollections.users).doc(userCredential.user!.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      final newUser = UserModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        displayName: userCredential.user!.displayName ?? '',
        photoUrl: userCredential.user!.photoURL,
        hasConsented: false,
        consentTimestamp: null,
        createdAt: DateTime.now(),
      );
      await firestore
          .collection(FirebaseCollections.users)
          .doc(newUser.uid)
          .set(newUser.toFirestore());
      return newUser;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthException(
        message: _mapAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  @override
  Future<void> logout() async {
    if (googleSignIn != null) {
      await googleSignIn!.signOut();
    }
    await auth.signOut();
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final fbUser = auth.currentUser;
    if (fbUser == null) {
      throw AuthException(message: 'المستخدم غير مسجل', code: 'not-logged-in');
    }
    await fbUser.reload();
    final refreshedUser = auth.currentUser;
    if (refreshedUser == null) {
      throw AuthException(message: 'المستخدم غير مسجل', code: 'not-logged-in');
    }
    return _getUserFromFirestore(refreshedUser.uid);
  }

  @override
  Future<void> updateConsent(bool consented) async {
    final fbUser = auth.currentUser;
    if (fbUser == null) {
      throw AuthException(message: 'المستخدم غير مسجل', code: 'not-logged-in');
    }
    await firestore.collection(FirebaseCollections.users).doc(fbUser.uid).update({
      'hasConsented': consented,
      'consentTimestamp': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel> _getUserFromFirestore(String uid) async {
    final doc = await firestore.collection(FirebaseCollections.users).doc(uid).get();
    if (!doc.exists) {
      throw ServerException(message: 'بيانات المستخدم غير موجودة');
    }
    return UserModel.fromFirestore(doc);
  }

  String _mapAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'الحساب مُعطّل';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'operation-not-allowed':
        return 'تسجيل الدخول غير مفعّل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'cancelled':
        return 'تم إلغاء تسجيل الدخول';
      case 'popup-blocked':
        return 'منع المتصفح نافذة تسجيل الدخول. يرجى السماح للنوافذ المنبثقة';
      case 'popup-closed-by-user':
        return 'تم إغلاق نافذة تسجيل الدخول';
      case 'unauthorized-domain':
        return 'هذا النطاق غير مصرح به في Firebase';
      default:
        return 'حدث خطأ في تسجيل الدخول';
    }
  }
}
