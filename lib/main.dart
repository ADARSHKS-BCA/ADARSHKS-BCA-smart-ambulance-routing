import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Ambulance System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A3D5C),
          primary: const Color(0xFFE63946),
          secondary: const Color(0xFF0A3D5C),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.dmSansTextTheme(),
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isSignUp = true;

  // Controllers for Sign Up
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _ageController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  // Controllers for Sign In
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  // Visibility states
  bool _obscureSignUpPassword = true;
  bool _obscureSignUpConfirmPassword = true;
  bool _obscureSignInPassword = true;

  // Submission triggers (to show error states)
  bool _signUpSubmitted = false;
  bool _signInSubmitted = false;

  // Toast status
  String? _toastMessage;
  Color _toastColor = Colors.green;
  IconData _toastIcon = Icons.check_circle;
  bool _showToast = false;
  Timer? _toastTimer;

  // ECG Animation Controller
  late AnimationController _ecgController;

  @override
  void initState() {
    super.initState();
    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Listeners for real-time validation on typing
    _signUpPasswordController.addListener(_onSignUpFieldsChanged);
    _signUpConfirmPasswordController.addListener(_onSignUpFieldsChanged);
    _firstNameController.addListener(_onSignUpFieldsChanged);
    _surnameController.addListener(_onSignUpFieldsChanged);
    _ageController.addListener(_onSignUpFieldsChanged);

    _signInEmailController.addListener(_onSignInFieldsChanged);
    _signInPasswordController.addListener(_onSignInFieldsChanged);
  }

  @override
  void dispose() {
    _ecgController.dispose();
    _firstNameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _onSignUpFieldsChanged() {
    if (_signUpSubmitted) {
      setState(() {});
    } else {
      // Force repaint of strength meter / match indicator instantly without general submission error highlights
      setState(() {});
    }
  }

  void _onSignInFieldsChanged() {
    if (_signInSubmitted) {
      setState(() {});
    }
  }

  // Toast Helper
  void _triggerToast(String message, Color color, IconData icon) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastColor = color;
      _toastIcon = icon;
      _showToast = true;
    });

    _toastTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showToast = false;
      });
    });
  }

  // Navigation helpers
  void _switchToSignIn() {
    setState(() {
      _isSignUp = false;
      _signUpSubmitted = false;
    });
  }

  void _switchToSignUp() {
    setState(() {
      _isSignUp = true;
      _signInSubmitted = false;
    });
  }

  // Password Strength Evaluation
  int _evaluatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;

    // Rule 1: Length check
    if (password.length >= 6) {
      score++;
    }
    // Rule 2: Contains Uppercase
    if (password.contains(RegExp(r'[A-Z]'))) {
      score++;
    }
    // Rule 3: Contains Number
    if (password.contains(RegExp(r'[0-9]'))) {
      score++;
    }
    // Rule 4: Contains Special Character
    if (password.contains(RegExp(r'[!@#\$&*~%^()_+=\[{\]};:<>,-/?]'))) {
      score++;
    }

    return score; // returns 0 to 4
  }

  String _getStrengthLabel(int score) {
    if (score == 0) return '';
    if (score == 1) return 'Weak';
    if (score == 2) return 'Fair';
    if (score == 3) return 'Good';
    return 'Strong';
  }

  Color _getStrengthColor(int score) {
    if (score == 1) return const Color(0xFFE74C3C); // Red
    if (score == 2) return const Color(0xFFE67E22); // Orange
    if (score == 3) return const Color(0xFFF1C40F); // Yellow
    if (score == 4) return const Color(0xFF2ECC71); // Green
    return Colors.transparent;
  }

  bool _isPasswordAtLeastMedium(String password) {
    // Rule: uppercase + numbers or symbols
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasSymbol = password.contains(RegExp(r'[!@#\$&*~%^()_+=\[{\]};:<>,-/?]'));
    
    return password.length >= 6 && hasUppercase && (hasNumber || hasSymbol);
  }

  // Validation Checkers (Field specific)
  String? _validateFirstName(String val) {
    if (val.trim().isEmpty) return 'First name is required';
    return null;
  }

  String? _validateSurname(String val) {
    if (val.trim().isEmpty) return 'Surname is required';
    return null;
  }

  String? _validateAge(String val) {
    if (val.trim().isEmpty) return 'Age is required';
    final parsed = int.tryParse(val.trim());
    if (parsed == null || parsed < 1 || parsed > 120) {
      return 'Age must be between 1 and 120';
    }
    return null;
  }

  String? _validateSignUpPassword(String val) {
    if (val.isEmpty) return 'Password is required';
    if (!_isPasswordAtLeastMedium(val)) {
      return 'Must contain uppercase and a number or symbol';
    }
    return null;
  }

  String? _validateSignUpConfirmPassword(String val, String originalPassword) {
    if (val.isEmpty) return 'Confirm password is required';
    if (val != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateSignInEmail(String val) {
    if (val.trim().isEmpty) return 'Email or username is required';
    return null;
  }

  String? _validateSignInPassword(String val) {
    if (val.isEmpty) return 'Password is required';
    return null;
  }

  // Form Submissions
  void _submitSignUp() {
    setState(() {
      _signUpSubmitted = true;
    });

    final isFirstNameValid = _validateFirstName(_firstNameController.text) == null;
    final isSurnameValid = _validateSurname(_surnameController.text) == null;
    final isAgeValid = _validateAge(_ageController.text) == null;
    final isPasswordValid = _validateSignUpPassword(_signUpPasswordController.text) == null;
    final isConfirmPasswordValid = _validateSignUpConfirmPassword(
      _signUpConfirmPasswordController.text,
      _signUpPasswordController.text,
    ) == null;

    if (isFirstNameValid && isSurnameValid && isAgeValid && isPasswordValid && isConfirmPasswordValid) {
      // Show Success Toast
      _triggerToast(
        'Account created successfully! Redirecting...',
        const Color(0xFF2ECC71),
        Icons.check_circle_outline,
      );

      // Auto-redirect to Sign In screen after 2 seconds
      Timer(const Duration(seconds: 2), () {
        setState(() {
          _isSignUp = false;
          _signUpSubmitted = false;
          _firstNameController.clear();
          _surnameController.clear();
          _ageController.clear();
          _signUpPasswordController.clear();
          _signUpConfirmPasswordController.clear();
        });
      });
    } else {
      _triggerToast(
        'Please correct the errors in the form.',
        const Color(0xFFE74C3C),
        Icons.error_outline,
      );
    }
  }

  void _submitSignIn() {
    setState(() {
      _signInSubmitted = true;
    });

    final isEmailValid = _validateSignInEmail(_signInEmailController.text) == null;
    final isPasswordValid = _validateSignInPassword(_signInPasswordController.text) == null;

    if (isEmailValid && isPasswordValid) {
      _triggerToast(
        'Signed in successfully! Welcome back.',
        const Color(0xFF3498DB),
        Icons.info_outline,
      );
    } else {
      _triggerToast(
        'Please enter your credentials.',
        const Color(0xFFE74C3C),
        Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Stack(
        children: [
          // Background design elements (subtle clinical styling)
          Positioned.fill(
            child: GridPaper(
              color: Colors.blue.withOpacity(0.015),
              divisions: 1,
              subdivisions: 1,
              interval: 100,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  width: 480,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A3D5C).withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dark Navy Header Component
                      _buildHeader(),
                      
                      // Animated cross-fade between views
                      Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: AnimatedCrossFade(
                          firstChild: _buildSignUpForm(),
                          secondChild: _buildSignInForm(),
                          crossFadeState: _isSignUp ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 350),
                          firstCurve: Curves.easeIn,
                          secondCurve: Curves.easeIn,
                          sizeCurve: Curves.easeInOut,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Toast Message Banner (Overlay)
          if (_showToast)
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 250),
                  builder: (context, val, child) {
                    return Opacity(
                      opacity: val,
                      child: Transform.translate(
                        offset: Offset(0, -10 * (1 - val)),
                        child: child,
                      ),
                    );
                  },
                  child: Material(
                    elevation: 10,
                    borderRadius: BorderRadius.circular(12),
                    color: _toastColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_toastIcon, color: Colors.white),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _toastMessage ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
        ],
      ),
    );
  }

  // Dark Navy Header Component
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0A3D5C),
      padding: const EdgeInsets.symmetric(vertical: 28.0),
      child: Column(
        children: [
          // Medical cross icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE63946), // Emergency Red background
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE63946).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          // Heading Text (Space Grotesk style)
          Text(
            'Smart Ambulance System',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          // Subtitle Text (Space Grotesk style)
          Text(
            'PATIENT & STAFF REGISTRATION',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFFB0C4DE),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // ECG Waveform Pulse line
          SizedBox(
            height: 32,
            width: double.infinity,
            child: CustomPaint(
              painter: ECGPainter(animationValue: _ecgController.value),
            ),
          ),
        ],
      ),
    );
  }

  // --- Sign Up Form ---
  Widget _buildSignUpForm() {
    final score = _evaluatePasswordStrength(_signUpPasswordController.text);
    final strengthLabel = _getStrengthLabel(score);
    final strengthColor = _getStrengthColor(score);
    final confirmMatches = _signUpConfirmPasswordController.text.isNotEmpty &&
        _signUpConfirmPasswordController.text == _signUpPasswordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Continue with Google Button
        _buildGoogleButton(
          text: 'Continue with Google',
          onTap: () {
            // Emulate redirection to Sign In
            _switchToSignIn();
            _triggerToast('Redirected from Google auth flow to credentials page.', const Color(0xFF3498DB), Icons.swap_horiz);
          },
        ),
        const SizedBox(height: 20),

        // Divider
        _buildDivider('or fill in manually'),
        const SizedBox(height: 20),

        // First Name & Surname fields side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _firstNameController,
                labelText: 'FIRST NAME',
                placeholder: 'John',
                keyboardType: TextInputType.name,
                validator: _validateFirstName,
                submitted: _signUpSubmitted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTextField(
                controller: _surnameController,
                labelText: 'SURNAME',
                placeholder: 'Doe',
                keyboardType: TextInputType.name,
                validator: _validateSurname,
                submitted: _signUpSubmitted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Age Field
        _buildTextField(
          controller: _ageController,
          labelText: 'AGE',
          placeholder: 'e.g. 30',
          keyboardType: TextInputType.number,
          validator: _validateAge,
          submitted: _signUpSubmitted,
        ),
        const SizedBox(height: 20),

        // Divider
        _buildDivider('secure credentials'),
        const SizedBox(height: 20),

        // Password Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _signUpPasswordController,
              labelText: 'PASSWORD',
              placeholder: 'Create a password',
              obscureText: _obscureSignUpPassword,
              submitted: _signUpSubmitted,
              validator: _validateSignUpPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignUpPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: const Color(0xFF0A3D5C).withOpacity(0.6),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureSignUpPassword = !_obscureSignUpPassword;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),

            // Password strength visual indicators
            if (_signUpPasswordController.text.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    'Strength: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF0A3D5C).withOpacity(0.6),
                    ),
                  ),
                  Text(
                    strengthLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: strengthColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(4, (index) {
                  bool filled = index < score;
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 3.0,
                        right: index == 3 ? 0 : 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: filled ? strengthColor : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ]
          ],
        ),

        // Confirm Password Field
        _buildTextField(
          controller: _signUpConfirmPasswordController,
          labelText: 'CONFIRM PASSWORD',
          placeholder: 'Re-enter password',
          obscureText: _obscureSignUpConfirmPassword,
          submitted: _signUpSubmitted,
          validator: (val) => _validateSignUpConfirmPassword(val, _signUpPasswordController.text),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureSignUpConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: const Color(0xFF0A3D5C).withOpacity(0.6),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscureSignUpConfirmPassword = !_obscureSignUpConfirmPassword;
              });
            },
          ),
          forceSuccessIcon: confirmMatches,
        ),
        const SizedBox(height: 28),

        // Create Account Button (Emergency Red)
        _buildPrimaryButton(
          text: 'Create account',
          icon: Icons.person_add_alt_1_outlined,
          onTap: _submitSignUp,
        ),
        const SizedBox(height: 18),

        // Navigate to Sign In Link
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Already registered? ',
                style: TextStyle(
                  color: const Color(0xFF0A3D5C).withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: _switchToSignIn,
                child: Text(
                  'Sign in here',
                  style: TextStyle(
                    color: const Color(0xFFE63946),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFFE63946).withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Sign In Form ---
  Widget _buildSignInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sign In with Google Button
        _buildGoogleButton(
          text: 'Sign in with Google',
          onTap: () {
            _triggerToast(
              'Signed in successfully via Google!',
              const Color(0xFF3498DB),
              Icons.check_circle_outline,
            );
          },
        ),
        const SizedBox(height: 20),

        // Divider
        _buildDivider('or use your credentials'),
        const SizedBox(height: 20),

        // Email / Username
        _buildTextField(
          controller: _signInEmailController,
          labelText: 'EMAIL OR USERNAME',
          placeholder: 'yourname@hospital.com',
          keyboardType: TextInputType.emailAddress,
          validator: _validateSignInEmail,
          submitted: _signInSubmitted,
        ),
        const SizedBox(height: 16),

        // Password with visibility toggle
        _buildTextField(
          controller: _signInPasswordController,
          labelText: 'PASSWORD',
          placeholder: 'Enter password',
          obscureText: _obscureSignInPassword,
          submitted: _signInSubmitted,
          validator: _validateSignInPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureSignInPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: const Color(0xFF0A3D5C).withOpacity(0.6),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscureSignInPassword = !_obscureSignInPassword;
              });
            },
          ),
        ),
        const SizedBox(height: 12),

        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              _triggerToast('Reset password link has been sent to your email.', const Color(0xFF3498DB), Icons.mail_outline);
            },
            child: Text(
              'Forgot password?',
              style: TextStyle(
                color: const Color(0xFF0A3D5C).withOpacity(0.8),
                fontWeight: FontWeight.bold,
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF0A3D5C).withOpacity(0.3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Sign In Button (Emergency Red)
        _buildPrimaryButton(
          text: 'Sign in',
          icon: Icons.login_outlined,
          onTap: _submitSignIn,
        ),
        const SizedBox(height: 18),

        // Navigate to Sign Up Link
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'No account yet? ',
                style: TextStyle(
                  color: const Color(0xFF0A3D5C).withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: _switchToSignUp,
                child: Text(
                  'Register here',
                  style: TextStyle(
                    color: const Color(0xFFE63946),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFFE63946).withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- UI Reusable Component Builders ---

  // Divider Widget
  Widget _buildDivider(String text) {
    return Row(
      children: [
        Expanded(child: Divider(color: const Color(0xFF0A3D5C).withOpacity(0.12))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            text,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0A3D5C).withOpacity(0.4),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: const Color(0xFF0A3D5C).withOpacity(0.12))),
      ],
    );
  }

  // Google OAuth button
  Widget _buildGoogleButton({required String text, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF0A3D5C).withOpacity(0.15)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google Logo using Flutter Custom Drawing
              CustomPaint(
                size: const Size(20, 20),
                painter: GoogleLogoPainter(),
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF0A3D5C),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Clinical Primary Action Button (Emergency Red)
  Widget _buildPrimaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFE63946), // Emergency Red
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE63946).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Clinical Custom Text Form Field
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String placeholder,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String) validator,
    required bool submitted,
    Widget? suffixIcon,
    bool forceSuccessIcon = false,
  }) {
    final error = submitted ? validator(controller.text) : null;
    final isNotEmpty = controller.text.isNotEmpty;
    final isValid = isNotEmpty && validator(controller.text) == null;

    Color borderColor = const Color(0xFF0A3D5C).withOpacity(0.15);
    Color labelColor = const Color(0xFF0A3D5C).withOpacity(0.5);
    Widget? activeSuffix = suffixIcon;

    if (submitted) {
      if (error != null) {
        borderColor = const Color(0xFFE74C3C); // Red Error
        labelColor = const Color(0xFFE74C3C);
      } else if (isValid) {
        borderColor = const Color(0xFF2ECC71); // Green Success
        labelColor = const Color(0xFF2ECC71);
      }
    } else if (isValid || forceSuccessIcon) {
      // Dynamic inline indicator if desired
      borderColor = const Color(0xFF2ECC71);
      labelColor = const Color(0xFF2ECC71);
    }

    // Determine custom suffix status icon
    if (activeSuffix == null) {
      if (submitted && error != null) {
        activeSuffix = const Icon(Icons.cancel, color: Color(0xFFE74C3C), size: 20);
      } else if (isValid || forceSuccessIcon) {
        activeSuffix = const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 20);
      }
    } else {
      // If suffix icon exists (e.g. visibility toggle), and it is valid, place a checkmark next to it
      if (isValid || forceSuccessIcon) {
        activeSuffix = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 18),
            const SizedBox(width: 4),
            suffixIcon!,
          ],
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Text (Clinical Subtext style)
        Text(
          labelText,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: labelColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        // Input Container
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    style: const TextStyle(
                      color: Color(0xFF0A3D5C),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: TextStyle(
                        color: const Color(0xFF0A3D5C).withOpacity(0.35),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                  ),
                ),
                if (activeSuffix != null) activeSuffix,
              ],
            ),
          ),
        ),
        // Error message row
        if (error != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFE74C3C), size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: Color(0xFFE74C3C),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// --- Custom Painters for Graphical Elements ---

