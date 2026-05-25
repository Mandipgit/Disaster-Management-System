import 'package:flutter/material.dart';
import 'package:disaster360/colors.dart';
import 'package:disaster360/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/providers/auth_provider.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _error = '';
  
  bool _isVerified = false;
  final TextEditingController _uuidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await _apiService.get('/admin/users');
      setState(() {
        // filter to show only admin and rescue roles
        _users = (response as List).where((u) => u['role'] == 'admin' || u['role'] == 'rescue').toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStatus(String userId, String role, bool currentStatus) async {
    try {
      final key = role == 'admin' ? 'is_admin' : 'is_rescueteam';
      await _apiService.put(
        '/admin/users/$userId/status',
        body: {key: !currentStatus},
      );
      // Refresh the list after update
      _fetchUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: ${e}'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVerified) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          title: const Text('Security Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.bgPrimary,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 64, color: AppColors.warning),
              const SizedBox(height: 24),
              const Text(
                'Administrative Access',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please enter your personal Admin UUID to access User Management.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _uuidController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter Admin UUID',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  prefixIcon: const Icon(Icons.key, color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: const TextStyle(color: Colors.white30),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final authProvider = context.read<AuthProvider>();
                    if (authProvider.user?.id == _uuidController.text.trim()) {
                      setState(() => _isVerified = true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid UUID! Authorization denied.'), backgroundColor: AppColors.danger),
                      );
                    }
                  },
                  child: const Text('Verify Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('User Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchUsers,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: AppColors.danger)))
              : _users.isEmpty
                  ? const Center(
                      child: Text(
                        'No admin or rescue team registrations found.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final isRoleAdmin = user['role'] == 'admin';
                        final isApproved = isRoleAdmin ? user['is_admin'] : user['is_rescueteam'];

                        return Card(
                          color: AppColors.bgSurface,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isRoleAdmin ? AppColors.info.withOpacity(0.2) : AppColors.warning.withOpacity(0.2),
                                  child: Icon(
                                    isRoleAdmin ? Icons.admin_panel_settings : Icons.health_and_safety,
                                    color: isRoleAdmin ? AppColors.info : AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['email'] ?? 'No Email',
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Role: ',
                                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            width: 8, height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isApproved ? AppColors.success : AppColors.danger,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isApproved ? 'Authorized' : 'Pending',
                                            style: TextStyle(
                                              color: isApproved ? AppColors.success : AppColors.danger,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _toggleStatus(user['id'], user['role'], isApproved),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isApproved ? AppColors.danger : AppColors.success,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: Text(isApproved ? 'Unauthorize' : 'Authorize'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
