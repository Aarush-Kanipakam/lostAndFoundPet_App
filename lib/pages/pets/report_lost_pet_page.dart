import 'package:flutter/material.dart';
import '/widgets/date_picker_form_field.dart';
import '/widgets/picture_upload_section.dart';
import '/widgets/location_picker_field.dart';
import 'dart:io';
import '/services/pet_report_service.dart';

// Main report page - Step 1
class ReportLostPetPage extends StatefulWidget {
  const ReportLostPetPage({Key? key}) : super(key: key);

  @override
  State<ReportLostPetPage> createState() => _ReportLostPetPageState();
}

class _ReportLostPetPageState extends State<ReportLostPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _petNameController = TextEditingController();
  String? selectedPetType;
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // ADD THIS METHOD - Get userId from route arguments
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments['userId'] != null) {
      _userId = arguments['userId'] as String;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 248, 248),
      body: Column(
        children: [
          // Custom App Bar
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 10, 10),
            decoration: const BoxDecoration(
              color: Colors.red,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 255, 255, 255)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Report Lost Pet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Let\'s start with basic information:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pet Name
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _petNameController,
                        decoration: const InputDecoration(
                          labelText: 'Pet Name',
                          hintText: 'e.g. Bruno',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'Please enter your pet\'s name';
                        //   }
                        //   return null;
                        // },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pet Type Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Pet Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        value: selectedPetType,
                        items: const [
                          DropdownMenuItem(value: 'dog', child: Text('Dog')),
                          DropdownMenuItem(value: 'cat', child: Text('Cat')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedPetType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select pet type';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Next Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // Navigate to specific pet page
                            if (selectedPetType == 'dog') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DogDetailsPage(
                                    petName: _petNameController.text,
                                    userId: _userId,
                                  ),
                                ),
                              );
                            } else if (selectedPetType == 'cat') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CatDetailsPage(
                                    petName: _petNameController.text,
                                    userId: _userId,
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _petNameController.dispose();
    super.dispose();
  }
}

// Dog Details Page - Step 2
class DogDetailsPage extends StatefulWidget {
  final String petName;
  final String? userId;
  const DogDetailsPage({Key? key, required this.petName, this.userId}) : super(key: key);

  @override
  State<DogDetailsPage> createState() => _DogDetailsPageState();
}