// Google G logo custom painter
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;

    // We can draw a stylized Google "G" logo using basic path curves
    // Red quadrant
    paint.color = const Color(0xFFEA4335);
    Path pathRed = Path()
      ..moveTo(cx, cy)
      ..relativeLineTo(-r * 0.7, -r * 0.7)
      ..arcToPoint(Offset(cx + r * 0.7, cy - r * 0.7), radius: Radius.circular(r), largeArc: false, clockwise: true)
      ..close();
    canvas.drawPath(pathRed, paint);

    // Yellow quadrant
    paint.color = const Color(0xFFFBBC05);
    Path pathYellow = Path()
      ..moveTo(cx, cy)
      ..relativeLineTo(-r * 0.7, -r * 0.7)
      ..arcToPoint(Offset(cx - r * 0.7, cy + r * 0.7), radius: Radius.circular(r), largeArc: false, clockwise: false)
      ..close();
    canvas.drawPath(pathYellow, paint);

    // Green quadrant
    paint.color = const Color(0xFF34A853);
    Path pathGreen = Path()
      ..moveTo(cx, cy)
      ..relativeLineTo(-r * 0.7, r * 0.7)
      ..arcToPoint(Offset(cx + r * 0.7, cy + r * 0.7), radius: Radius.circular(r), largeArc: false, clockwise: true)
      ..close();
    canvas.drawPath(pathGreen, paint);

    // Blue quadrant & horizontal bar
    paint.color = const Color(0xFF4285F4);
    Path pathBlue = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + r, cy)
      ..arcToPoint(Offset(cx + r * 0.7, cy - r * 0.7), radius: Radius.circular(r), largeArc: false, clockwise: false)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(pathBlue, paint);

    // White circle masking the center for the "G" shape
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.5, paint);

    // Blue horizontal arm insertion
    paint.color = const Color(0xFF4285F4);
    Rect arm = Rect.fromLTRB(cx, cy - r * 0.25, cx + r, cy + r * 0.25);
    canvas.drawRect(arm, paint);

    // Cutout of the G shape (white mask)
    paint.color = Colors.white;
    Path cut = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + r * 0.7, cy - r * 0.35)
      ..lineTo(cx + r, cy - r * 0.35)
      ..close();
    canvas.drawPath(cut, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ECG Animation custom painter representing active health heartbeat
class ECGPainter extends CustomPainter {
  final double animationValue;

  ECGPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = const Color(0xFFE63946) // Red ECG line
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint glowPaint = Paint()
      ..color = const Color(0xFFE63946).withOpacity(0.15)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double width = size.width;
    final double height = size.height;
    final double midY = height / 2;

    Path path = Path();
    path.moveTo(0, midY);

    // Grid details for the ECG:
    // P wave: small bump
    // Q wave: small downward spike
    // R wave: huge upward spike
    // S wave: downward spike
    // T wave: medium upward bump
    
    // Cycle the position of the heartbeats across the width
    double totalHorizontalOffset = animationValue * width;

    for (double x = 0; x < width; x += 1.0) {
      // Relative position in a repeating pulse period
      double relativeX = (x + totalHorizontalOffset) % 150.0;
      double y = midY;

      if (relativeX > 30 && relativeX <= 45) {
        // P Wave (small bump)
        double t = (relativeX - 30) / 15.0;
        y = midY - (4 * (1 - (2 * t - 1) * (2 * t - 1)));
      } else if (relativeX > 45 && relativeX <= 50) {
        // Flat baseline
        y = midY;
      } else if (relativeX > 50 && relativeX <= 53) {
        // Q Wave (short dip)
        double t = (relativeX - 50) / 3.0;
        y = midY + (t * 5);
      } else if (relativeX > 53 && relativeX <= 59) {
        // R Wave (tall spike)
        double t = (relativeX - 53) / 6.0;
        y = (midY + 5) - (t * 26);
      } else if (relativeX > 59 && relativeX <= 65) {
        // S Wave (deep dip)
        double t = (relativeX - 59) / 6.0;
        y = (midY - 21) + (t * 31);
      } else if (relativeX > 65 && relativeX <= 70) {
        // Return to baseline
        double t = (relativeX - 65) / 5.0;
        y = (midY + 10) - (t * 10);
      } else if (relativeX > 70 && relativeX <= 75) {
        y = midY;
      } else if (relativeX > 75 && relativeX <= 95) {
        // T Wave (medium bump)
        double t = (relativeX - 75) / 20.0;
        y = midY - (8 * (1 - (2 * t - 1) * (2 * t - 1)));
      }

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw grid background line for realism
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(width, midY), gridPaint);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant ECGPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
