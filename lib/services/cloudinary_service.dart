import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Your Cloudinary credentials
  static const String _cloudName = 'dgug9jxvd';
  static const String _uploadPreset = 'authapp_profile'; // We'll create this

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName,
    _uploadPreset,
    cache: false,
  );

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile?  image = await _picker.pickImage(
        source: ImageSource. camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  /// Upload image to Cloudinary from XFile
  Future<String? > uploadImage(XFile imageFile) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Read file as bytes (works for web and mobile)
      final Uint8List bytes = await imageFile.readAsBytes();

      // Upload to Cloudinary
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: 'profile_$userId',
          folder: 'authapp/profiles',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Get the secure URL
      final String imageUrl = response.secureUrl;

      // Save URL to Firestore
      await _saveProfilePictureUrl(imageUrl);

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Save profile picture URL to Firestore
  Future<void> _saveProfilePictureUrl(String imageUrl) async {
    try {
      final userId = _auth.currentUser?. uid;
      if (userId == null) return;

      await _firestore.collection('users'). doc(userId).set({
        'photoUrl': imageUrl,
        'photoUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update Firebase Auth profile
      await _auth.currentUser?.updatePhotoURL(imageUrl);
    } catch (e) {
      print('Error saving profile picture URL: $e');
    }
  }

  /// Get current user's profile picture URL
  Future<String?> getProfilePictureUrl() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['photoUrl'];
    } catch (e) {
      print('Error getting profile picture: $e');
      return null;
    }
  }

  /// Delete profile picture
  Future<bool> deleteProfilePicture() async {
    try {
      final userId = _auth.currentUser?. uid;
      if (userId == null) return false;

      // Remove from Firestore
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': FieldValue.delete(),
        'photoUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Remove from Firebase Auth
      await _auth.currentUser?.updatePhotoURL(null);

      return true;
    } catch (e) {
      print('Error deleting profile picture: $e');
      return false;
    }
  }

  /// Get optimized Cloudinary URL with transformations
  String getOptimizedUrl(String originalUrl, {int size = 200}) {
    // Add Cloudinary transformations for optimization
    // c_fill = crop fill, g_face = focus on face, w_200, h_200 = size
    if (originalUrl.contains('cloudinary.com')) {
      return originalUrl. replaceFirst(
        '/upload/',
        '/upload/c_fill,g_face,w_$size,h_$size,q_auto,f_auto/',
      );
    }
    return originalUrl;
  }

  /// Get circular cropped URL
  String getCircularUrl(String originalUrl, {int size = 200}) {
    if (originalUrl.contains('cloudinary.com')) {
      return originalUrl.replaceFirst(
        '/upload/',
        '/upload/c_fill,g_face,w_$size,h_$size,r_max,q_auto,f_auto/',
      );
    }
    return originalUrl;
  }
}