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

  // Check if user is already logged in
  Future<void> _checkExistingUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    // Also check Firebase auth state
    final currentUser = _auth.currentUser;
    
    if ((isLoggedIn || currentUser != null) && mounted) {
      // Get the stored user ID and pass it to home page
      final userId = prefs.getString('userId') ?? '';
      _navigateToHome(userId);
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

    // Proceed with OTP for new user registration
    await _sendOTP();
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

    // Check if we need name input for new users
    if (!_isExistingUser && _nameController.text.trim().isEmpty) {
      _showToast('Please enter your name');
      return;
    }

    setState(() {
      _isDummyLoading = true;
    });

    try {
      String? userId;
      String userName;

      if (_isExistingUser) {
        // Existing user - get their data
        userId = _existingUserId.isNotEmpty ? _existingUserId : await _updateUserInSupabase(_completePhoneNumber);
        userName = _existingUserName;
      } else {
        // New user - save their data
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
        await prefs.setString('userId', userId);
        await prefs.setBool('isLoggedIn', true);

        _showToast('Login successful!');

        // Navigate to home with user ID
        _navigateToHome(userId);
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
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _completePhoneNumber,
        verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
          // Auto-verification (happens on some Android devices)
          await _signInWithCredential(credential);
        },
        verificationFailed: (fb_auth.FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          _showToast('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
          _showToast('OTP sent successfully!');
          _startResendTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
      
    } on fb_auth.FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showToast('Error: ${e.message}');
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
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

      await _signInWithCredential(credential);
      
    } on fb_auth.FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showToast('Invalid OTP: ${e.message}');
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showToast('Verification failed');
    }
  }

  // Sign in with phone credential
  Future<void> _signInWithCredential(fb_auth.PhoneAuthCredential credential) async {
    try {
      fb_auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Save user data locally and to Supabase
        final userId = await _saveUserData(userCredential.user!);
        
        // Navigate to home page with user ID
        if (userId != null) {
          _navigateToHome(userId);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showToast('Sign in failed: $e');
    }
  }

  // Save user data to local storage and Supabase
  Future<String?> _saveUserData(fb_auth.User user) async {
    String? userId;
    String userName;

    if (_isExistingUser) {
      // Existing user - get their data
      userId = _existingUserId.isNotEmpty ? _existingUserId : await _updateUserInSupabase(_completePhoneNumber);
      userName = _existingUserName;
    } else {
      // New user - save their data
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
    }

    return userId; // Return the userId for navigation
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
          _verificationId = verificationId;
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
                  
                  const SizedBox(height: 30),
                  
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
                
                // Terms and conditions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
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