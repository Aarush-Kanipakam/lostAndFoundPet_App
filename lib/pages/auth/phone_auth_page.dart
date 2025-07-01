// lib/pages/auth/phone_auth_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({Key? key}) : super(key: key);

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _termsAccepted = false;
  String _completePhoneNumber = '';
  String _countryCode = '+91'; // Default to India
  bool _isLoading = false;
  bool _otpSent = false;
  bool _isResending = false;
  int _resendTimer = 0;
  bool _isDummyLoading = false;
  
  // New states for phone check flow
  bool _showNameInput = false; // Show name input for new users
  bool _isExistingUser = false; // Track if user already exists
  String _existingUserName = ''; // Store existing user's name
  String _existingUserId = ''; // Store existing user's ID
  
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  String _verificationId = '';

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
  Future<void> _showTermsDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms & Conditions'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pet Finder App - Terms of Service',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'By using this app, you agree to the following:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. PHONE NUMBER SHARING\n'
                  '• Your phone number will be visible to other users when you post about lost or found pets\n'
                  '• Other users may contact you directly via phone or Whatsapp regarding pet-related matters\n'
                  '• You consent to receiving calls/messages from pet owners or finders\n',
                ),
                const Text(
                  '2. PRIVACY & SAFETY\n'
                  '• Only share your phone number if you\'re comfortable being contacted\n'
                  '• We recommend meeting in public places when arranging pet exchanges\n'
                  '• Report any inappropriate contact to our support team\n',
                ),
                const Text(
                  '3. DATA USAGE\n'
                  '• Your name and phone number will be stored securely\n'
                  '• Information is used solely for pet-finding purposes\n'
                  '• You can delete your account and data at any time\n',
                ),
                const Text(
                  '4. USER RESPONSIBILITIES\n'
                  '• Provide accurate information about lost/found pets\n'
                  '• Use the app responsibly and ethically\n'
                  '• Respect other users\' privacy and safety\n',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: const Text(
                    '⚠️ IMPORTANT: By proceeding, you acknowledge that your phone number will be shared with other users for pet-related communication.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Read Again'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _termsAccepted = true;
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('I Agree'),
            ),
          ],
        );
      },
    );
  }
  // Check if user is already logged in
  Future<void> _checkExistingUser() async {
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  
  if (isLoggedIn && mounted) {
    // Get the stored user ID and pass it to home page
    final userId = prefs.getString('userId') ?? '';
    if (userId.isNotEmpty) {
      _navigateToHome(userId);
    }
  }
}

  // Check if phone number exists in database
  Future<Map<String, dynamic>?> _checkPhoneExists(String phone) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, name')
          .eq('phone', phone)
          .maybeSingle(); // Use maybeSingle() to avoid exception if no record found
      
      return response;
    } catch (error) {
      print('Error checking phone number: $error');
      _showToast('Error checking phone number: $error');
      return null;
    }
  }

  // Handle phone number submission
  Future<void> _handlePhoneSubmission() async {
    if (!_formKey.currentState!.validate()) return;
    
    // // Check if terms are accepted
    // if (!_termsAccepted) {
    //   _showToast('Please read and accept the Terms & Conditions first');
    //   return;
    // }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if phone number exists in database
      final userData = await _checkPhoneExists(_completePhoneNumber);
      
      if (userData != null) {
        // User exists - proceed with OTP for login
        setState(() {
          _isExistingUser = true;
          _existingUserName = userData['name'] ?? '';
          _existingUserId = userData['id'] ?? '';
          _showNameInput = false;
        });
        await _sendOTP();
      } else {
        // New user - show name input
        setState(() {
          _isExistingUser = false;
          _showNameInput = true;
          _isLoading = false;
        });
        _showToast('New user detected. Please enter your name.');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showToast('Error: $error');
    }
  }

  // Proceed with registration after name input
  Future<void> _proceedWithRegistration() async {
  if (_nameController.text.trim().isEmpty) {
    _showToast('Please enter your name');
    return;
  }

  if (_nameController.text.trim().length < 2) {
    _showToast('Name must be at least 2 characters');
    return;
  }

  // Check if terms are accepted for new users
  if (!_termsAccepted) {
    _showToast('Please read and accept the Terms & Conditions first');
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // DON'T save to Supabase yet - just send OTP
    // The user will be saved after successful OTP verification
    await _sendOTP();
  } catch (error) {
    setState(() {
      _isLoading = false;
    });
    _showToast('Error sending OTP: $error');
  }
}
  // Save user data to Supabase
  Future<String?> _saveUserToSupabase(String name, String phone) async {
    try {
      final response = await _supabase
          .from('users')
          .insert({
            'name': name,
            'phone': phone,
          })
          .select('id')
          .single();

      return response['id'] as String?;
    } catch (error) {
      print('Error saving user data to Supabase: $error');
      _showToast('Error saving user data: $error');
      return null;
    }
  }

  // Update existing user data in Supabase (if needed)
  Future<String?> _updateUserInSupabase(String phone) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, name')
          .eq('phone', phone)
          .single();

      return response['id'] as String?;
    } catch (error) {
      print('Error getting user data from Supabase: $error');
      _showToast('Error getting user data: $error');
      return null;
    }
  }

  // Navigate to home page with user ID
  void _navigateToHome(String userId) {
    if (mounted) {
      // Option 1: Pass as route arguments
      Navigator.pushReplacementNamed(
        context, 
        '/home',
        arguments: {'userId': userId},
      );
      
      // Option 2: If you prefer using a custom route
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => HomePage(userId: userId),
      //   ),
      // );
    }
  }

  // Dummy login function (for testing without OTP)
  Future<void> _dummyLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if terms are accepted
    if (!_termsAccepted) {
      _showToast('Please read and accept the Terms & Conditions first');
      return;
    }
    setState(() {
      _isDummyLoading = true;
    });

  try {
    String? userId;
    String userName;

    if (_isExistingUser) {
      // Existing user - use stored data
      userId = _existingUserId;
      userName = _existingUserName;
    } else {
      // New user - check if name is provided
      if (_nameController.text.trim().isEmpty) {
        _showToast('Please enter your name');
        setState(() {
          _isDummyLoading = false;
        });
        return;
      }
      
      // Save new user to Supabase
      userId = await _saveUserToSupabase(
        _nameController.text.trim(),
        _completePhoneNumber,
      );
      userName = _nameController.text.trim();
    }

    if (userId != null) {
      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', userName);
      await prefs.setString('userPhone', _completePhoneNumber);
      await prefs.setString('userId', userId);
      await prefs.setBool('isLoggedIn', true);

      _showToast('Login successful!');
      _navigateToHome(userId);
    } else {
      _showToast('Failed to create/login user');
    }
  } catch (error) {
    _showToast('Login failed: $error');
  } finally {
    setState(() {
      _isDummyLoading = false;
    });
  }
}

  // Send OTP to phone number
  Future<void> _sendOTP() async {
  // Validate phone number format before sending
  if (_completePhoneNumber.isEmpty || _completePhoneNumber.length < 10) {
    _showToast('Please enter a valid phone number');
    return;
  }

  setState(() {
    _isLoading = true;
  });

  print('Sending OTP to: $_completePhoneNumber'); // Debug print

  try {
    await _auth.verifyPhoneNumber(
      phoneNumber: _completePhoneNumber,
      verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
        print('Auto-verification completed'); // Debug print
        await _signInWithCredential(credential);
      },
      verificationFailed: (fb_auth.FirebaseAuthException e) {
        setState(() {
          _isLoading = false;
        });
        
        print('Verification failed: ${e.code} - ${e.message}'); // Debug print
        
        switch (e.code) {
          case 'invalid-phone-number':
            _showToast('Invalid phone number format');
            break;
          case 'too-many-requests':
            _showToast('Too many requests. Please try again later.');
            break;
          case 'quota-exceeded':
            _showToast('SMS quota exceeded. Please try again later.');
            break;
          default:
            _showToast('Verification failed: ${e.message}');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        print('OTP sent successfully. VerificationId: $verificationId'); // Debug print
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _isLoading = false;
        });
        _showToast('OTP sent successfully!');
        _startResendTimer();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('Auto-retrieval timeout. VerificationId: $verificationId'); // Debug print
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
    
  } on fb_auth.FirebaseAuthException catch (e) {
    setState(() {
      _isLoading = false;
    });
    print('Firebase exception in _sendOTP: ${e.code} - ${e.message}'); // Debug print
    _showToast('Error: ${e.message}');
  } catch (error) {
    setState(() {
      _isLoading = false;
    });
    print('General error in _sendOTP: $error'); // Debug print
    _showToast('An unexpected error occurred');
  }
}

  // Verify OTP
  Future<void> _verifyOTP() async {
  if (_otpController.text.trim().length != 6) {
    _showToast('Please enter a valid 6-digit OTP');
    return;
  }

  setState(() {
    _isLoading = true;
  });

try {
  // Create credential from verification ID and OTP
  fb_auth.PhoneAuthCredential credential = fb_auth.PhoneAuthProvider.credential(
    verificationId: _verificationId,
    smsCode: _otpController.text.trim(),
  );

  // FIXED: Use the workaround for the casting bug
  fb_auth.UserCredential? userCredential;
  try {
    userCredential = await _auth.signInWithCredential(credential);
  } catch (e) {
    // Check if this is the specific casting error
    if (e.toString().contains("is not a subtype of type 'PigeonUserDetails?'")) {
      // Get the current user after the credential was processed
      fb_auth.User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Create a mock UserCredential-like result
        print('OTP verification successful (workaround applied)');
        // Immediately sign out from Firebase since we only use it for OTP
        await _auth.signOut();
        // Handle Supabase operations
        await _handleSupabaseOperations();
        return;
      } else {
        throw Exception('OTP verification failed');
      }
    } else {
      // Re-throw other errors
      rethrow;
    }
  }
  
  // If we get here, normal flow worked
  if (userCredential?.user != null) {
    // Immediately sign out from Firebase since we only use it for OTP
    await _auth.signOut();
    // Handle Supabase operations
    await _handleSupabaseOperations();
  } else {
    throw Exception('OTP verification failed');
  }
  
} on fb_auth.FirebaseAuthException catch (e) {
  // ... rest of your existing Firebase exception handling remains the same
    setState(() {
      _isLoading = false;
    });
    
    print('Firebase Auth Error Code: ${e.code}');
    print('Firebase Auth Error Message: ${e.message}');
    
    switch (e.code) {
      case 'invalid-verification-code':
        _showToast('Invalid OTP. Please check and try again.');
        break;
      case 'session-expired':
        _showToast('OTP expired. Please request a new one.');
        _goBackToPhoneInput();
        break;
      case 'invalid-verification-id':
        _showToast('Invalid session. Please try again.');
        _goBackToPhoneInput();
        break;
      case 'credential-already-in-use':
        _showToast('This phone number is already in use.');
        break;
      default:
        _showToast('Verification failed: ${e.message}');
    }
  } catch (error) {
    setState(() {
      _isLoading = false;
    });
    print('General OTP verification error: $error');
    _showToast('Verification failed. Please try again.');
  }
}



  // Sign in with phone credential
  // Sign in with phone credential
