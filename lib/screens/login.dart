import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:math' as math; // Import for math.sin and math.pi

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController _memberIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _offset = 0.0;
  double _formOffset = 0.0;
  bool _isKeyboardVisible = false;
  bool _showPassword = false;
  String? _emailError;
  String? _passwordError;

  // Animation controllers
  late AnimationController _waveEntryAnimationController;
  late Animation<double> _waveEntryAnimation;
  late AnimationController _loopingWaveAnimationController;
  late Animation<double> _loopingWaveAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _memberIdController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);

    // Initialize and start wave entry animation
    _waveEntryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _waveEntryAnimation = CurvedAnimation(
      parent: _waveEntryAnimationController,
      curve: Curves.easeOutCubic,
    );

    // Initialize looping wave animation
    _loopingWaveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Duration for one full wave cycle
    );
    _loopingWaveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_loopingWaveAnimationController);

    // Start entry animation, and once completed, start the looping animation
    _waveEntryAnimationController.forward();
    _waveEntryAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _loopingWaveAnimationController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _memberIdController.removeListener(_validateEmail);
    _passwordController.removeListener(_validatePassword);
    _memberIdController.dispose();
    _passwordController.dispose();
    _waveEntryAnimationController.dispose(); 
    _loopingWaveAnimationController.dispose(); // Dispose looping animation controller
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      if (_memberIdController.text.isEmpty) {
        _emailError = "Email cannot be empty";
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_memberIdController.text)) {
        _emailError = "Please enter a valid email";
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      if (_passwordController.text.isEmpty) {
        _passwordError = "Password cannot be empty";
      } else if (_passwordController.text.length < 6) {
        _passwordError = "Password must be at least 6 characters";
      } else {
        _passwordError = null;
      }
    });
  }

  void _toggleShowPassword() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  @override
  void didChangeMetrics() {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    setState(() {
      _isKeyboardVisible = keyboardOpen;
      _offset = keyboardOpen ? -120 : 0;
      _formOffset = keyboardOpen ? -150 : 0;
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Set loading state
      setState(() {
        // Show immediate feedback that the button was clicked
      });

      try {
        // Show error dialog regardless of server response for testing
        bool simulateError =
            false; // Set this to false when you want real login

        if (simulateError) {
          // Force show error dialog immediately
          await Future.delayed(
              const Duration(milliseconds: 500)); // Simulate network delay
          _showLoginErrorDialog();
          return;
        }

        final success = await authProvider.login(
          _memberIdController.text,
          _passwordController.text,
        );

        if (success) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Force show error dialog immediately after login fails
          if (!mounted) return;
          _showLoginErrorDialog();
        }
      } catch (e) {
        // Handle any exceptions
        if (!mounted) return;
        _showLoginErrorDialog();
      }
    } else {
      // If form validation fails, make sure to run our real-time validation
      // This ensures consistent error messages
      _validateEmail();
      _validatePassword();
    }
  }

  // Simpler error dialog method
  void _showLoginErrorDialog() {
    print("Showing error dialog"); // Debug print

    if (!mounted) return;

    // Use Navigator directly
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Login Failed", style: TextStyle(color: Colors.red)),
        content: const Text("Invalid username or password. Please try again."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    // final screenWidth = MediaQuery.of(context).size.width; // Not currently used, can be removed if not needed

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFF01579B), 
              child: AnimatedBuilder( 
                animation: Listenable.merge([_waveEntryAnimation, _loopingWaveAnimation]), // Listen to both
                builder: (context, child) {
                  return CustomPaint(
                    painter: _WaveBackgroundPainter(
                      entryAnimationValue: _waveEntryAnimation.value,
                      loopingAnimationValue: _loopingWaveAnimation.value,
                    ),
                    child: Container(), 
                  );
                },
              ),
            ),
          ),

          // Logo and Title
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _isKeyboardVisible ? screenHeight * 0.005 : screenHeight * 0.03, // Moved further up
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                Image.asset("assets/logos/hdlogo.png", height: 220),
                const SizedBox(height: 0), 
                Transform.translate(
                  offset: const Offset(0, -60.0), // Use Transform.translate for negative offset
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.blue[300]!, Colors.blue[800]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                    child: const Text(
                      'AquaCultura',
                      style: TextStyle(
                        fontSize: 48, // User updated font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white, 
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Login Form
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: MediaQuery.of(context).size.height * 0.45 + _formOffset,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Log In',
                            style: TextStyle(
                                fontSize: 28, // Slightly larger for modern feel
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 35), // Increased spacing
                        const Text('Email',
                            style: TextStyle(color: Colors.white70, fontSize: 16)), // Softer label
                        const SizedBox(height: 8),
                        _buildInputField(_memberIdController, "Enter Email", icon: Icons.email_outlined),
                        const SizedBox(height: 25), // Increased spacing
                        const Text('Password',
                            style: TextStyle(color: Colors.white70, fontSize: 16)), // Softer label
                        const SizedBox(height: 8),
                        _buildInputField(_passwordController, "Enter Password",
                            isPassword: true, icon: Icons.lock_outline),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40), // Increased spacing
                Padding( // Added padding for the button
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SizedBox( // To make button full width
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 18), // Taller button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0), // Consistent border radius
                        ),
                        // backgroundColor: Colors.transparent, // Handled by gradient below
                      ).copyWith(
                        elevation: MaterialStateProperty.all(0), // Flat button
                        backgroundColor: MaterialStateProperty.all(Colors.transparent), // For gradient
                        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.pressed)) {
                              return Colors.white.withOpacity(0.1);
                            }
                            return null; // Use the default overlay.
                          },
                        ),
                      ),
                      onPressed: authProvider.isLoading ? null : _login,
                      child: Ink( // Wrap child in Ink for gradient
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: authProvider.isLoading ? [Colors.grey, Colors.grey] : [Colors.blue[400]!, Colors.blue[700]!],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          constraints: const BoxConstraints(minHeight: 50.0), // Ensure consistent height
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  width: 24, // Adjusted size
                                  height: 24, // Adjusted size
                                  child: CircularProgressIndicator(
                                    color: Colors.white, // White indicator on blue button
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                      color: Colors.white, // White text on blue button
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Remove test button
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hintText,
      {bool isPassword = false, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_showPassword,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onTap: () {
            // Clear error message when the text field is tapped
            setState(() {
              if (isPassword) {
                _passwordError = null;
              } else {
                _emailError = null;
              }
            });
          },
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: Colors.white70, size: 20) : null, // Prefix icon
            hintText: hintText,
            hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16), // Softer hint
            filled: true,
            fillColor: Colors.white.withOpacity(0.15), // Light filled background
            border: OutlineInputBorder( // Modern border style
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none, // No visible border by default
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.blue[300]!, width: 1.5), // Subtle focus border
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), // Adjust padding
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: _toggleShowPassword,
                    icon: Icon( // Using Icon widget for consistency
                      _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                  )
                : null,
          ),
          validator: (value) {
            return value == null || value.isEmpty ? "" : null;
          },
        ),
        // Error message display - only from real-time validation
        if ((isPassword && _passwordError != null) ||
            (!isPassword && _emailError != null))
          Padding(
            padding: const EdgeInsets.only(top: 5.0, left: 5.0),
            child: Text(
              isPassword ? _passwordError! : _emailError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

// Custom Painter for Wave Background
class _WaveBackgroundPainter extends CustomPainter {
  final double entryAnimationValue; 
  final double loopingAnimationValue; // Value from 0.0 to 1.0, oscillating

  const _WaveBackgroundPainter({
    required this.entryAnimationValue,
    required this.loopingAnimationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double downwardShiftFactor = 0.035; 
    double waveStructureHeight = size.height * (0.45 + downwardShiftFactor); 
    final double slideInOffset = (1.0 - entryAnimationValue) * -waveStructureHeight;

    const double waveAmplitude = 7.0; // How much the waves move up/down
    // Calculate the looping wave offset using sine for smooth oscillation
    // loopingAnimationValue goes 0->1->0, so sin will produce one full cycle
    final double loopingOffsetY = math.sin(loopingAnimationValue * math.pi * 2) * waveAmplitude;

    // First wave (white, top)
    final paint1 = Paint()
      ..color = Colors.white 
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * (0.25 + downwardShiftFactor) + slideInOffset);
    path1.quadraticBezierTo(
        size.width * 0.15, 
        size.height * (0.35 + downwardShiftFactor) + slideInOffset + loopingOffsetY, // Apply looping wave to control point
        size.width * 0.4, 
        size.height * (0.30 + downwardShiftFactor) + slideInOffset);
    path1.quadraticBezierTo(
        size.width * 0.65, 
        size.height * (0.25 + downwardShiftFactor) + slideInOffset - loopingOffsetY, // Apply opposite looping to other control point for variety
        size.width * 0.85, 
        size.height * (0.35 + downwardShiftFactor) + slideInOffset);
    path1.quadraticBezierTo(
        size.width, size.height * (0.40 + downwardShiftFactor) + slideInOffset, 
        size.width, size.height * (0.40 + downwardShiftFactor) + slideInOffset);
    path1.lineTo(size.width, slideInOffset); 
    path1.lineTo(0, slideInOffset);      
    path1.close();

    // Second wave (medium blue, below first wave)
    final paint2 = Paint()
      ..color = const Color(0xFF0288D1) 
      ..style = PaintingStyle.fill;

    final path2_revised = Path();
    path2_revised.moveTo(0, size.height * (0.30 + downwardShiftFactor) + slideInOffset); 
    path2_revised.quadraticBezierTo(
        size.width * 0.20, 
        size.height * (0.42 + downwardShiftFactor) + slideInOffset - loopingOffsetY, // Apply looping wave (can be same or different phase)
        size.width * 0.45, 
        size.height * (0.37 + downwardShiftFactor) + slideInOffset);
    path2_revised.quadraticBezierTo(
        size.width * 0.70, 
        size.height * (0.32 + downwardShiftFactor) + slideInOffset + loopingOffsetY, // Apply looping wave
        size.width * 0.90, 
        size.height * (0.40 + downwardShiftFactor) + slideInOffset);
    path2_revised.quadraticBezierTo(
        size.width, size.height * (0.45 + downwardShiftFactor) + slideInOffset, 
        size.width, size.height * (0.45 + downwardShiftFactor) + slideInOffset);
    path2_revised.lineTo(size.width, slideInOffset); 
    path2_revised.lineTo(0, slideInOffset);      
    path2_revised.close();
    
    canvas.drawPath(path2_revised, paint2); 
    canvas.drawPath(path1, paint1); 
  }

  @override
  bool shouldRepaint(covariant _WaveBackgroundPainter oldDelegate) {
    return oldDelegate.entryAnimationValue != entryAnimationValue || 
           oldDelegate.loopingAnimationValue != loopingAnimationValue;
  }
}
