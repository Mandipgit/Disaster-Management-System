import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/providers/auth_provider.dart';
import 'package:disaster360/auth/auth_wrapper.dart';
import 'package:disaster360/colors.dart';
import 'package:disaster360/main.dart';
import 'package:disaster360/services/feedback.dart';
import 'package:disaster360/services/api_service.dart';
import 'package:disaster360/providers/report_provider.dart';


// ═══════════════════════════════════════════════════════════════════════════════
//  ADMIN PROFILE SCREEN — Disaster360
//  Enhanced:
//   • Responsive: Mobile (<600) / Tablet (600-1023) / Desktop (≥1024)
//   • Tablet/Desktop: two-column layout — avatar+info left, activity+actions right
//   • Bottom sheets replaced with Dialog on tablet/desktop
//   • Hover animations on all interactive elements (MouseRegion + AnimatedContainer)
//   • Page-level FadeTransition on navigation pushes
//   • Hand cursor on all clickable elements
//   • Zero overflow — all text uses Flexible/Expanded with overflow handling
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Breakpoint helpers ────────────────────────────────────────────────────────
class _BP {
  static bool isMobile(BuildContext c) => MediaQuery.of(c).size.width < 600;
  static bool isTablet(BuildContext c) =>
      MediaQuery.of(c).size.width >= 600 && MediaQuery.of(c).size.width < 1024;
  static bool isDesktop(BuildContext c) => MediaQuery.of(c).size.width >= 1024;
  static bool isWide(BuildContext c) => !isMobile(c);
  static double hPad(BuildContext c) {
    if (isDesktop(c)) return MediaQuery.of(c).size.width * 0.08;
    if (isTablet(c)) return 28;
    return 16;
  }
}

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _systemOnline = true;
  late TabController _tabController;

  int _alertsManaged = 0;
  int _reportsReviewed = 0;
  int _teamsDeployed = 0;
  int _zonesMonitored = 0;

  List<_AppUser> _admins = [];
  List<_AppUser> _citizens = [];
  List<_AppUser> _rescueTeams = [];

  final Map<int, int> _visibleCount = {0: 3, 1: 3, 2: 3};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAdminData();
    });
  }

  Future<void> _fetchAdminData() async {
    try {
      final userRes = await ApiService().get('/admin/users');
      if (userRes is List) {
        final List<_AppUser> parsedAdmins = [];
        final List<_AppUser> parsedCitizens = [];
        final List<_AppUser> parsedRescue = [];

        for (var u in userRes) {
          final role = (u['role'] ?? 'citizen').toString().toLowerCase();
          final appUser = _AppUser(
            id: u['id'].toString().length >= 8 ? u['id'].toString().substring(0, 8) : u['id'].toString(),
            name: u['full_name'] ?? 'Unknown',
            role: role.toUpperCase(),
            phone: u['phone']?.toString() ?? 'N/A',
            loginTime: 'Just now',
            citizenId: u['id'].toString().length >= 5 ? u['id'].toString().substring(0, 5) : u['id'].toString(),
            isOnline: true,
            district: 'N/A',
          );
          if (role == 'admin') {
            parsedAdmins.add(appUser);
          } else if (role == 'rescue') {
            parsedRescue.add(appUser);
          } else {
            parsedCitizens.add(appUser);
          }
        }
        setState(() {
          _admins = parsedAdmins;
          _citizens = parsedCitizens;
          _rescueTeams = parsedRescue;
        });
      }

      final reportProv = context.read<ReportProvider>();
      final reports = reportProv.reports;
      setState(() {
        _alertsManaged = reports.where((r) => r.status == 'Verified' || r.status == 'Resolved').length;
        _reportsReviewed = reports.where((r) => r.status != 'Pending').length;
        _teamsDeployed = reportProv.activeRescues.length;
        _zonesMonitored = reports.map((r) => r.title).toSet().length;
      });
    } catch (e) {
      debugPrint("Error fetching admin profile data: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final hPad = _BP.hPad(context);
    final isWide = _BP.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _BP.isDesktop(context) ? 1100 : double.infinity,
              ),
              child:
                  isWide
                      ? _buildWideLayout(context)
                      : _buildMobileLayout(context),
            ),
          ),
        ),
      ),
    );
  }

  // ── Wide layout (tablet + desktop): two-column ────────────────────────────
  Widget _buildWideLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left column: avatar, name, info, system, quick actions ──────
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _buildAvatarAndName(context),
                  const SizedBox(height: 20),
                  _buildStatsRow(context),
                  const SizedBox(height: 16),
                  _buildInfoCard(context),
                  const SizedBox(height: 16),
                  _buildSystemStatusCard(),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 16),
                  _buildMenuCard(context),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // ── Right column: user activity section ─────────────────────────
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildUserActivitySection(context),
                  const SizedBox(height: 28),
                  _buildSignOut(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Mobile layout: single column ──────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeader(context),
        const SizedBox(height: 28),
        _buildAvatarAndName(context),
        const SizedBox(height: 20),
        _buildStatsRow(context),
        const SizedBox(height: 20),
        _buildInfoCard(context),
        const SizedBox(height: 16),
        _buildSystemStatusCard(),
        const SizedBox(height: 16),
        _buildQuickActions(context),
        const SizedBox(height: 20),
        _buildUserActivitySection(context),
        const SizedBox(height: 16),
        _buildMenuCard(context),
        const SizedBox(height: 28),
        _buildSignOut(context),
        const SizedBox(height: 24),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  SECTION WIDGETS
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: _BP.isDesktop(context) ? 26 : 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
          ),
        ),
        _HoverTextButton(
          label: 'Edit',
          color: AppColors.orange,
          onTap: () => _showSnack('Edit profile coming soon', isSuccess: true),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    var split = name.trim().split(' ');
    if (split.length > 1) {
      return '${split[0][0]}${split[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildAvatarAndName(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.fullName ?? 'Admin User';
    final role = user?.role ?? 'Admin';
    final initials = _getInitials(name);

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.info,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.info.withOpacity(0.4),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgPrimary, width: 2),
                ),
                child: const Icon(Icons.shield, color: Colors.white, size: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
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
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            _roleBadge(role.toUpperCase(), AppColors.orange),
            _roleBadge(
              user?.citizenshipIssueDistrict ?? 'Jurisdiction N/A',
              AppColors.info,
            ),
          ],
        ),
      ],
    );
  }

  Widget _roleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final stats = [
      _StatItem(
        label: 'Alerts\nManaged',
        value: '$_alertsManaged',
        color: AppColors.danger,
      ),
      _StatItem(
        label: 'Reports\nReviewed',
        value: '$_reportsReviewed',
        color: AppColors.warning,
      ),
      _StatItem(
        label: 'Teams\nDeployed',
        value: '$_teamsDeployed',
        color: AppColors.success,
      ),
      _StatItem(
        label: 'Zones\nMonitored',
        value: '$_zonesMonitored',
        color: AppColors.info,
      ),
    ];

    return Row(
      children:
          stats.map((s) {
            return Expanded(child: _HoverStatCard(stat: s));
          }).toList(),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final rows = [
      _InfoRow(label: 'Employee ID', value: user?.citizenshipNumber ?? 'N/A'),
      _InfoRow(label: 'Department', value: 'Disaster Management Authority'),
      _InfoRow(label: 'Email', value: user?.email ?? 'N/A'),
      _InfoRow(label: 'Phone', value: user?.phone ?? 'N/A'),
      _InfoRow(
        label: 'Jurisdiction',
        value: user?.citizenshipIssueDistrict ?? 'N/A',
        valueColor: AppColors.info,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Text(
                      row.label,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        row.value,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          color: row.valueColor ?? Colors.white,
                          fontSize: 13,
                          fontWeight:
                              row.valueColor != null
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                        ),
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

  Widget _buildSystemStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color:
                          _systemOnline ? AppColors.success : AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      color:
                          _systemOnline ? AppColors.success : AppColors.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    child: Text(
                      _systemOnline ? 'System Online' : 'System Offline',
                    ),
                  ),
                ],
              ),
              Switch(
                value: _systemOnline,
                onChanged: (v) => setState(() => _systemOnline = v),
                activeColor: AppColors.success,
                inactiveThumbColor: AppColors.danger,
                inactiveTrackColor: AppColors.danger.withOpacity(0.3),
                activeTrackColor: AppColors.success.withOpacity(0.3),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),
          _infoRowPair('Last Sync', 'Mar 30, 2026 · 11:45 AM'),
          const SizedBox(height: 8),
          _infoRowPair('Server Region', 'Nepal — AP South'),
        ],
      ),
    );
  }

  Widget _infoRowPair(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('QUICK ACTIONS'),
        const SizedBox(height: 12),
        Row(
          children: [
            _HoverQuickAction(
              icon: Icons.campaign_outlined,
              label: 'Broadcast\nAlert',
              color: AppColors.danger,
              onTap: () => _showBroadcastDialog(context),
            ),
            const SizedBox(width: 10),
            _HoverQuickAction(
              icon: Icons.download_outlined,
              label: 'Export\nReport',
              color: AppColors.info,
              onTap: () => _showExportDialog(context),
            ),
            const SizedBox(width: 10),
            _HoverQuickAction(
              icon: Icons.manage_accounts_outlined,
              label: 'Manage\nUsers',
              color: AppColors.warning,
              onTap: () => _showManageUsers(context),
            ),
            const SizedBox(width: 10),
            _HoverQuickAction(
              icon: Icons.history_outlined,
              label: 'System\nLogs',
              color: AppColors.success,
              onTap: () => _showSystemLogs(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserActivitySection(BuildContext context) {
    final tabs = ['Admins', 'Citizens', 'Rescue'];
    final counts = [_admins.length, _citizens.length, _rescueTeams.length];
    final onlineCounts = [
      _admins.where((u) => u.isOnline).length,
      _citizens.where((u) => u.isOnline).length,
      _rescueTeams.where((u) => u.isOnline).length,
    ];
    final colors = [AppColors.orange, AppColors.info, AppColors.success];
    final data = [_admins, _citizens, _rescueTeams];
    final totalOnline = onlineCounts.reduce((a, b) => a + b);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const _SectionLabel('USER ACTIVITY'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$totalOnline online',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Count chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: colors[i].withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors[i].withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${counts[i]}',
                          style: TextStyle(
                            color: colors[i],
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          tabs[i],
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '${onlineCounts[i]} online',
                          style: TextStyle(
                            color: colors[i].withOpacity(0.7),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // TabBar
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.orange,
            indicatorWeight: 2.5,
            labelColor: AppColors.orange,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            dividerColor: AppColors.border,
            tabs: List.generate(
              3,
              (i) => Tab(text: '${tabs[i]} (${counts[i]})'),
            ),
          ),

          // Tab content — fixed height based on visible count
          SizedBox(
            height: _computeListHeight(),
            child: TabBarView(
              controller: _tabController,
              children: List.generate(3, (tabIdx) {
                final list = data[tabIdx];
                final visible = _visibleCount[tabIdx]!;
                final shown = list.sublist(0, visible.clamp(0, list.length));
                final hasMore = visible < list.length;

                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      ...shown.map(
                        (user) => _HoverUserTile(
                          user: user,
                          onTap: () => _showUserDetail(context, user),
                        ),
                      ),
                      if (hasMore)
                        _HoverTextButton(
                          label:
                              'View more (${list.length - visible} remaining)',
                          color: AppColors.orange,
                          fontSize: 12,
                          onTap:
                              () => setState(() {
                                _visibleCount[tabIdx] =
                                    (_visibleCount[tabIdx]! + 3).clamp(
                                      0,
                                      list.length,
                                    );
                              }),
                        )
                      else if (list.length > 3)
                        _HoverTextButton(
                          label: 'Show less',
                          color: Colors.white38,
                          fontSize: 12,
                          onTap:
                              () => setState(() => _visibleCount[tabIdx] = 3),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  double _computeListHeight() {
    final tabIdx = _tabController.index;
    final visible = _visibleCount[tabIdx]!;
    return (visible * 72.0) + 56.0;
  }

  Widget _buildMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _HoverMenuTile(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Provide Feedback',
            onTap: () => _showFeedbackPanel(context), // <-- call our new method
          ),

          const Divider(height: 1, color: AppColors.border, indent: 56),
          _HoverMenuTile(
            icon: Icons.security_outlined,
            label: 'Security Settings',
            onTap: () => _showSecurityPanel(context),
          ),
          const Divider(height: 1, color: AppColors.border, indent: 56),
          _HoverMenuTile(
            icon: Icons.notifications_outlined,
            label: 'Notification Preferences',
            onTap: () => _showNotificationPrefs(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOut(BuildContext context) {
    return _HoverTextButton(
      label: 'Sign Out',
      color: AppColors.danger,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      onTap: () => _showSignOutDialog(context),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  DIALOGS & PANELS
  //  Rule: Mobile → bottom sheet  |  Tablet/Desktop → Dialog
  // ════════════════════════════════════════════════════════════════════════════

  void _showPanel({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    double sheetSize = 0.6,
  }) {
    if (_BP.isWide(context)) {
      // ── Dialog for tablet/desktop ──────────────────────────────────────────
      showDialog(
        context: context,
        builder:
            (_) => Dialog(
              backgroundColor: AppColors.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          _HoverIconButton(
                            icon: Icons.close,
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 16),
                      Expanded(child: SingleChildScrollView(child: content)),
                      if (actions != null) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: actions,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
      );
    } else {
      // ── Bottom sheet for mobile ────────────────────────────────────────────
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder:
            (_) => DraggableScrollableSheet(
              initialChildSize: sheetSize,
              maxChildSize: 0.92,
              minChildSize: 0.3,
              builder:
                  (_, ctrl) => Container(
                    decoration: const BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: ctrl,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                content,
                                if (actions != null) ...[
                                  const SizedBox(height: 20),
                                  ...actions,
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
      );
    }
  }


  // ── Broadcast alert ────────────────────────────────────────────────────────
  void _showBroadcastDialog(BuildContext context) {
    String selectedZone = 'All Zones';
    final zones = [
      'All Zones',
      'Sunsari District',
      'Dharan',
      'Itahari',
      'Biratnagar',
      'Morang',
    ];
    final msgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLS) => AlertDialog(
                  backgroundColor: AppColors.bgSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: const [
                      Icon(
                        Icons.campaign_outlined,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Broadcast Alert',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Target Zone',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.bgPrimary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButton<String>(
                            value: selectedZone,
                            isExpanded: true,
                            dropdownColor: AppColors.bgSurface,
                            underline: const SizedBox(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            items:
                                zones
                                    .map(
                                      (z) => DropdownMenuItem(
                                        value: z,
                                        child: Text(z),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setLS(() => selectedZone = v!),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Message',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: msgCtrl,
                          maxLines: 3,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type your emergency broadcast...',
                            hintStyle: const TextStyle(
                              color: Colors.white24,
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: AppColors.bgPrimary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.danger,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                    _HoverElevatedButton(
                      label: 'Send Alert',
                      color: AppColors.danger,
                      onTap: () {
                        Navigator.pop(context);
                        _showSnack(
                          '🚨 Broadcast sent to $selectedZone',
                          isSuccess: false,
                        );
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  // ── Export report ──────────────────────────────────────────────────────────
  void _showExportDialog(BuildContext context) {
    String format = 'PDF';
    String range = 'Last 7 days';

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLS) => AlertDialog(
                  backgroundColor: AppColors.bgSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: const [
                      Icon(
                        Icons.download_outlined,
                        color: AppColors.info,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Export Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Format',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children:
                              ['PDF', 'CSV', 'Excel'].map((f) {
                                final sel = format == f;
                                return _HoverChip(
                                  label: f,
                                  selected: sel,
                                  color: AppColors.info,
                                  onTap: () => setLS(() => format = f),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Date Range',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children:
                              ['Last 7 days', 'Last 30 days', 'All time'].map((
                                r,
                              ) {
                                final sel = range == r;
                                return _HoverChip(
                                  label: r,
                                  selected: sel,
                                  color: AppColors.info,
                                  onTap: () => setLS(() => range = r),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                    _HoverElevatedButton(
                      label: 'Export',
                      color: AppColors.info,
                      onTap: () {
                        Navigator.pop(context);
                        _showSnack(
                          '✅ Exporting $format report ($range)…',
                          isSuccess: true,
                        );
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  // ── Manage users ───────────────────────────────────────────────────────────
  void _showManageUsers(BuildContext context) {
    final allUsers = [..._admins, ..._citizens, ..._rescueTeams];
    _showPanel(
      context: context,
      title: 'Manage Users',
      sheetSize: 0.75,
      content: Column(
        children:
            allUsers
                .map(
                  (u) => _HoverUserTile(
                    user: u,
                    onTap: () {
                      if (_BP.isWide(context)) Navigator.pop(context);
                      _showUserDetail(context, u);
                    },
                  ),
                )
                .toList(),
      ),
    );
  }

  // ── System logs ────────────────────────────────────────────────────────────
  void _showSystemLogs(BuildContext context) {
    final logs = [
      _LogEntry(
        time: '11:45 AM',
        event: 'System sync completed',
        level: 'INFO',
      ),
      _LogEntry(
        time: '11:30 AM',
        event: 'Report RPT-00421 verified by admin',
        level: 'INFO',
      ),
      _LogEntry(
        time: '10:55 AM',
        event: 'Broadcast sent to Sunsari District',
        level: 'WARN',
      ),
      _LogEntry(
        time: '10:20 AM',
        event: 'New user registered: CIT-009',
        level: 'INFO',
      ),
      _LogEntry(
        time: '09:47 AM',
        event: 'Team Alpha deployed to Ward 7',
        level: 'INFO',
      ),
      _LogEntry(
        time: '09:15 AM',
        event: 'Risk zone updated: Dharan Ward 7 → High',
        level: 'WARN',
      ),
      _LogEntry(
        time: '08:02 AM',
        event: 'Admin login: Rajesh Kumar',
        level: 'INFO',
      ),
      _LogEntry(
        time: 'Yesterday',
        event: 'System backup completed',
        level: 'INFO',
      ),
      _LogEntry(
        time: 'Yesterday',
        event: 'Failed login attempt detected',
        level: 'ERROR',
      ),
    ];

    _showPanel(
      context: context,
      title: 'System Logs',
      sheetSize: 0.65,
      content: Column(
        children:
            logs.map((log) {
              final lc =
                  log.level == 'ERROR'
                      ? AppColors.danger
                      : log.level == 'WARN'
                      ? AppColors.warning
                      : AppColors.success;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: lc.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.level,
                            style: TextStyle(
                              color: lc,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.event,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                log.time,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                ],
              );
            }).toList(),
      ),
    );
  }

  // ── User detail ────────────────────────────────────────────────────────────
  void _showUserDetail(BuildContext context, _AppUser user) {
    final rc =
        user.role == 'Admin'
            ? AppColors.orange
            : user.role == 'Rescue Team'
            ? AppColors.success
            : AppColors.info;

    _showPanel(
      context: context,
      title: 'User Details',
      sheetSize: 0.6,
      content: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: rc.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: rc.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    user.name
                        .split(' ')
                        .take(2)
                        .map((w) => w[0])
                        .join()
                        .toUpperCase(),
                    style: TextStyle(
                      color: rc,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: rc.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: rc.withOpacity(0.4)),
                          ),
                          child: Text(
                            user.role,
                            style: TextStyle(
                              color: rc,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                user.isOnline
                                    ? AppColors.success
                                    : Colors.white24,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color:
                                user.isOnline
                                    ? AppColors.success
                                    : Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          _detailRow(Icons.badge_outlined, 'User ID', user.id),
          _detailRow(
            Icons.credit_card_outlined,
            'Citizen/Staff ID',
            user.citizenId,
          ),
          _detailRow(Icons.phone_outlined, 'Phone', user.phone),
          _detailRow(Icons.location_on_outlined, 'District', user.district),
          _detailRow(Icons.access_time, 'Last Login', user.loginTime),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HoverOutlinedButton(
                  label: 'Message',
                  icon: Icons.message_outlined,
                  color: AppColors.info,
                  onTap: () {
                    Navigator.pop(context);
                    _showSnack('Message sent to ${user.name}', isSuccess: true);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HoverOutlinedButton(
                  label: 'Suspend',
                  icon: Icons.block_outlined,
                  color: AppColors.danger,
                  onTap: () {
                    Navigator.pop(context);
                    _showSnack(
                      '${user.name} has been suspended',
                      isSuccess: false,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 15),
          const SizedBox(width: 8),
          Text(
            '$label  ',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Security settings ──────────────────────────────────────────────────────
  void _showSecurityPanel(BuildContext context) {
    bool twoFa = true, loginAlerts = true;
    _showPanel(
      context: context,
      title: 'Security Settings',
      content: StatefulBuilder(
        builder:
            (_, setLS) => Column(
              children: [
                _switchRow(
                  'Two-Factor Authentication',
                  twoFa,
                  (v) => setLS(() => twoFa = v),
                ),
                const Divider(color: AppColors.border),
                _switchRow(
                  'Login Alerts',
                  loginAlerts,
                  (v) => setLS(() => loginAlerts = v),
                ),
                const Divider(color: AppColors.border),
                _HoverMenuTile(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnack('Password change email sent', isSuccess: true);
                  },
                ),
                const Divider(color: AppColors.border, indent: 56),
                _HoverMenuTile(
                  icon: Icons.devices_outlined,
                  label: 'Active Sessions  (2)',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnack(
                      'All other sessions terminated',
                      isSuccess: true,
                    );
                  },
                ),
              ],
            ),
      ),
    );
  }

  // ── Notification prefs ─────────────────────────────────────────────────────
  void _showNotificationPrefs(BuildContext context) {
    bool push = true, sms = true, email = false, proximity = true;
    _showPanel(
      context: context,
      title: 'Notification Preferences',
      content: StatefulBuilder(
        builder:
            (_, setLS) => Column(
              children: [
                _switchRow(
                  'Push Notifications',
                  push,
                  (v) => setLS(() => push = v),
                ),
                const Divider(color: AppColors.border),
                _switchRow('SMS Alerts', sms, (v) => setLS(() => sms = v)),
                const Divider(color: AppColors.border),
                _switchRow(
                  'Email Digest',
                  email,
                  (v) => setLS(() => email = v),
                ),
                const Divider(color: AppColors.border),
                _switchRow(
                  'Proximity Alerts',
                  proximity,
                  (v) => setLS(() => proximity = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _HoverElevatedButton(
                    label: 'Save Preferences',
                    color: AppColors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _showSnack(
                        'Notification preferences saved',
                        isSuccess: true,
                      );
                    },
                  ),
                ),
              ],
            ),
      ),
    );
  }

  // ── Feedback panel ──────────────────────────────────────────────────────
  void _showFeedbackPanel(BuildContext context) {
    if (_BP.isWide(context)) {
      // Tablet/Desktop: show as floating dialog
      _showPanel(
        context: context,
        title: 'Provide Feedback',
        sheetSize: 0.7,
        content: const FeedbackScreen(isInDialog: true), // <-- pass true
      );
    } else {
      // Mobile: push full screen
      Navigator.push(
        context,
        _fadeRoute(const FeedbackScreen()), // default isInDialog = false
      );
    }
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const Text(
              'Are you sure you want to sign out of your admin session?',
              style: TextStyle(color: Colors.white54, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              _HoverElevatedButton(
                label: 'Sign Out',
                color: AppColors.danger,
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.orange,
          inactiveTrackColor: Colors.white12,
        ),
      ],
    );
  }

  void _showSnack(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor:
            isSuccess
                ? AppColors.success.withOpacity(0.92)
                : AppColors.danger.withOpacity(0.92),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED / HOVER WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

/// Animated stat card with hover glow + number scale
class _HoverStatCard extends StatefulWidget {
  final _StatItem stat;
  const _HoverStatCard({required this.stat});

  @override
  State<_HoverStatCard> createState() => _HoverStatCardState();
}

class _HoverStatCardState extends State<_HoverStatCard> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _h ? widget.stat.color.withOpacity(0.4) : AppColors.border,
          ),
          boxShadow:
              _h
                  ? [
                    BoxShadow(
                      color: widget.stat.color.withOpacity(0.08),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                  : [],
        ),
        child: Column(
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: widget.stat.color,
                fontSize: _h ? 23 : 20,
                fontWeight: FontWeight.w800,
              ),
              child: Text(widget.stat.value),
            ),
            const SizedBox(height: 4),
            Text(
              widget.stat.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hover-animated quick action button
class _HoverQuickAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _HoverQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_HoverQuickAction> createState() => _HoverQuickActionState();
}

class _HoverQuickActionState extends State<_HoverQuickAction> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _h = true),
        onExit: (_) => setState(() => _h = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(_h ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.color.withOpacity(_h ? 0.5 : 0.25),
              ),
            ),
            child: Column(
              children: [
                AnimatedScale(
                  scale: _h ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 160),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: TextStyle(
                    color: widget.color,
                    fontSize: _h ? 9.5 : 9,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  child: Text(widget.label, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hover-animated menu tile (list item with chevron)
class _HoverMenuTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HoverMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_HoverMenuTile> createState() => _HoverMenuTileState();
}

class _HoverMenuTileState extends State<_HoverMenuTile> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        color: _h ? Colors.white.withOpacity(0.04) : Colors.transparent,
        child: ListTile(
          onTap: widget.onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          leading: Icon(
            widget.icon,
            color: _h ? Colors.white70 : Colors.white60,
            size: 20,
          ),
          title: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 160),
            style: TextStyle(
              color: Colors.white,
              fontSize: _h ? 14.5 : 14,
              fontWeight: FontWeight.w500,
            ),
            child: Text(widget.label),
          ),
          trailing: AnimatedScale(
            scale: _h ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Icon(
              Icons.chevron_right,
              color: _h ? Colors.white54 : Colors.white30,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hover-animated user tile
class _HoverUserTile extends StatefulWidget {
  final _AppUser user;
  final VoidCallback onTap;
  const _HoverUserTile({required this.user, required this.onTap});

  @override
  State<_HoverUserTile> createState() => _HoverUserTileState();
}

class _HoverUserTileState extends State<_HoverUserTile> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final roleUpper = widget.user.role.toUpperCase();
    final rc =
        roleUpper == 'ADMIN'
            ? AppColors.orange
            : roleUpper == 'RESCUE'
            ? AppColors.success
            : AppColors.info;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        color: _h ? Colors.white.withOpacity(0.04) : Colors.transparent,
        child: ListTile(
          onTap: widget.onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rc.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.user.name.trim().isEmpty 
                        ? 'U' 
                        : widget.user.name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase(),
                    style: TextStyle(
                      color: rc,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color:
                        widget.user.isOnline
                            ? AppColors.success
                            : Colors.white24,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bgSurface, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            widget.user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            widget.user.district,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.user.loginTime,
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
              const SizedBox(height: 2),
              AnimatedScale(
                scale: _h ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 140),
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.white24,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hover text button (e.g. Edit, Sign Out, View more)
class _HoverTextButton extends StatefulWidget {
  final String label;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final VoidCallback onTap;
  const _HoverTextButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w500,
  });

  @override
  State<_HoverTextButton> createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<_HoverTextButton> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            color: _h ? widget.color.withOpacity(0.75) : widget.color,
            fontSize: _h ? widget.fontSize * 1.05 : widget.fontSize,
            fontWeight: widget.fontWeight,
            decoration: _h ? TextDecoration.underline : TextDecoration.none,
            decorationColor: widget.color.withOpacity(0.5),
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

/// Elevated button with hover animation
class _HoverElevatedButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _HoverElevatedButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_HoverElevatedButton> createState() => _HoverElevatedButtonState();
}

class _HoverElevatedButtonState extends State<_HoverElevatedButton> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: _h ? widget.color.withOpacity(0.85) : widget.color,
            borderRadius: BorderRadius.circular(10),
            boxShadow:
                _h
                    ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                    : [],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              color: Colors.white,
              fontSize: _h ? 13.5 : 13,
              fontWeight: FontWeight.w700,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

/// Outlined button with hover
class _HoverOutlinedButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HoverOutlinedButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_HoverOutlinedButton> createState() => _HoverOutlinedButtonState();
}

class _HoverOutlinedButtonState extends State<_HoverOutlinedButton> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: _h ? widget.color.withOpacity(0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _h ? widget.color : widget.color.withOpacity(0.6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _h ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 140),
                child: Icon(widget.icon, color: widget.color, size: 15),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  color: widget.color,
                  fontSize: _h ? 13.5 : 13,
                  fontWeight: FontWeight.w600,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hover icon button (e.g. close ×)
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HoverIconButton({required this.icon, required this.onTap});

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _h ? Colors.white.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            color: _h ? Colors.white60 : Colors.white38,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Chip selector with hover
class _HoverChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _HoverChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  State<_HoverChip> createState() => _HoverChipState();
}

class _HoverChipState extends State<_HoverChip> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(right: 8, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                widget.selected
                    ? widget.color.withOpacity(0.2)
                    : (_h
                        ? widget.color.withOpacity(0.08)
                        : AppColors.bgPrimary),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  widget.selected
                      ? widget.color
                      : (_h ? widget.color.withOpacity(0.4) : AppColors.border),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color:
                  widget.selected
                      ? widget.color
                      : (_h ? widget.color.withOpacity(0.7) : Colors.white38),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Section label
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ── Dialog text field ──────────────────────────────────────────────────────────
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
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
      ),
    );
  }
}

// ── Fade route transition ──────────────────────────────────────────────────────
PageRouteBuilder _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════
class _AppUser {
  final String id, name, role, phone, loginTime, citizenId, district;
  final bool isOnline;
  const _AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.loginTime,
    required this.citizenId,
    required this.isOnline,
    required this.district,
  });
}

class _StatItem {
  final String label, value;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _InfoRow {
  final String label, value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});
}

class _LogEntry {
  final String time, event, level;
  const _LogEntry({
    required this.time,
    required this.event,
    required this.level,
  });
}

