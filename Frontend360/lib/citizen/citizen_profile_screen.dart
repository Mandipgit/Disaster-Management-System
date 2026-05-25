import 'package:provider/provider.dart';
import 'package:disaster360/providers/auth_provider.dart';
import 'package:disaster360/auth/auth_wrapper.dart';
import 'package:disaster360/main.dart';
import 'package:disaster360/services/feedback.dart';
import 'package:disaster360/colors.dart';
  import 'package:flutter/material.dart';

class CitizenProfileScreen extends StatefulWidget {
  const CitizenProfileScreen({super.key});

  @override
  State<CitizenProfileScreen> createState() => _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends State<CitizenProfileScreen> {
  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    var split = name.trim().split(' ');
    if (split.length > 1) {
      return '${split[0][0]}${split[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final _name = user?.fullName ?? 'Citizen User';
    final _initials = _getInitials(_name);
    final _role = user?.role ?? 'Citizen';
    final _citizenshipNo = user?.citizenshipNumber ?? 'N/A';
    final _email = user?.email ?? 'N/A';
    final _phone = user?.phone ?? 'N/A';
    final _issueDate = user?.citizenshipIssueDate ?? 'N/A';
    final _issueDistrict = user?.citizenshipIssueDistrict ?? 'N/A';
    final _reportsSubmitted = 0; // Or fetch from ReportProvider!

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      // ── No bottom navigation bar per project requirement ───────────────────
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(context),
              const SizedBox(height: 28),
              _buildAvatar(_initials),
              const SizedBox(height: 14),
              _buildNameAndRole(_name, _role),
              const SizedBox(height: 16),

              _buildInfoCard(
                _citizenshipNo,
                _email,
                _phone,
                _issueDate,
                _issueDistrict,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(context),
              const SizedBox(height: 28),
              _buildSignOut(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
          ),
        ),
        GestureDetector(
          onTap: () => _showEditDialog(context),
          child: const Text(
            'Edit',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────
  Widget _buildAvatar(String initials) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.orange,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ── Name + role badge ──────────────────────────────────────────────────────
  Widget _buildNameAndRole(String name, String role) {
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.info.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Text(
            role.toUpperCase(),
            style: const TextStyle(
              color: AppColors.info,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────────
  Widget _buildInfoCard(
    String citizenshipNo,
    String email,
    String phone,
    String issueDate,
    String issueDistrict,
  ) {
    final rows = [
      _InfoRow(label: 'Email', value: email),
      _InfoRow(label: 'Phone', value: phone),
      _InfoRow(label: 'Citizenship No.', value: citizenshipNo),
      _InfoRow(label: 'Issue Dist.', value: issueDistrict),
      _InfoRow(label: 'Issue Date (B.S.)', value: issueDate),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      row.label,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      row.value,
                      style: TextStyle(
                        color: row.valueColor ?? Colors.white,
                        fontSize: 13,
                        fontWeight:
                            row.valueColor != null
                                ? FontWeight.w700
                                : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                const Divider(height: 1, color: AppColors.border, indent: 16),
            ],
          );
        }),
      ),
    );
  }

  // ── Menu card (Feedback + Offline Support) ─────────────────────────────────
  Widget _buildMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Provide Feedback',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                ),
          ),
          const Divider(height: 1, color: AppColors.border, indent: 56),
],
      ),
    );
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Widget _buildSignOut(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // 👈 shows hand cursor
      child: GestureDetector(
        onTap: () => _showSignOutDialog(context),
        child: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.danger,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Edit profile dialog ────────────────────────────────────────────────────
  void _showEditDialog(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final nameCtrl = TextEditingController(text: user?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Edit Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(controller: nameCtrl, label: 'Full Name'),
                const SizedBox(height: 12),
                _DialogField(controller: phoneCtrl, label: 'Phone'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await context.read<AuthProvider>().updateProfile(
                      fullName: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully.'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  // ── Sign out confirmation dialog ───────────────────────────────────────────
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Text(
              'Are you sure you want to sign out?',
              style: TextStyle(color: Colors.white54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthProvider>().logout().then((_) {
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                        (route) => false,
                      );
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _InfoRow {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: Colors.white60, size: 20),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.white30,
        size: 20,
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _DialogField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: AppColors.bgPrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.orange),
        ),
      ),
    );
  }
}
