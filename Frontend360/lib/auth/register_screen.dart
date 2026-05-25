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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join Disaster360 today',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
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
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.email, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                      if (!val.trim().contains(' ')) return 'Must include at least one space (e.g., First Last)';
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.person, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.phone, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    decoration: InputDecoration(
                      labelText: 'Citizenship Number',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.badge, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    validator: (val) => val == null ? 'Please select a district' : null,
                    dropdownColor: AppColors.bgSurface,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Citizenship Issue District',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.location_city,
                        color: Colors.white54,
                      ),
                    ),
                    items:
                        _districts.map((String value) {
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
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Citizenship Issue Date',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: AppColors.bgSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _selectedIssueDate == null ? 'Please select issue date' : null,
                        prefixIcon: const Icon(
                          Icons.calendar_today,
                          color: Colors.white54,
                        ),
                      ),
                      child: Text(
                        _selectedIssueDate == null
                            ? 'Select Date'
                            : '${_selectedIssueDate!.year}-${_selectedIssueDate!.month.toString().padLeft(2, '0')}-${_selectedIssueDate!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color:
                              _selectedIssueDate == null
                                  ? Colors.white54
                                  : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(color: Colors.white),
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: AppColors.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white54),
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
                    children:
                        _roles.map((role) {
                          final isSelected = _selectedRole == role;
                          return ChoiceChip(
                            label: Text(
                              role,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white54,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.orange,
                            backgroundColor: AppColors.bgSurface,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedRole = role);
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.white54),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
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
