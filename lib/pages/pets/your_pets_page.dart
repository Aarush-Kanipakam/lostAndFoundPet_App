// lib/pages/pets/your_pets_page.dart
import 'package:flutter/material.dart';

class YourPetsPage extends StatelessWidget {
  final String petType; // 'lost' or 'found'
  
  const YourPetsPage({Key? key, required this.petType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLost = petType == 'lost';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Your ${isLost ? 'Lost' : 'Found'} Pets'),
        backgroundColor: isLost ? Colors.red[400] : Colors.green[400],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLost ? Icons.search : Icons.list,
              size: 100,
              color: isLost ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              'Hi from Your ${isLost ? 'Lost' : 'Found'} Pets Page!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This page will show your ${petType} pet reports',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}