class _DogDetailsPageState extends State<DogDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _petTypeController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _sterilizedController = TextEditingController();
  final TextEditingController _earNotchedController = TextEditingController();
  final TextEditingController _collarController = TextEditingController();
  final TextEditingController _injuredController = TextEditingController();
  final TextEditingController _friendlyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _additionalDetailsController = TextEditingController();
  DateTime? lostDate;
  File? selectedPetImage;  
  LocationData? selectedLocation;
  
  final PetReportService _petReportService = PetReportService();
  bool _isSubmitting = false;


    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.petName} - Dog Details'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tell us more about ${widget.petName}:',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),

                      /// Age Field
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          hintText: 'e.g. 2 years, 6 months, Unknown',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the age';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DatePickerFormField(
                        label: 'Date Lost',
                        selectedDate: lostDate,
                        onDateSelected: (picked) {
                          setState(() {
                            lostDate = picked;
                          });
                        },
                      ),


                      const SizedBox(height: 16),
                      /// Pet Type / Community Dog
                      DropdownButtonFormField<String>(
                        value: _petTypeController.text.isEmpty ? null : _petTypeController.text,
                        decoration: const InputDecoration(
                          labelText: 'Pet Type',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Pet Dog',
                          'Community Dog',
                          'Stray Dog',
                          'Unknown',
                        ].map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _petTypeController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select pet type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Gender Dropdown
                      DropdownButtonFormField<String>(
                        value: _genderController.text.isEmpty ? null : _genderController.text,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Male',
                          'Female',
                          'Unknown',
                        ].map((gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _genderController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select gender';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Breed Dropdown
                      DropdownButtonFormField<String>(
                        value: _breedController.text.isEmpty ? null : _breedController.text,
                        decoration: const InputDecoration(
                          labelText: 'Breed',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Labrador Retriever',
                          'German Shepherd',
                          'Golden Retriever',
                          'Beagle',
                          'Pug',
                          'Shih Tzu',
                          'Rottweiler',
                          'Pomeranian',
                          'Doberman Pinscher',
                          'Dachshund',
                          'Boxer',
                          'Great Dane',
                          'Cocker Spaniel',
                          'Husky',
                          'Saint Bernard',
                          'Indie Dog (Indian Street Dog)',
                          'Mixed Breed',
                          'Unknown',
                        ].map((breed) {
                          return DropdownMenuItem<String>(
                            value: breed,
                            child: Text(breed),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _breedController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a breed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Sterilized Dropdown
                      DropdownButtonFormField<String>(
                        value: _sterilizedController.text.isEmpty ? null : _sterilizedController.text,
                        decoration: const InputDecoration(
                          labelText: 'Sterilized',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Yes',
                          'No',
                          'Unknown',
                        ].map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _sterilizedController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select sterilization status';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Ear Notched Dropdown
                      DropdownButtonFormField<String>(
                        value: _earNotchedController.text.isEmpty ? null : _earNotchedController.text,
                        decoration: const InputDecoration(
                          labelText: 'Ear Notched',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Yes',
                          'No',
                          'Unknown',
                        ].map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _earNotchedController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select ear notch status';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Collar Dropdown
                      DropdownButtonFormField<String>(
                        value: _collarController.text.isEmpty ? null : _collarController.text,
                        decoration: const InputDecoration(
                          labelText: 'Collar',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Yes',
                          'No',
                          'Unknown',
                        ].map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _collarController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select collar status';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Injured Dropdown
                      DropdownButtonFormField<String>(
                        value: _injuredController.text.isEmpty ? null : _injuredController.text,
                        decoration: const InputDecoration(
                          labelText: 'Injured?',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Yes',
                          'No',
                          'Unknown',
                        ].map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _injuredController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select injury status';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Friendly Dropdown
                      DropdownButtonFormField<String>(
                        value: _friendlyController.text.isEmpty ? null : _friendlyController.text,
                        decoration: const InputDecoration(
                          labelText: 'Friendly?',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Very Friendly',
                          'Friendly',
                          'Neutral',
                          'Cautious',
                          'Aggressive',
                          'Unknown',
                        ].map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _friendlyController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select friendliness level';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Color Field
                      DropdownButtonFormField<String>(
                        value: _colorController.text.isEmpty ? null : _colorController.text,
                        decoration: const InputDecoration(
                          labelText: 'Color / Markings',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Black',
                          'Brown',
                          'White',
                          'Golden',
                          'Gray',
                          'Black and White',
                          'Brown and White',
                          'Black and Brown',
                          'Tri-color',
                          'Spotted',
                          'Brindle',
                          'Other',
                        ].map((color) {
                          return DropdownMenuItem<String>(
                            value: color,
                            child: Text(color),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _colorController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select color/markings';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Location Lost Field (User Input)
                      LocationSearchField(
                        controller: _locationController,
                        labelText: 'Location Lost',
                        hintText: 'Type to search location',
                        onLocationSelected: (LocationData? location) {
                          setState(() {
                            selectedLocation = location;
                          });
                          
                          if (location != null) {
                            print('Address: ${location.address}');
                            print('Latitude: ${location.latitude}');
                            print('Longitude: ${location.longitude}');
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a location';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Show selected location details
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
                              //   Text('Coordinates: ${selectedLocation!.latitude.toStringAsFixed(6)}, ${selectedLocation!.longitude.toStringAsFixed(6)}'),
                               ],
                            ),
                          ),
                        ),



                      
                      /// Picture Upload Section
                      PictureUploadSection(
                        title: 'Pet Photo',
                        buttonText: 'Add Pet Photo',
                        onImageSelected: (File? image) {
                          setState(() {
                            selectedPetImage = image;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Additional Details Field (User Input)
                      TextFormField(
                        controller: _additionalDetailsController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Details',
                          hintText: 'Any other information that might help...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'Please provide additional details';
                        //   }
                        //   return null;
                        // },
                      ),
                      const SizedBox(height: 30),

                      /// Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting 
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
                                  SizedBox(width: 10),
                                  Text('Submitting...', style: TextStyle(fontSize: 16)),
                                ],
                              )
                            : const Text('Submit Report', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),

    );
  }

Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? imageUrl;
      
      // Upload image if selected
      if (selectedPetImage != null) {
        imageUrl = await _petReportService.uploadImage(
          selectedPetImage!,
          '${widget.petName}_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      // Submit the report
      final success = await _petReportService.submitPetReport(
        petName: widget.petName,
        petType: 'dog',
        reportType: 'lost',
        age: _ageController.text,
        dateLost: lostDate,
        petTypeCategory: _petTypeController.text,
        gender: _genderController.text,
        breed: _breedController.text,
        sterilized: _sterilizedController.text,
        earNotched: _earNotchedController.text,
        collar: _collarController.text,
        injured: _injuredController.text,
        friendly: _friendlyController.text,
        color: _colorController.text,
        locationAddress: _locationController.text,
        latitude: selectedLocation?.latitude,
        longitude: selectedLocation?.longitude,
        additionalDetails: _additionalDetailsController.text,
        imageUrl: imageUrl,
        userId: widget.userId,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.petName} report submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        throw Exception('Failed to submit report');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _breedController.dispose();
    _colorController.dispose();
    _ageController.dispose();
    _petTypeController.dispose();
    _genderController.dispose();
    _sterilizedController.dispose();
    _earNotchedController.dispose();
    _collarController.dispose();
    _injuredController.dispose();
    _friendlyController.dispose();
    _locationController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }
}


// Cat Details Page - Step 2
class CatDetailsPage extends StatefulWidget {
  final String petName;
  final String? userId;
  
  const CatDetailsPage({Key? key, required this.petName, this.userId}) : super(key: key);
  
  @override
  State<CatDetailsPage> createState() => _CatDetailsPageState();
}

class _CatDetailsPageState extends State<CatDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _petTypeController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _sterilizedController = TextEditingController();
  final TextEditingController _earNotchedController = TextEditingController();
  final TextEditingController _collarController = TextEditingController();
  final TextEditingController _injuredController = TextEditingController();
  final TextEditingController _friendlyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _additionalDetailsController = TextEditingController();
  DateTime? lostDate;
  File? selectedPetImage;
  LocationData? selectedLocation;
  final PetReportService _petReportService = PetReportService();
  bool _isSubmitting = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.petName} - Cat Details'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tell us more about ${widget.petName}:',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),

                      /// Age Field
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          hintText: 'e.g. 2 years, 6 months, Unknown',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the age';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                                            DatePickerFormField(
                        label: 'Date Lost',
                        selectedDate: lostDate,
                        onDateSelected: (picked) {
                          setState(() {
                            lostDate = picked;
                          });
                        },
                      ),


                      const SizedBox(height: 16),
                      /// Pet Type / Community Dog
                      DropdownButtonFormField<String>(
                        value: _petTypeController.text.isEmpty ? null : _petTypeController.text,
                        decoration: const InputDecoration(
                          labelText: 'Pet Type',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Pet Cat',
                          'Community Cat',
                          'Stray Cat',
                          'Unknown',
                        ].map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _petTypeController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select pet type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Gender Dropdown
                      DropdownButtonFormField<String>(
                        value: _genderController.text.isEmpty ? null : _genderController.text,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Male',
                          'Female',
                          'Unknown',
                        ].map((gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _genderController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select gender';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Breed Dropdown
                      DropdownButtonFormField<String>(
                        value: _breedController.text.isEmpty ? null : _breedController.text,
                        decoration: const InputDecoration(
                          labelText: 'Breed',
                          border: OutlineInputBorder(),
                        ),
                        
                        items: [
                            'Persian Cat',
                            'Siamese Cat',
                            'Maine Coon',
                            'Himalayan Cat',
                            'Bengal Cat',
                            'Ragdoll Cat',
                            'British Shorthair',
                            'Scottish Fold',
                            'Russian Blue',
                            'Sphynx Cat',
                            'Indian Billi (Indian Street Cat)',
                            'Unknown'
                        ].map((breed) {
                          return DropdownMenuItem<String>(
                            value: breed,
                            child: Text(breed),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _breedController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a breed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Sterilized Dropdown
                      DropdownButtonFormField<String>(
                        value: _sterilizedController.text.isEmpty ? null : _sterilizedController.text,
                        decoration: const InputDecoration(
                          labelText: 'Sterilized',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Yes',
                          'No',
                          'Unknown',
                        ].map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _sterilizedController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select sterilization status';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Ear Notched Dropdown
                      DropdownButtonFormField<String>(
                        value: _earNotchedController.text.isEmpty ? null : _earNotchedController.text,
                        decoration: const InputDecoration(
                          labelText: 'Ear Notched',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Yes',
                          'No',
                          'Unknown',
                        ].map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _earNotchedController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select ear notch status';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Collar Dropdown
                      DropdownButtonFormField<String>(
                        value: _collarController.text.isEmpty ? null : _collarController.text,
                        decoration: const InputDecoration(
                          labelText: 'Collar',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Yes',
                          'No',
                          'Unknown',
                        ].map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _collarController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select collar status';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Injured Dropdown
                      DropdownButtonFormField<String>(
                        value: _injuredController.text.isEmpty ? null : _injuredController.text,
                        decoration: const InputDecoration(
                          labelText: 'Injured?',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Yes',
                          'No',
                          'Unknown',
                        ].map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _injuredController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select injury status';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Friendly Dropdown
                      DropdownButtonFormField<String>(
                        value: _friendlyController.text.isEmpty ? null : _friendlyController.text,
                        decoration: const InputDecoration(
                          labelText: 'Friendly?',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Very Friendly',
                          'Friendly',
                          'Neutral',
                          'Cautious',
                          'Aggressive',
                          'Unknown',
                        ].map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _friendlyController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select friendliness level';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Color Field
                      DropdownButtonFormField<String>(
                        value: _colorController.text.isEmpty ? null : _colorController.text,
                        decoration: const InputDecoration(
                          labelText: 'Color / Markings',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Black',
                          'Brown',
                          'White',
                          'Golden',
                          'Gray',
                          'Black and White',
                          'Brown and White',
                          'Black and Brown',
                          'Tri-color',
                          'Spotted',
                          'Brindle',
                          'Other',
                        ].map((color) {
                          return DropdownMenuItem<String>(
                            value: color,
                            child: Text(color),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _colorController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select color/markings';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Location Lost Field (User Input)
                      /// Location Lost Field (User Input)
                      LocationSearchField(
                        controller: _locationController,
                        labelText: 'Location Lost',
                        hintText: 'Type to search location',
                        onLocationSelected: (LocationData? location) {
                          setState(() {
                            selectedLocation = location;
                          });
                          
                          if (location != null) {
                            print('Address: ${location.address}');
                            print('Latitude: ${location.latitude}');
                            print('Longitude: ${location.longitude}');
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a location';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Show selected location details
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
                             //   Text('Coordinates: ${selectedLocation!.latitude.toStringAsFixed(6)}, ${selectedLocation!.longitude.toStringAsFixed(6)}'),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      /// Picture Upload Section
                      PictureUploadSection(
                        title: 'Pet Photo',
                        buttonText: 'Add Pet Photo',
                        onImageSelected: (File? image) {
                          setState(() {
                            selectedPetImage = image;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Additional Details Field (User Input)
                      TextFormField(
                        controller: _additionalDetailsController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Details',
                          hintText: 'Any other information that might help...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return 'Please provide additional details';
                        //   }
                        //   return null;
                        // },
                      ),
                      const SizedBox(height: 30),

                      /// Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting 
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
                                  SizedBox(width: 10),
                                  Text('Submitting...', style: TextStyle(fontSize: 16)),
                                ],
                              )
                            : const Text('Submit Report', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? imageUrl;
      
      // Upload image if selected
      if (selectedPetImage != null) {
        imageUrl = await _petReportService.uploadImage(
          selectedPetImage!,
          '${widget.petName}_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      // Submit the report
      final success = await _petReportService.submitPetReport(
        petName: widget.petName,
        petType: 'cat',
        reportType: 'lost',
        age: _ageController.text,
        dateLost: lostDate,
        petTypeCategory: _petTypeController.text,
        gender: _genderController.text,
        breed: _breedController.text,
        sterilized: _sterilizedController.text,
        earNotched: _earNotchedController.text,
        collar: _collarController.text,
        injured: _injuredController.text,
        friendly: _friendlyController.text,
        color: _colorController.text,
        locationAddress: _locationController.text,
        latitude: selectedLocation?.latitude,
        longitude: selectedLocation?.longitude,
        additionalDetails: _additionalDetailsController.text,
        imageUrl: imageUrl,
        userId: widget.userId,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.petName} report submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        throw Exception('Failed to submit report');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _breedController.dispose();
    _colorController.dispose();
    _ageController.dispose();
    _petTypeController.dispose();
    _genderController.dispose();
    _sterilizedController.dispose();
    _earNotchedController.dispose();
    _collarController.dispose();
    _injuredController.dispose();
    _friendlyController.dispose();
    _locationController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }
}