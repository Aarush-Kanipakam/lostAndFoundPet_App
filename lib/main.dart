import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'pages/auth/phone_auth_page.dart';
import 'pages/home/home_page.dart';
import 'pages/pets/report_found_pet_page.dart';
import 'pages/pets/report_lost_pet_page.dart';
import 'pages/pets/reported_pets_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/pets/pet_matches_page.dart';
import 'pages/pets/put_up_for_adoption_page.dart';
import 'pages/pets/pet_adoption_matches_page.dart';
import 'pages/pets/report_lost_pet_page.dart' as lost_pet;
import 'pages/pets/report_found_pet_page.dart' as found_pet;
import 'pages/pets/put_up_for_adoption_page.dart' as pet;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase using environment variables
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Finder',
      theme: ThemeData(

        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/auth': (context) => const PhoneAuthPage(),
        '/home': (context) => const HomePage(),
        '/lost': (context) => const ReportLostPetPage(),
        '/found': (context) => const ReportFoundPetPage(),
        '/reported': (context) => const ReportedPetsPage(),
        '/matches': (context) => const PetMatchesPage(),
        '/putUpForAdoption': (context) => const PutUpForAdoptionPage(),
        '/adoptionMatches': (context) => const PetAdoptionMatchesPage(),
        // Add this route to your MaterialApp routes
        '/edit-report-lost-dog': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final reportData = arguments?['reportData'] as Map<String, dynamic>?;
          final userId = arguments?['userId'] as String?;
          
          if (reportData != null) {
            return lost_pet.DogDetailsPage(
              petName: reportData['pet_name'] ?? 'Unknown Pet',
              userId: userId,
              editData: reportData,
            );
          }
          
          // Fallback to regular report page if no data
          return const ReportLostPetPage();
        },
        '/edit-report-found-dog': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final reportData = arguments?['reportData'] as Map<String, dynamic>?;
          final userId = arguments?['userId'] as String?;
          
          if (reportData != null) {
            return found_pet.DogDetailsPage(
              petName: reportData['pet_name'] ?? 'Unknown Pet',
              userId: userId,
              editData: reportData,
            );
          }
          
          // Fallback to regular report page if no data
          return const ReportFoundPetPage();
        },
        '/edit-report-lost-cat': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final reportData = arguments?['reportData'] as Map<String, dynamic>?;
          final userId = arguments?['userId'] as String?;
          
          if (reportData != null) {
            return lost_pet.CatDetailsPage(
              petName: reportData['pet_name'] ?? 'Unknown Pet',
              userId: userId,
              editData: reportData,
            );
          }
          
          // Fallback to regular report page if no data
          return const ReportLostPetPage();
        },
        '/edit-report-found-cat': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final reportData = arguments?['reportData'] as Map<String, dynamic>?;
          final userId = arguments?['userId'] as String?;
          
          if (reportData != null) {
            return found_pet.CatDetailsPage(
              petName: reportData['pet_name'] ?? 'Unknown Pet',
              userId: userId,
              editData: reportData,
            );
          }
          
          // Fallback to regular report page if no data
          return const ReportFoundPetPage();
        },
        '/edit-report-adoption-dog': (context) {
        final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final reportData = arguments?['reportData'] as Map<String, dynamic>?;
        final userId = arguments?['userId'] as String?;

        if (reportData != null) {
          return pet.DogDetailsPage(
            petName: reportData['pet_name'] ?? 'Unknown Pet',
            userId: userId,
            editData: reportData,
          );
        }

        // Fallback to new adoption form if no data is provided
        return const PutUpForAdoptionPage();
      },
      '/edit-report-adoption-cat': (context) {
        final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final reportData = arguments?['reportData'] as Map<String, dynamic>?;
        final userId = arguments?['userId'] as String?;

        if (reportData != null) {
          return pet.CatDetailsPage(
            petName: reportData['pet_name'] ?? 'Unknown Pet',
            userId: userId,
            editData: reportData,
          );
        }

        // Fallback to new adoption form if no data is provided
        return const PutUpForAdoptionPage();
      },

      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      final user = FirebaseAuth.instance.currentUser;
      
      setState(() {
        _isLoggedIn = isLoggedIn && user != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _isLoggedIn ? const HomePage() : const PhoneAuthPage();
  }
}