// Sign in with phone credential
Future<void> _signInWithCredential(fb_auth.PhoneAuthCredential credential) async {
  try {
    print('Attempting to sign in with credential for OTP verification...');
    
    // FIXED: Apply workaround for casting bug
    fb_auth.UserCredential? userCredential;
    try {
      userCredential = await _auth.signInWithCredential(credential);
    } catch (e) {
      // Check if this is the specific casting error
      if (e.toString().contains("is not a subtype of type 'PigeonUserDetails?'")) {
        // Get the current user after the credential was processed
        fb_auth.User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('OTP verification successful (workaround applied)');
          // Immediately sign out from Firebase since we only use it for OTP
          await _auth.signOut();
          print('Signed out from Firebase after OTP verification');
          // Handle Supabase operations
          await _handleSupabaseOperations();
          return;
        } else {
          throw Exception('OTP verification failed');
        }
      } else {
        // Re-throw other errors
        rethrow;
      }
    }
    
    print('OTP verification successful');
    
    if (userCredential?.user != null) {
      // Immediately sign out from Firebase since we only use it for OTP
      await _auth.signOut();
      print('Signed out from Firebase after OTP verification');
      // Handle Supabase operations
      await _handleSupabaseOperations();
    } else {
      throw Exception('OTP verification failed');
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    print('OTP verification error: $e');
    _showToast('OTP verification failed: $e');
  }
}
Future<void> _handleSupabaseOperations() async {
  try {
    _showToast('Phone verification successful!');
    
    String? userId;
    String userName;

    if (_isExistingUser) {
      // Existing user - use stored data
      userId = _existingUserId;
      userName = _existingUserName;
    } else {
      // New user - create account in Supabase
      if (_nameController.text.trim().isEmpty) {
        _showToast('Name is required for new users');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      userId = await _saveUserToSupabase(
        _nameController.text.trim(),
        _completePhoneNumber,
      );
      userName = _nameController.text.trim();
    }

    if (userId != null) {
      // Save user data locally (no Firebase UID since we don't store Firebase sessions)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', userName);
      await prefs.setString('userPhone', _completePhoneNumber);
      await prefs.setString('userId', userId); // Only Supabase UUID
      await prefs.setBool('isLoggedIn', true);
      
      print('User data saved locally. Supabase UserId: $userId');
      
      // Navigate to home page
      _navigateToHome(userId);
    } else {
      _showToast('Failed to save user data');
      setState(() {
        _isLoading = false;
      });
    }
  } catch (error) {
    print('Error in _handleSupabaseOperations: $error');
    _showToast('Failed to complete registration: $error');
    setState(() {
      _isLoading = false;
    });
  }
}

Future<void> _saveUserDataLocally() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Use the data we already have
    final userName = _isExistingUser ? _existingUserName : _nameController.text.trim();
    
    await prefs.setString('userName', userName);
    await prefs.setString('userPhone', _completePhoneNumber);
    await prefs.setString('userId', _existingUserId); // Supabase UUID
    await prefs.setBool('isLoggedIn', true);
    
    print('User data saved locally. UserId: $_existingUserId'); // Debug print
  } catch (error) {
    print('Error saving user data locally: $error'); // Debug print
    _showToast('Failed to save user data: $error');
    throw error; // Re-throw to handle in calling function
  }
}

  // Save user data to local storage and Supabase
  Future<String?> _saveUserData(fb_auth.User user) async {
  try {
    String? userId;
    String userName;

    if (_isExistingUser) {
      // Existing user - get their data
      userId = _existingUserId.isNotEmpty ? _existingUserId : await _updateUserInSupabase(_completePhoneNumber);
      userName = _existingUserName;
    } else {
      // New user - save their data
      if (_nameController.text.trim().isEmpty) {
        _showToast('Name is required for new users');
        return null;
      }
      
      userId = await _saveUserToSupabase(
        _nameController.text.trim(),
        _completePhoneNumber,
      );
      userName = _nameController.text.trim();
    }

    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', userName);
      await prefs.setString('userPhone', _completePhoneNumber);
      await prefs.setString('userId', userId); // Supabase UUID  
      await prefs.setString('firebaseUserId', user.uid); // Firebase UID
      await prefs.setBool('isLoggedIn', true);
      
      print('User data saved successfully. UserId: $userId'); // Debug print
      return userId;
    } else {
      print('Failed to get userId from database operations'); // Debug print
      return null;
    }
  } catch (error) {
    print('Error in _saveUserData: $error'); // Debug print
    _showToast('Failed to save user data: $error');
    return null;
  }
}

  // Resend OTP
  Future<void> _resendOTP() async {
    if (_isResending || _resendTimer > 0) return;
    
    setState(() {
      _isResending = true;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _completePhoneNumber,
        verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (fb_auth.FirebaseAuthException e) {
          _showToast('Resend failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
          });
          _showToast('OTP resent successfully!');
          _startResendTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
         // _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
      
    } catch (error) {
      _showToast('Failed to resend OTP');
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  // Start resend timer
  void _startResendTimer() {
    setState(() {
      _resendTimer = 30;
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        return _resendTimer > 0;
      }
      return false;
    });
  }

  // Show toast message
  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  // Go back to phone input
void _goBackToPhoneInput() {
  setState(() {
    _otpSent = false;
    _showNameInput = false;
    _isExistingUser = false;
    _existingUserName = '';
    _existingUserId = '';
    _otpController.clear();
    _nameController.clear();
    _resendTimer = 0;
    _verificationId = '';
    _termsAccepted = false; // Reset terms acceptance
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_otpSent 
            ? 'Verify OTP' 
            : _showNameInput 
                ? 'Enter Your Name' 
                : 'Phone Verification'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom - 
                          kToolbarHeight - 48, // Account for AppBar and padding
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                const SizedBox(height: 40),
                
                // App Logo/Icon
                Container(
                  height: 100,
                  width: 100,
                  margin: const EdgeInsets.only(bottom: 40),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pets,
                    size: 50,
                    color: Colors.blue[600],
                  ),
                ),

                if (!_otpSent && !_showNameInput) ...[
                  // Welcome message
                  if (_isExistingUser && _existingUserName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.green[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Welcome back, $_existingUserName!',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Phone number input
                  IntlPhoneField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    initialCountryCode: 'IN',
                    onChanged: (phone) {
                      _completePhoneNumber = phone.completeNumber;
                      _countryCode = phone.countryCode;
                    },
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (phone.number.length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Continue button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handlePhoneSubmission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SpinKitThreeBounce(
                            color: Colors.white,
                            size: 20,
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Dummy Login Button (for testing without OTP)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Testing Mode',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: ElevatedButton(
                            onPressed: (_isDummyLoading || _isLoading) ? null : _dummyLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isDummyLoading
                                ? const SpinKitThreeBounce(
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : const Text(
                                    'Skip OTP & Login (Test)',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (!_otpSent && _showNameInput) ...[
                  // New user message
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_add, color: Colors.blue[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'New User Registration',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Phone: $_completePhoneNumber',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Name input
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Terms and conditions for new users
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _termsAccepted,
                              onChanged: (bool? value) {
                                if (value == true) {
                                  _showTermsDialog();
                                } else {
                                  setState(() {
                                    _termsAccepted = false;
                                  });
                                }
                              },
                              activeColor: Colors.blue[600],
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showTermsDialog(),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    children: [
                                      const TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: TextStyle(
                                          color: Colors.blue[600],
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      const TextSpan(text: ' including phone number sharing for pet-related communication'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!_termsAccepted)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Text(
                              '⚠️ Your phone number will be visible to other users',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Proceed with registration button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _proceedWithRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SpinKitThreeBounce(
                            color: Colors.white,
                            size: 20,
                          )
                        : const Text(
                            'Send OTP',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Back button
                  TextButton(
                    onPressed: _goBackToPhoneInput,
                    child: Text(
                      'Change Phone Number',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ] else ...[
                  // OTP sent message
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sms, color: Colors.blue[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isExistingUser ? 'Welcome back!' : 'Almost there!',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'OTP sent to $_completePhoneNumber',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // OTP input
                  TextFormField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      labelText: 'Enter 6-digit OTP',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Resend OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Didn't receive OTP? "),
                      if (_resendTimer > 0)
                        Text(
                          'Resend in ${_resendTimer}s',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      else
                        GestureDetector(
                          onTap: _isResending ? null : _resendOTP,
                          child: Text(
                            _isResending ? 'Sending...' : 'Resend OTP',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Verify OTP button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SpinKitThreeBounce(
                            color: Colors.white,
                            size: 20,
                          )
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Back button
                  TextButton(
                    onPressed: _goBackToPhoneInput,
                    child: Text(
                      'Change Phone Number',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
                
                const Spacer(),
                
                
              ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

