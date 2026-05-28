import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/providers/auth_provider.dart';
import 'package:disaster360/colors.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _citizenshipNumberController = TextEditingController();

  String? _selectedDistrict;
  NepaliDateTime? _selectedIssueDate;

  String _selectedRole = 'Citizen';
  final List<String> _roles = ['Citizen', 'Admin', 'Rescue'];
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final List<String> _districts = [
    'Bhojpur', 'Dhankuta', 'Ilam', 'Jhapa', 'Khotang', 'Morang', 'Okhaldhunga', 'Panchthar', 'Sankhuwasabha', 'Solukhumbu', 'Sunsari', 'Taplejung', 'Terhathum', 'Udayapur', 'Bara', 'Parsa', 'Rautahat', 'Sarlahi', 'Dhanusha', 'Mahottari', 'Siraha', 'Saptari', 'Bhaktapur', 'Dhading', 'Kathmandu', 'Kavrepalanchok', 'Lalitpur', 'Nuwakot', 'Rasuwa', 'Sindhupalchok', 'Baglung', 'Gorkha', 'Kaski', 'Lamjung', 'Manang', 'Mustang', 'Myagdi', 'Parbat', 'Syangja', 'Tanahun', 'Arghakhanchi', 'Banke', 'Bardiya', 'Dang', 'Gulmi', 'Kapilvastu', 'Nawalparasi East', 'Nawalparasi West', 'Palpa', 'Pyuthan', 'Rolpa', 'Rukum East', 'Rukum West', 'Rupandehi', 'Dolpa', 'Humla', 'Jumla', 'Kalikot', 'Mugu', 'Dailekh', 'Jajarkot', 'Surkhet', 'Achham', 'Baitadi', 'Bajhang', 'Bajura', 'Dadeldhura', 'Darchula', 'Doti', 'Kailali', 'Kanchanpur',
  ];

  Future<void> _pickDate() async {
    final pickedDate = await showNepaliDatePicker(
      context: context,
      initialDate: NepaliDateTime.now(),
      firstDate: NepaliDateTime(2000),
      lastDate: NepaliDateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.orange,
              onPrimary: Colors.white,
              surface: AppColors.bgSurface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() => _selectedIssueDate = pickedDate);
      if (_citizenshipNumberController.text.isNotEmpty) {
        _formKey.currentState?.validate();
      }
    }
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDistrict == null || _selectedIssueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select district and issue date')));
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final citizenshipNumber = _citizenshipNumberController.text.trim();

    setState(() => _isLoading = true);

    try {
      final msg = await context.read<AuthProvider>().register(
        email,
        password,
        _selectedRole,
        fullName: fullName,
        phone: phone,
        citizenshipNumber: citizenshipNumber,
        citizenshipIssueDistrict: _selectedDistrict!,
        citizenshipIssueDate:
            '${_selectedIssueDate!.year}-${_selectedIssueDate!.month.toString().padLeft(2, '0')}-${_selectedIssueDate!.day.toString().padLeft(2, '0')}',
      );

      if (!mounted) return;
      
      await _showSuccessDialog();
      
      if (!mounted) return;
      // Navigate back to login screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Must contain at least 1 uppercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Must contain at least 1 number';
    if (!value.contains(RegExp(r'[!@#%^&*(),.?":{}|<>]'))) return 'Must contain at least 1 special character';
    return null;
  }

  InputDecoration _getInputDecoration({String? hintText, required IconData prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: AppColors.bgPrimary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1),
      ),
      prefixIcon: Icon(prefixIcon, color: Colors.white54),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Glowing Logo
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.orange.withOpacity(0.15),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Text(
                    'Disaster360',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Email is required';
                              final emailRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)+$");
                              if (!emailRegex.hasMatch(val)) return 'Enter a valid email address';
                              return null;
                            },
                            decoration: _getInputDecoration(
                              hintText: 'Email address',
                              prefixIcon: Icons.mail_outline,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Full Name Field
                          TextFormField(
                            controller: _fullNameController,
                            style: const TextStyle(color: Colors.white),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                            ],
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Full Name is required';
                              if (val.trim().length < 2) return 'Name must be at least 2 characters';
                              if (!val.startsWith(RegExp(r'[A-Z]'))) return 'Must start with a capital letter';
                              if (!val.trim().contains(' ')) return 'Must include at least one space';
                              return null;
                            },
                            decoration: _getInputDecoration(
                              hintText: 'Full Name',
                              prefixIcon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              NepalPhoneFormatter(),
                            ],
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Phone number is required';
                              if (!val.startsWith('+977-')) return 'Must start with +977-';
                              if (val.length != 15) return 'Invalid phone number length';
                              return null;
                            },
                            decoration: _getInputDecoration(
                              hintText: '+977-98XXXXXXXX',
                              prefixIcon: Icons.phone_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Citizenship Number Field
                          TextFormField(
                            controller: _citizenshipNumberController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              CitizenshipFormatter(),
                            ],
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Citizenship number is required';
                              if (val.length != 14) return 'Format must be xx-xx-xx-xxxxx';
                              if (_selectedIssueDate != null) {
                                final parts = val.split('-');
                                if (parts.length == 4) {
                                  final thirdSection = parts[2];
                                  final issueYear = _selectedIssueDate!.year.toString();
                                  final lastTwoDigits = issueYear.length >= 2 ? issueYear.substring(issueYear.length - 2) : issueYear;
                                  if (thirdSection != lastTwoDigits) {
                                    return 'Citizenship number invalid';
                                  }
                                }
                              }
                              return null;
                            },
                            decoration: _getInputDecoration(
                              hintText: 'Citizenship Number (xx-xx-xx-xxxxx)',
                              prefixIcon: Icons.badge_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // District Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedDistrict,
                            validator: (val) => val == null ? 'Please select a district' : null,
                            dropdownColor: AppColors.bgSurface,
                            style: const TextStyle(color: Colors.white),
                            iconEnabledColor: Colors.white54,
                            hint: const Text('Citizenship Issue District', style: TextStyle(color: Colors.white38)),
                            decoration: _getInputDecoration(
                              hintText: null,
                              prefixIcon: Icons.location_city_outlined,
                            ),
                            items: _districts.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedDistrict = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Issue Date Picker
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: _getInputDecoration(
                                hintText: 'Citizenship Issue Date',
                                prefixIcon: Icons.calendar_today_outlined,
                              ).copyWith(
                                errorText: _selectedIssueDate == null ? 'Please select issue date' : null,
                              ),
                              child: Text(
                                _selectedIssueDate == null
                                    ? 'Select Issue Date (B.S.)'
                                    : '${_selectedIssueDate!.year}-${_selectedIssueDate!.month.toString().padLeft(2, '0')}-${_selectedIssueDate!.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: _selectedIssueDate == null ? Colors.white38 : Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(color: Colors.white),
                            validator: _validatePassword,
                            decoration: _getInputDecoration(
                              hintText: 'Password',
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Role Selection
                          const Text(
                            'Select Role',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _roles.map((role) {
                              final isSelected = _selectedRole == role;
                              return ChoiceChip(
                                label: Text(
                                  role,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white54,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.orange,
                                backgroundColor: AppColors.bgPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.orange : Colors.transparent,
                                  )
                                ),
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedRole = role);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 32),
                          
                          // Submit Button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.orange.withOpacity(0.15),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : _handleRegister,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 20),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Footer Info
                
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(24),
          title: const Column(
            children: [
              Icon(Icons.mark_email_unread_outlined, size: 64, color: AppColors.success),
              SizedBox(height: 16),
              Text(
                'Verify Your Email',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const Text(
            "Check your email to verify it's you. We've sent a verification link to your inbox.",
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK, I will check!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

class NepalPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    
    if (text.isEmpty) return newValue;

    if (!text.startsWith('+977-')) {
      if (text.startsWith('+977')) {
        text = text.replaceFirst('+977', '+977-');
      } else if (text.startsWith('+')) {
        // user is typing +
      } else {
        text = '+977-' + text;
      }
    }
    
    if (text.length >= 5) {
      String prefix = text.substring(0, 5); // +977-
      String rest = text.substring(5).replaceAll(RegExp(r'[^0-9]'), '');
      if (rest.length > 10) rest = rest.substring(0, 10);
      text = prefix + rest;
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class CitizenshipFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 11) text = text.substring(0, 11);
    
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4 || i == 6) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }
    
    String finalString = buffer.toString();
    return TextEditingValue(
      text: finalString,
      selection: TextSelection.collapsed(offset: finalString.length),
    );
  }
}
