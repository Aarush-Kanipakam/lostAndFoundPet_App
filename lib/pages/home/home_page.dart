// pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  // Option 1: Constructor parameter (if using direct navigation)
  final String? userId;
  
  const HomePage({Key? key, this.userId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userId;
  String? _userName;
  String? _userPhone;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Option 2: Get userId from route arguments (if using named routes)
    if (_userId == null) {
      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments != null && arguments['userId'] != null) {
        _userId = arguments['userId'] as String;
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        // Prioritize constructor parameter, then route arguments, then SharedPreferences
        _userId = widget.userId ?? 
                 _userId ?? 
                 prefs.getString('userId');
        _userName = prefs.getString('userName') ?? 'User';
        _userPhone = prefs.getString('userPhone');
        _isLoading = false;
      });
      
      // Debug print to verify userId is received
      print('HomePage loaded with userId: $_userId');
      
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Close loading dialog and navigate to auth page
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Finder'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              
              // Welcome message with user name
              Text(
                'Welcome${_userName != null ? ', $_userName' : ''}!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'You are successfully logged in',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              
              // Show user details (for debugging/verification)
              if (_userId != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User ID: $_userId', style: const TextStyle(fontSize: 12)),
                      if (_userPhone != null) 
                        Text('Phone: $_userPhone', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 40),

              // Report Lost Pet Button
              ElevatedButton.icon(
                onPressed: () {
                  // Pass userId to lost pet page
                  Navigator.pushNamed(
                    context, 
                    '/lost',
                    arguments: {'userId': _userId},
                  );
                },
                icon: const Icon(Icons.report_problem),
                label: const Text('Report a Lost Pet'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Report Found Pet Button
              ElevatedButton.icon(
                onPressed: () {
                  // Pass userId to found pet page
                  Navigator.pushNamed(
                    context, 
                    '/found',
                    arguments: {'userId': _userId},
                  );
                },
                icon: const Icon(Icons.pets),
                label: const Text('Report a Found Pet'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Your Reported Pets Button
              ElevatedButton.icon(
                onPressed: () {
                  // Pass userId to reported pets page
                  Navigator.pushNamed(
                    context, 
                    '/reported',
                    arguments: {'userId': _userId},
                  );
                },
                icon: const Icon(Icons.pets),
                label: const Text('Your Reported Pets'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color.fromARGB(255, 29, 68, 160),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}