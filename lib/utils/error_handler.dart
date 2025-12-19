import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ErrorHandler {
  /// Get user-friendly message for Firebase Auth errors
  static String getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. ';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email. ';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.  Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'user-disabled':
        return 'This account has been disabled. ';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please log out and log in again to continue.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification.  Please try again.';
      case 'session-expired':
        return 'Session expired. Please try again.';
      case 'quota-exceeded':
        return 'Service limit reached. Please try again later.';
      case 'provider-already-linked':
        return 'This account is already linked. ';
      case 'credential-already-in-use':
        return 'This credential is already in use. ';
      default:
        return e.message ?? 'Authentication error.  Please try again.';
    }
  }

  /// Get user-friendly message for Firestore errors
  static String getFirestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again. ';
      case 'not-found':
        return 'Requested data not found.';
      case 'already-exists':
        return 'This data already exists.';
      case 'cancelled':
        return 'Operation cancelled.';
      case 'deadline-exceeded':
        return 'Operation timed out. Please try again.';
      case 'resource-exhausted':
        return 'Too many requests. Please try again later.';
      case 'failed-precondition':
        return 'Operation failed.  Please try again.';
      case 'aborted':
        return 'Operation aborted.  Please try again.';
      case 'out-of-range':
        return 'Invalid request. ';
      case 'unimplemented':
        return 'This feature is not available.';
      case 'internal':
        return 'Internal error. Please try again. ';
      case 'data-loss':
        return 'Data error. Please try again. ';
      case 'unauthenticated':
        return 'Please log in to continue.';
      default:
        return e.message ?? 'Database error. Please try again.';
    }
  }

  /// Get user-friendly message for any error
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getFirebaseAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return getFirestoreErrorMessage(error);
    } else if (error is Exception) {
      final message = error.toString();
      if (message.contains('SocketException') || 
          message.contains('NetworkException')) {
        return 'Network error. Check your internet connection.';
      }
      if (message.contains('TimeoutException')) {
        return 'Request timed out. Please try again.';
      }
      return 'An error occurred. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Log error for debugging (can be extended to send to analytics)
  static void logError(dynamic error, {String? context, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] ERROR${context != null ? " in $context" : ""}: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}