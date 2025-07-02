// lib/pages/pets/your_pets_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportedPetsPage extends StatefulWidget {
  const ReportedPetsPage({Key? key}) : super(key: key);

  @override
  State<ReportedPetsPage> createState() => _ReportedPetsPageState();
}

class _ReportedPetsPageState extends State<ReportedPetsPage> {
  String? _userId;
  List<Map<String, dynamic>> _petReports = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get userId from route arguments
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments['userId'] != null) {
      _userId = arguments['userId'] as String;
      _fetchPetReports();
    }
  }

  Future<void> _fetchPetReports() async {
    if (_userId == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await Supabase.instance.client
          .from('pet_reports')
          .select('*, report_type, pet_type')
          .eq('user_id', _userId!);

      setState(() {
        _petReports = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

    } catch (error) {
      setState(() {
        _errorMessage = 'Error loading pet reports: $error';
        _isLoading = false;
      });
    }
  }

  Widget _buildPetReportCard(Map<String, dynamic> report) {
    final reportType = report['report_type'] ?? 'Unknown';
    final petType = report['pet_type'] ?? 'Unknown';
    final String petName = report['pet_name'] ?? 'Unnamed Pet';
    // Set colors based on report type
    Color cardColor = reportType.toLowerCase() == 'lost' 
        ? Colors.red[50]! 
        : Colors.blue[50]!;
    Color iconColor = reportType.toLowerCase() == 'lost' 
        ? Colors.red[400]! 
        : Colors.blue[400]!;
    IconData icon = reportType.toLowerCase() == 'lost' 
        ? Icons.pets_outlined 
        : Icons.favorite_outlined;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 30),
                const SizedBox(width: 12),
                Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${reportType.toUpperCase()} ${petType.toUpperCase()} : $petName',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      
                        Navigator.pushNamed(
                          context, 
                          '/matches',
                          arguments: {
                            'userReportId': _userId, 
                            'reportType': reportType, 
                            'petType': petType,
                            'reportId': report['id'] // Add this line to pass the specific report ID
                          },
                        );
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Checking matches for ${reportType.toLowerCase()} $petType...'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Check Matches',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Fixed resolve button section
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        // Show loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Deleting report...')),
                        );

                        await Supabase.instance.client
                            .from('pet_reports')
                            .delete()
                            .eq('id', report['id']);

                        // Check if deletion was successful and refresh the list
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Report deleted successfully.')),
                        );
                        
                        // Refresh the pet reports list after successful deletion
                        _fetchPetReports();
                        
                      } catch (error) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete report: $error')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Resolve Issue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                            ],
          ),
        ],
      ),
    ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Pets'),
        backgroundColor: const Color.fromARGB(255, 193, 71, 234),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPetReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchPetReports,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _petReports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pets,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reports :(',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You haven\'t reported any pets yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Your Pet Reports (${_petReports.length})',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _petReports.length,
                            itemBuilder: (context, index) {
                              return _buildPetReportCard(_petReports[index]);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}