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
// Add this method to your PetReportService class
Future<bool> updatePetReport({
  required String? reportId,
  required String petName,
  required String petType,
  required String reportType,
  required String age,
  DateTime? dateLost,
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
  double? latitude,
  double? longitude,
  required String additionalDetails,
  String? imageUrl,
  String? userId,
}) async {
  try {
    final response = await Supabase.instance.client
        .from('adoption_pets')
        .update({
          'pet_name': petName,
          'pet_type': petType,
          'report_type': reportType,
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
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reportId!);

    return true;
  } catch (e) {
    print('Error updating pet report: $e');
    return false;
  }
}

Future<bool> updatePetForAdoption({
  required String? reportId,
  required String petName,
  required String petType,
  required String age,
  required String gender,
  required String breed,
  required String sterilized,
  required String vaccinated,
  required String locationAddress,
  double? latitude,
  double? longitude,
  required String additionalDetails,
  String? imageUrl,
  String? userId,
}) async {
  try {
    final response = await Supabase.instance.client
        .from('adoption_pets') // Use your actual table name
        .update({
          'pet_name': petName,
          'pet_type': petType,
          'age': age,
          'gender': gender,
          'breed': breed,
          'sterilized': sterilized,
          'vaccinated': vaccinated,
          'location_address': locationAddress,
          'latitude': latitude,
          'longitude': longitude,
          'additional_details': additionalDetails,
          'image_url': imageUrl,
         
        })
        .eq('id', reportId!);
        



    return true;
  } catch (e) {
    print('Error updating pet adoption report: $e');
    return false;
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

    Future<bool> submitPetForAdoption({
    required String? userId,
    required String petName,
    required String petType,
    required String age,
    required String gender,
    required String breed,
    required String sterilized,
    required String vaccinated, // Assuming vaccination is not required for adoption
    required String locationAddress,
    required double? latitude,
    required double? longitude,
    required String additionalDetails,
    String? imageUrl,
  }) async {
    try {
      final response = await _client.from('adoption_pets').insert({
        'user_id': userId,
        'pet_name': petName,
        'pet_type': petType.toLowerCase(), // 'dog' or 'cat'
   
        'age': age,

        'gender': gender,   // male or female
        'breed': breed,
        'sterilized': sterilized,    //yes or no
        'vaccinated': vaccinated, // Assuming vaccination is not required for adoption
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