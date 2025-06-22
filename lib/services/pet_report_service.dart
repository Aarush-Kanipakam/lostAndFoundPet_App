// lib/services/pet_report_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetReportService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> uploadImage(File imageFile, String fileName) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'pet_images/$timestamp.$fileExt';

      await _client.storage.from('pet-images').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final imageUrl = _client.storage.from('pet-images').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> submitPetReport({
    required String? userId,
    required String? reportType,
    required String petName,
    required String petType,
    required String age,
    required DateTime? dateLost,
    required String petTypeCategory,
    required String gender,
    required String breed,
    required String sterilized,
    required String earNotched,
    required String collar,
    required String injured,
    required String friendly,
    required String color,
    required String locationAddress,
    required double? latitude,
    required double? longitude,
    required String additionalDetails,
    String? imageUrl,
  }) async {
    try {
      final response = await _client.from('pet_reports').insert({
        'user_id': userId,
        'pet_name': petName,
        'pet_type': petType.toLowerCase(), // 'dog' or 'cat'
        'report_type': reportType, // 'lost' or 'found'
        'age': age,
        'date': dateLost?.toIso8601String(),
        'pet_type_category': petTypeCategory,
        'gender': gender,
        'breed': breed,
        'sterilized': sterilized,
        'ear_notched': earNotched,
        'collar': collar,
        'injured': injured,
        'friendly': friendly,
        'color': color,
        'location_address': locationAddress,
        'latitude': latitude,
        'longitude': longitude,
        'additional_details': additionalDetails,
        'image_url': imageUrl,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error submitting pet report: $e');
      return false;
    }
  }
}