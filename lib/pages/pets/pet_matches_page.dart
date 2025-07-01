// lib/pages/pets/pet_matches_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math'; // Add this import for mathematical functions
import 'package:url_launcher/url_launcher.dart';
class PetMatchesPage extends StatefulWidget {
  const PetMatchesPage({Key? key}) : super(key: key);

  @override
  State<PetMatchesPage> createState() => _PetMatchesPageState();
}

class _PetMatchesPageState extends State<PetMatchesPage> {
  String? _reportType;
  String? _petType;
  String? _userReportId;
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  Map<String, dynamic>? _userPetDetails; // Add this line
  
  // Pagination variables
  int _currentPage = 0;
  final int _pageSize = 10; // Load 10 items at a time
  bool _hasMoreData = true;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get arguments from route
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _reportType = arguments['reportType'] as String?;
      _petType = arguments['petType'] as String?;
      _userReportId = arguments['userReportId'] as String?;
      _fetchMatches(isRefresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200 pixels from bottom
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreMatches();
      }
    }
  }

  Future<void> _fetchMatches({bool isRefresh = false}) async {
    if (_reportType == null || _petType == null || _userReportId == null) return;

    try {
      if (isRefresh) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _currentPage = 0;
          _matches.clear();
          _hasMoreData = true;
          _userPetDetails = null; // Reset user pet details
        });
      }

      // First, get the user's original pet details for comparison (only once)
      if (_userPetDetails == null) {
        final userPetResponse = await Supabase.instance.client
            .from('pet_reports')
            .select('*')
            .eq('user_id', _userReportId!)
            .eq('report_type', _reportType!)
            .eq('pet_type', _petType!)
            .limit(1)
            .single();
        
        _userPetDetails = userPetResponse;
      }

      // Get opposite report type for matching
      String oppositeType = _reportType == 'lost' ? 'found' : 'lost';

      // Get ALL matching pets first (we'll sort them ourselves)
      final response = await Supabase.instance.client
          .from('pet_reports')
          .select('*, users!user_id(name, phone)')
          .eq('report_type', oppositeType)
          .eq('pet_type', _petType!)
          .neq('user_id', _userReportId!)
          .order('created_at', ascending: false);

      final allMatches = List<Map<String, dynamic>>.from(response);
      
      // Sort matches by similarity to user's pet
      final sortedMatches = _sortMatchesBySimilarity(allMatches, _userPetDetails!);
      
      // Apply pagination to sorted results
      final startIndex = _currentPage * _pageSize;
      final endIndex = startIndex + _pageSize;
      final paginatedMatches = sortedMatches.sublist(
        startIndex, 
        endIndex > sortedMatches.length ? sortedMatches.length : endIndex
      );

      setState(() {
        if (isRefresh) {
          _matches = paginatedMatches;
        } else {
          _matches.addAll(paginatedMatches);
        }
        _hasMoreData = endIndex < sortedMatches.length;
        _isLoading = false;
        _isLoadingMore = false;
      });

    } catch (error) {
      setState(() {
        _errorMessage = 'Error loading matches: $error';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }
  List<Map<String, dynamic>> _sortMatchesBySimilarity(
  List<Map<String, dynamic>> matches, 
  Map<String, dynamic> userPet
) {
  return matches.map((match) {
    double similarity = _calculateSimilarity(match, userPet);
    return {
      ...match,
      'similarity_score': similarity,
    };
  }).toList()
    ..sort((a, b) => b['similarity_score'].compareTo(a['similarity_score']));
}

double _calculateSimilarity(Map<String, dynamic> match, Map<String, dynamic> userPet) {
  double score = 0.0;
  
  // 1. LOCATION PRIORITY (40% weight) - Highest priority
  if (userPet['latitude'] != null && userPet['longitude'] != null &&
      match['latitude'] != null && match['longitude'] != null) {
    double distance = _calculateDistance(
      userPet['latitude'], userPet['longitude'],
      match['latitude'], match['longitude']
    );
    
    // Convert distance to score (closer = higher score)
    // Max 40 points for location within 1km, decreasing exponentially
    if (distance <= 1.0) {
      score += 40.0;
    } else if (distance <= 5.0) {
      score += 30.0;
    } else if (distance <= 10.0) {
      score += 20.0;
    } else if (distance <= 25.0) {
      score += 10.0;
    } else {
      score += 5.0; // Still some points for far locations
    }
  }
  
  // 2. BREED MATCH (25% weight) - Second priority
  if (userPet['breed'] != null && match['breed'] != null) {
    String userBreed = userPet['breed'].toString().toLowerCase();
    String matchBreed = match['breed'].toString().toLowerCase();
    
    if (userBreed == matchBreed) {
      score += 25.0;
    } else if (userBreed.contains(matchBreed) || matchBreed.contains(userBreed)) {
      score += 15.0; // Partial breed match
    }
  }
  
  // 3. PHYSICAL CHARACTERISTICS (35% total weight)
  
  // Color match (10% weight)
  if (userPet['color'] != null && match['color'] != null) {
    if (userPet['color'].toString().toLowerCase() == 
        match['color'].toString().toLowerCase()) {
      score += 10.0;
    }
  }
  
  // Gender match (8% weight)
  if (userPet['gender'] != null && match['gender'] != null) {
    if (userPet['gender'].toString().toLowerCase() == 
        match['gender'].toString().toLowerCase()) {
      score += 8.0;
    }
  }
  
  // Age similarity (7% weight)
  if (userPet['age'] != null && match['age'] != null) {
    String userAge = userPet['age'].toString().toLowerCase();
    String matchAge = match['age'].toString().toLowerCase();
    
    if (userAge == matchAge) {
      score += 7.0;
    } else if ((userAge.contains('young') && matchAge.contains('young')) ||
               (userAge.contains('adult') && matchAge.contains('adult')) ||
               (userAge.contains('senior') && matchAge.contains('senior'))) {
      score += 4.0;
    }
  }
  
  // Size match (5% weight)
  if (userPet['pet_type_category'] != null && match['pet_type_category'] != null) {
    if (userPet['pet_type_category'].toString().toLowerCase() == 
        match['pet_type_category'].toString().toLowerCase()) {
      score += 5.0;
    }
  }
  
  // Special characteristics (5% weight total)
  List<String> characteristics = ['sterilized', 'ear_notched', 'collar'];
  for (String char in characteristics) {
    if (userPet[char] != null && match[char] != null) {
      if (userPet[char].toString().toLowerCase() == 
          match[char].toString().toLowerCase()) {
        score += 1.5;
      }
    }
  }
  
  return score;
}

// Haversine formula to calculate distance between two points
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // Earth's radius in kilometers
  
  double dLat = _degreesToRadians(lat2 - lat1);
  double dLon = _degreesToRadians(lon2 - lon1);
  
  double a = (sin(dLat / 2) * sin(dLat / 2)) +
      cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
      (sin(dLon / 2) * sin(dLon / 2));
  
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return earthRadius * c;
}

double _degreesToRadians(double degrees) {
  return degrees * (pi / 180);
}

  Future<void> _loadMoreMatches() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _fetchMatches();
  }

  void _showDetailedView(Map<String, dynamic> pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => PetDetailModal(pet: pet),
    );
  }

  String get _getTitle {
    if (_reportType == null || _petType == null) return 'Matches';
    String oppositeType = _reportType == 'lost' ? 'found' : 'lost';
    return '${oppositeType.toUpperCase()} ${_petType!.toUpperCase()}S';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle),
        backgroundColor: _reportType == 'lost' ? Colors.blue[400] : Colors.red[400],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchMatches(isRefresh: true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: TextStyle(color: Colors.red[400])),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _fetchMatches(isRefresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _matches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No matches found',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No ${_reportType == 'lost' ? 'found' : 'lost'} ${_petType}s available',
                            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Found ${_matches.length} potential matches${_hasMoreData ? '+' : ''}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.6,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _matches.length + (_hasMoreData ? 1 : 0), // +1 for loading indicator
                            itemBuilder: (context, index) {
                              // Show loading indicator at the end
                              if (index == _matches.length) {
                                return _buildLoadingCard();
                              }
                              
                              return PetMatchCard(
                                pet: _matches[index],
                                onViewMore: () => _showDetailedView(_matches[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Loading more...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetMatchCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final VoidCallback onViewMore;

  const PetMatchCard({
    Key? key,
    required this.pet,
    required this.onViewMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image section - takes up more space
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: pet['image_url'] != null && pet['image_url'].isNotEmpty
                  ? Image.network(
                      pet['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.pets, size: 50, color: Colors.grey[400]),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.pets, size: 50, color: Colors.grey[400]),
                    ),
            ),
          ),
          // Content section - optimized layout
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(6.0), // Further reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      pet['pet_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 1), // Minimal spacing
                  Flexible(
                    child: Text(
                      pet['breed'] ?? 'Mixed breed',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  // Button with minimal height
                  SizedBox(
                    width: double.infinity,
                    height: 26, // Further reduced button height
                    child: ElevatedButton(
                      onPressed: onViewMore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4), // Minimal padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 1,
                      ),
                      child: const Text(
                        'View More',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PetDetailModal extends StatelessWidget {
  final Map<String, dynamic> pet;

  const PetDetailModal({Key? key, required this.pet}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pet Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 250,
                          width: double.infinity,
                          child: pet['image_url'] != null && pet['image_url'].isNotEmpty
                              ? Image.network(
                                  pet['image_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.pets, size: 100, color: Colors.grey[400]),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.pets, size: 100, color: Colors.grey[400]),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Pet Name
                      Text(
                        pet['pet_name'] ?? 'Unknown Pet',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Details Grid
                      _buildDetailRow('Type', pet['pet_type'] ?? 'Unknown'),
                      _buildDetailRow('Breed', pet['breed'] ?? 'Mixed breed'),
                      _buildDetailRow('Age', pet['age'] ?? 'Unknown'),
                      _buildDetailRow('Gender', pet['gender'] ?? 'Unknown'),
                      _buildDetailRow('Color', pet['color'] ?? 'Unknown'),
                      _buildDetailRow('Size', pet['pet_type_category'] ?? 'Unknown'),

                      const SizedBox(height: 16),

                      // Characteristics (handling "yes", "no", "unknown")
                      if (pet['sterilized'] != null)
                        _buildDetailRow('Sterilized', _formatYesNoUnknown(pet['sterilized'])),
                      if (pet['ear_notched'] != null)
                        _buildDetailRow('Ear Notched', _formatYesNoUnknown(pet['ear_notched'])),
                      if (pet['collar'] != null)
                        _buildDetailRow('Has Collar', _formatYesNoUnknown(pet['collar'])),
                      if (pet['injured'] != null)
                        _buildDetailRow('Injured', _formatYesNoUnknown(pet['injured'])),
                      if (pet['friendly'] != null)
                        _buildDetailRow('Friendly', pet['friendly']), // Show value as-is

                      const SizedBox(height: 16),

                      // Location
                      if (pet['location_address'] != null)
                        _buildDetailRow('Location', pet['location_address']),

                      const SizedBox(height: 16),

                      // Additional Details
                      if (pet['additional_details'] != null && pet['additional_details'].isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Additional Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                pet['additional_details'],
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),
                      
                      // Contact Information - Updated to show name and phone with call and WhatsApp buttons
                      if (pet['users'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reported By',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Name: ${pet['users']['name'] ?? 'Unknown'}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Phone: ${pet['users']['phone'] ?? 'Not provided'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      // Call Button
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            final phone = pet['users']['phone'];
                                            if (phone != null && phone.isNotEmpty) {
                                              final Uri phoneUri = Uri(scheme: 'tel', path: phone);
                                              if (await canLaunchUrl(phoneUri)) {
                                                await launchUrl(phoneUri);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Could not launch phone dialer'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[600],
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.phone,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Call',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // WhatsApp Button
                                      
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            final phone = pet['users']['phone'];
                                            if (phone != null && phone.isNotEmpty) {
                                              // Remove any spaces, dashes, or special characters
                                              String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
                                              
                                              // Add country code if not present (assuming India +91)
                                              if (!cleanPhone.startsWith('+')) {
                                                if (cleanPhone.startsWith('91')) {
                                                  cleanPhone = '+$cleanPhone';
                                                } else {
                                                  cleanPhone = '+91$cleanPhone';
                                                }
                                              }
                                              
                                              // Remove the + for WhatsApp URL
                                              String whatsappPhone = cleanPhone.replaceAll('+', '');
                                              
                                              // Try different WhatsApp URL schemes
                                              final List<String> whatsappUrls = [
                                                'whatsapp://send?phone=$whatsappPhone',
                                                'https://api.whatsapp.com/send?phone=$whatsappPhone',
                                                'https://wa.me/$whatsappPhone',
                                              ];
                                              
                                              bool launched = false;
                                              
                                              for (String url in whatsappUrls) {
                                                final Uri uri = Uri.parse(url);
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                  launched = true;
                                                  break;
                                                }
                                              }
                                              
                                              if (!launched) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('WhatsApp is not installed or could not be opened'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.green[600],
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.chat,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'WhatsApp',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatYesNoUnknown(dynamic value) {
  final val = value?.toString().toLowerCase();
  if (val == 'yes') return 'Yes';
  if (val == 'no') return 'No';
  return 'Unknown';
}