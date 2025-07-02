// lib/pages/pet_adoption_matches_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math'; // Add this import for mathematical functions
import 'package:url_launcher/url_launcher.dart';
import '/widgets/location_picker_field.dart';


class PetAdoptionMatchesPage extends StatefulWidget {
  const PetAdoptionMatchesPage({Key? key}) : super(key: key);

  @override
  State<PetAdoptionMatchesPage> createState() => _PetAdoptionMatchesPageState();
}

class _PetAdoptionMatchesPageState extends State<PetAdoptionMatchesPage> {
  String? _selectedPetType;
  // LocationData? _userLocation;
  LocationData? selectedLocation;
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _showMatches = false;
  String? _errorMessage;
  String? _userId;
  // Pagination variables
  int _currentPage = 0;
  final int _pageSize = 10; // Load 10 items at a time
  bool _hasMoreData = true;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

    @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get userId from route arguments
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments['userId'] != null) {
      _userId = arguments['userId'] as String;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200 pixels from the bottom
      if (!_isLoadingMore && _hasMoreData && _showMatches) {
        _loadMoreMatches();
      }
    }
  }
  

  Future<void> _searchMatches() async {
  if (_selectedPetType == null || selectedLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select pet type and location'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 0;
    _matches.clear();
    _hasMoreData = true;
    _showMatches = false;
  });

  await _fetchMatches(isRefresh: true);
}

  Future<void> _fetchMatches({bool isRefresh = false}) async {
  if (_selectedPetType == null || selectedLocation == null) return;

  try {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 0;
        _matches.clear();
        _hasMoreData = true;
      });
    }

    // Get ALL adoption pets of selected type first (we'll sort them ourselves)
    final response = await Supabase.instance.client
        .from('adoption_pets')
        .select('*, users!user_id(name, phone)')
        .eq('pet_type', _selectedPetType!)
        .neq('user_id', _userId!)
        .order('created_at', ascending: false);

    final allMatches = List<Map<String, dynamic>>.from(response);
    
    // Sort matches by distance to user's location
    final sortedMatches = _sortMatchesByDistance(allMatches, selectedLocation!); // CHANGED: _userLocation to selectedLocation
    
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
      _showMatches = true;
    });

  } catch (error) {
    setState(() {
      _errorMessage = 'Error loading matches: $error';
      _isLoading = false;
      _isLoadingMore = false;
    });
  }
}


  List<Map<String, dynamic>> _sortMatchesByDistance(
    List<Map<String, dynamic>> matches, 
    LocationData selectedLocation
  ) {
    return matches.map((match) {
      double distance = double.infinity;
      
      if (match['latitude'] != null && match['longitude'] != null) {
        distance = _calculateDistance(
          selectedLocation.latitude, 
          selectedLocation.longitude,
          match['latitude'], 
          match['longitude']
        );
      }
      
      return {
        ...match,
        'distance_km': distance,
      };
    }).toList()
      ..sort((a, b) => a['distance_km'].compareTo(b['distance_km']));
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
      builder: (context) => AdoptionPetDetailModal(pet: pet),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Pets for Adoption'),
        backgroundColor: Colors.green[400],
        foregroundColor: Colors.white,
        actions: [
          if (_showMatches)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _fetchMatches(isRefresh: true),
            ),
        ],
      ),
      body: !_showMatches ? _buildSearchForm() : _buildMatchesView(),
    );
  }

  Widget _buildSearchForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find Your Perfect Pet Companion',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us what type of pet you\'re looking for and your location to find the best matches nearby.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // Pet Type Selection
          const Text(
            'What type of pet are you looking for?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPetTypeCard(
                  'Dog',
                  Icons.pets,
                  Colors.blue,
                  _selectedPetType == 'dog',
                  () => setState(() => _selectedPetType = 'dog'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPetTypeCard(
                  'Cat',
                  Icons.pets,
                  Colors.orange,
                  _selectedPetType == 'cat',
                  () => setState(() => _selectedPetType = 'cat'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Location Input
// Replace the existing location section with this:
const Text(
  'Your Location',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  ),
),
const SizedBox(height: 16),

/// Location Search Field (User Input)
LocationSearchField(
  controller: _locationController,
  labelText: 'Your Location',
  hintText: 'Type to search your location',
  enableCurrentLocation: true, // Allow users to get current location
  onLocationSelected: (LocationData? location) {
    setState(() {
      selectedLocation = location;
    });
    
    if (location != null) {
      print('Selected Address: ${location.address}');
      print('Latitude: ${location.latitude}');
      print('Longitude: ${location.longitude}');
    }
  },
  validator: (value) {
    if (selectedLocation == null) {
      return 'Please select a location';
    }
    return null;
  },
),

const SizedBox(height: 16),

// Show selected location details (optional - you can remove this if you want)
if (selectedLocation != null)
  Card(
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selected Location:',
             style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Address: ${selectedLocation!.address}'),
          Text('Coordinates: ${selectedLocation!.latitude.toStringAsFixed(6)}, ${selectedLocation!.longitude.toStringAsFixed(6)}'),
        ],
      ),
    ),
  ),

          const SizedBox(height: 32),

          // Search Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _searchMatches,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Searching...'),
                      ],
                    )
                  : const Text(
                      'Find Pets Near Me',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPetTypeCard(String title, IconData icon, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? color : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesView() {
    return Column(
      children: [
        // Header with back button and results count
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green[50],
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showMatches = false;
                    _matches.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedPetType!.toUpperCase()}S FOR ADOPTION',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Found ${_matches.length} pets${_hasMoreData ? '+' : ''} near you',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Results
        Expanded(
          child: _isLoading
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
                                'No pets found',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No ${_selectedPetType}s available for adoption in your area',
                                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.59,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _matches.length + (_hasMoreData ? 1 : 0), // +1 for loading indicator
                          itemBuilder: (context, index) {
                            // Show loading indicator at the end
                            if (index == _matches.length) {
                              return _buildLoadingCard();
                            }
                            
                            return AdoptionPetCard(
                              pet: _matches[index],
                              onViewMore: () => _showDetailedView(_matches[index]),
                            );
                          },
                        ),
        ),
      ],
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

class AdoptionPetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final VoidCallback onViewMore;

  const AdoptionPetCard({
    Key? key,
    required this.pet,
    required this.onViewMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final distance = pet['distance_km'];
    final distanceText = distance != null && distance != double.infinity
        ? distance < 1 
            ? '${(distance * 1000).round()}m away'
            : '${distance.toStringAsFixed(1)}km away'
        : 'Distance unknown';

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
              padding: const EdgeInsets.all(6.0),
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
                  const SizedBox(height: 1),
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
                  Flexible(
                    child: Text(
                      distanceText,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  // Button with minimal height
                  SizedBox(
                    width: double.infinity,
                    height: 26,
                    child: ElevatedButton(
                      onPressed: onViewMore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 1,
                      ),
                      child: const Text(
                        'View Details',
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

class AdoptionPetDetailModal extends StatelessWidget {
  final Map<String, dynamic> pet;

  const AdoptionPetDetailModal({Key? key, required this.pet}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final distance = pet['distance_km'];
    final distanceText = distance != null && distance != double.infinity
        ? distance < 1 
            ? '${(distance * 1000).round()} meters away'
            : '${distance.toStringAsFixed(1)} km away'
        : 'Distance unknown';

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

                      // Pet Name and Distance
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pet['pet_name'] ?? 'Unknown Pet',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              distanceText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Details Grid
                      _buildDetailRow('Type', pet['pet_type'] ?? 'Unknown'),
                      _buildDetailRow('Breed', pet['breed'] ?? 'Mixed breed'),
                      _buildDetailRow('Age', pet['age'] ?? 'Unknown'),
                      _buildDetailRow('Gender', pet['gender'] ?? 'Unknown'),

                      const SizedBox(height: 16),

                      // Characteristics
                      if (pet['sterilized'] != null)
                        _buildDetailRow('Sterilized', _formatYesNoUnknown(pet['sterilized'])),
                      if (pet['vaccinated'] != null)
                        _buildDetailRow('Vaccinated', _formatYesNoUnknown(pet['vaccinated'])),

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
                      
                      // Contact Information
                      if (pet['users'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact Owner',
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
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.phone,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
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
                                              
                                              // Add country code if not present
                                              if (!cleanPhone.startsWith('+')) {
                                                cleanPhone = '+91$cleanPhone'; // Assuming India, adjust as needed
                                              }
                                              
                                              final Uri whatsappUri = Uri.parse('https://wa.me/$cleanPhone?text=Hi! I\'m interested in adopting ${pet['pet_name'] ?? 'your pet'}. Is it still available?');
                                              
                                              if (await canLaunchUrl(whatsappUri)) {
                                                await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Could not launch WhatsApp'),
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
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.chat,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
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
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatYesNoUnknown(dynamic value) {
    if (value == null) return 'Unknown';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'true':
        case 'yes':
        case '1':
          return 'Yes';
        case 'false':
        case 'no':
        case '0':
          return 'No';
        default:
          return 'Unknown';
      }
    }
    return 'Unknown';
  }
}