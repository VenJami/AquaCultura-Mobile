import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final TextEditingController _memberIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _offset = 0.0;
  double _formOffset = 0.0;
  bool _isKeyboardVisible = false;
  bool _showPassword = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Add listeners to the text controllers for real-time validation
    _memberIdController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _memberIdController.removeListener(_validateEmail);
    _passwordController.removeListener(_validatePassword);
    _memberIdController.dispose();
    _passwordController.dispose();
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF01579B), // Fallback color matching the image
                image: DecorationImage(
                  image: AssetImage("assets/bg.png"),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),

          // Logo and Title
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _isKeyboardVisible ? -50 : 30,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset("assets/logo.png", height: 90),
                const SizedBox(height: 5),
                const Text(
                  'AquaCultura',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text('Email',
                            style: TextStyle(color: Colors.white)),
                        _buildInputField(_memberIdController, "Enter Email"),
                        const SizedBox(height: 20),
                        const Text('Password',
                            style: TextStyle(color: Colors.white)),
                        _buildInputField(_passwordController, "Enter Password",
                            isPassword: true),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                            child: const Text(
                              'Forgot Password?',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  onPressed: authProvider.isLoading ? null : _login,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 43, 108, 168),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                              color: Color.fromARGB(255, 43, 108, 168),
                              fontWeight: FontWeight.bold),
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
      {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_showPassword,
          style: const TextStyle(color: Colors.white),
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
            hintText: hintText,
            hintStyle:
                const TextStyle(color: Color.fromARGB(255, 237, 237, 237)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.white, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.white, width: 2.0),
            ),
            filled: true,
            fillColor: Colors.transparent,
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: _toggleShowPassword,
                    icon: Image.asset(
                      _showPassword ? "assets/view.png" : "assets/eye.png",
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          // Silent validator - just validates without showing message
          validator: (value) {
            // Return empty string instead of error message
            // This makes the form validate but doesn't show a message
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
