import 'package:disaster360/admin/admin_analytics.dart';
import 'package:disaster360/admin/admin_myreport.dart';
import 'package:disaster360/admin/admin_profile.dart';
import 'package:disaster360/admin/admin_user_management.dart';
import 'package:disaster360/admin/admin_report_details.dart';
import 'package:disaster360/services/fab_add_report.dart';
import 'package:disaster360/services/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/providers/report_provider.dart';
import 'package:disaster360/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
// ═══════════════════════════════════════════════════════════════════════════════
//  ADMIN HOME SCREEN — Disaster360
//  Enhanced with:
//   • Responsive layout: Mobile / Tablet / Desktop via MediaQuery breakpoints
//   • AnimatedSwitcher for smooth page transitions between nav items
//   • Hover animations on all interactive elements (cards, buttons, nav)
//   • Hand cursor (MouseRegion) on all clickable elements
//   • Subtle entrance animations via AnimatedOpacity + SlideTransition
//   • Rejection dialog (tablet/desktop) instead of bottom sheet (mobile)
//   • Floating action button: mobile (circular +), tablet/desktop (extended + Report)
//   • On tablet/desktop, report screen opens in a centered dialog (max width 560)
//   • No logic or data changes — pure UI enhancement layer
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Responsive Breakpoints ───────────────────────────────────────────────────
class _Breakpoint {
  static bool isMobile(BuildContext ctx) => MediaQuery.of(ctx).size.width < 600;
  static bool isTablet(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 600 &&
      MediaQuery.of(ctx).size.width < 1024;
  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 1024;

  static double horizontalPadding(BuildContext ctx) {
    if (isDesktop(ctx)) return MediaQuery.of(ctx).size.width * 0.12;
    if (isTablet(ctx)) return 32;
    return 16;
  }

  static double contentMaxWidth(BuildContext ctx) {
    if (isDesktop(ctx)) return 960;
    if (isTablet(ctx)) return 720;
    return double.infinity;
  }
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with TickerProviderStateMixin {
  int _activeNav = 0;
  int _previousNav = 0;
  int _currentReportIndex = 0;

  // Page-level entrance animation controller
  late AnimationController _pageEntryCtrl;
  late Animation<double> _pageOpacity;
  late Animation<Offset> _pageSlide;

  bool _isLoading = false;
  late AnimationController _refreshSpinController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReportProvider>();
      provider.fetchReports();
      provider.fetchActiveRescues();
      provider.fetchDuplicateReports();
    });
    _pageEntryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _pageOpacity = CurvedAnimation(
      parent: _pageEntryCtrl,
      curve: Curves.easeOut,
    );
    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageEntryCtrl, curve: Curves.easeOut));
    _pageEntryCtrl.forward();

    _refreshSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _pageEntryCtrl.dispose();
    _refreshSpinController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    _refreshSpinController.repeat();
    
    final provider = context.read<ReportProvider>();
    await Future.wait([
      provider.fetchReports(),
      provider.fetchActiveRescues(),
      provider.fetchDuplicateReports(),
    ]);

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() => _isLoading = false);
      _refreshSpinController.stop();
    }
  }

  void _navigateTo(int index) {
    if (index == _activeNav) return;
    setState(() {
      _previousNav = _activeNav;
      _activeNav = index;
    });
    _pageEntryCtrl.reset();
    _pageEntryCtrl.forward();
    // Re-fetch reports whenever the Reports tab becomes active
    // so the list is always in sync with the database.
    if (index == 1) {
      context.read<ReportProvider>().fetchReports();
    } else if (index == 0) {
      final provider = context.read<ReportProvider>();
      provider.fetchReports();
      provider.fetchActiveRescues();
      provider.fetchDuplicateReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = _Breakpoint.isDesktop(context);
    final isTablet = _Breakpoint.isTablet(context);
    final isMobile = !isDesktop && !isTablet;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      // Bottom nav only on mobile (wide layout uses side rail)
      bottomNavigationBar: isMobile ? _buildBottomNav(context) : null,
      body:
          isDesktop || isTablet
              ? _buildWideLayout(context)
              : _buildMobileLayout(context),
      // ✅ Floating action button – adaptive
      floatingActionButton: _buildFloatingButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ── FAB (mobile: circular +, tablet/desktop: extended with label) ───────────
  Widget? _buildFloatingButton(BuildContext context) {
    if (_activeNav == 5) return null; // Hide FAB on User Management section

    final isMobile = _Breakpoint.isMobile(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child:
          isMobile
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                onPressed: () {
                  // Mobile: full screen page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReportDisasterScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add, size: 28),
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
              ),
            )
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                onPressed: () {
                  // Tablet / Desktop: show as centered dialog (not full width)
                  _showReportDialog(context);
                },
                icon: const Icon(Icons.add_alert_rounded),
                label: const Text('New Report'),
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
    );
  }

  // ── Dialog for tablet/desktop – wraps ReportDisasterScreen ─────────────────
  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(
              maxWidth: 560, // not full width on large screens
              maxHeight: 700,
            ),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: const ReportDisasterScreen(), // unchanged original screen
            ),
          ),
        );
      },
    );
  }

  // ── Wide layout (tablet + desktop): persistent side rail ──────────────────
  Widget _buildWideLayout(BuildContext context) {
    final isDesktop = _Breakpoint.isDesktop(context);
    return Row(
      children: [
        _SideRail(
          activeNav: _activeNav,
          onNavTap: _navigateTo,
          expanded: isDesktop,
        ),
        Expanded(child: _buildAnimatedPage(context)),
      ],
    );
  }

  // ── Mobile layout: bottom nav bar ─────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    // No inner Scaffold – body only, bottom nav is on outer Scaffold
    return _buildAnimatedPage(context);
  }

  // ── Page content with entrance animation ──────────────────────────────────
  Widget _buildAnimatedPage(BuildContext context) {
    return FadeTransition(
      opacity: _pageOpacity,
      child: SlideTransition(
        position: _pageSlide,
        child: _getScreenForNav(context),
      ),
    );
  }

  // ── Screen router ──────────────────────────────────────────────────────────
  Widget _getScreenForNav(BuildContext context) {
    switch (_activeNav) {
      case 0:
        return _buildDashboard(context);
      case 1:
        return const AdminReportsScreen();
      case 2:
        return const DisasterMapScreen();
      case 3:
        return const AdminAnalyticsScreen();
      case 4:
        return const AdminProfileScreen();
      case 5:
        return const AdminUserManagementScreen();
      default:
        return const SizedBox();
    }
  }

  // ── Dashboard body ─────────────────────────────────────────────────────────
  Widget _buildDashboard(BuildContext context) {
    final hPad = _Breakpoint.horizontalPadding(context);
    final maxW = _Breakpoint.contentMaxWidth(context);

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.bgSurface,
        onRefresh: () async {
          await context.read<ReportProvider>().fetchReports();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildStatCards(context),
                const SizedBox(height: 28),
                if (_Breakpoint.isTablet(context) || _Breakpoint.isDesktop(context))
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 8,
                        child: _buildPendingVerification(context),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDuplicateReports(context),
                            const SizedBox(height: 28),
                            _buildRescueTeamStatus(context),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPendingVerification(context),
                      const SizedBox(height: 28),
                      _buildDuplicateReports(context),
                      const SizedBox(height: 28),
                      _buildRescueTeamStatus(context),
                    ],
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }


  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADMIN PANEL',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: _Breakpoint.isDesktop(context) ? 26 : 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Real-time Dashboard',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: _fetchDashboardData,
              child: AnimatedScale(
                scale: _isLoading ? 0.93 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isLoading ? AppColors.success.withOpacity(0.08) : AppColors.bgDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isLoading ? AppColors.success.withOpacity(0.4) : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RotationTransition(
                        turns: _refreshSpinController,
                        child: const Icon(Icons.refresh_rounded, color: AppColors.success, size: 15),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isLoading ? 'Refreshing...' : 'Refresh',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _HoverAnimatedWidget(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.pending_actions_outlined,
                      color: AppColors.warning,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${context.watch<ReportProvider>().reports.where((r) => r.status.toLowerCase() == 'pending').length} Pending',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Stat Cards ───────────────────────────────────────────────────────────
  Widget _buildStatCards(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final totalR = reportProvider.reports.length.toString();
    final unverifieds =
        reportProvider.reports
            .where((r) => r.status.toLowerCase() == 'pending')
            .length
            .toString();

    final isTabletOrDesktop =
        _Breakpoint.isTablet(context) || _Breakpoint.isDesktop(context);

    final cards = [
      _StatCardData(totalR, 'Total Reports', AppColors.info),
      _StatCardData(unverifieds, 'Unverified', AppColors.danger),
      _StatCardData('2', 'Teams Active', AppColors.success),
    ];

    return isTabletOrDesktop
        ? Row(
          children:
              cards
                  .map(
                    (c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: _AnimatedStatCard(data: c),
                      ),
                    ),
                  )
                  .toList(),
        )
        : Row(
          children:
              cards
                  .asMap()
                  .entries
                  .map(
                    (e) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: e.key < 2 ? 10 : 0),
                        child: _AnimatedStatCard(data: e.value),
                      ),
                    ),
                  )
                  .toList(),
        );
  }

  // ─── Pending Verification ─────────────────────────────────────────────────

  String _relativeDate(String dateStr) {
    try {
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
        dateStr += 'Z';
      }
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inHours < 1) {
        if (diff.inMinutes < 1) return 'Just now';
        return '${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else if (diff.inDays < 30) {
        return '${diff.inDays} days ago';
      } else if (diff.inDays < 365) {
        const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return '${monthNames[dt.month - 1]} ${dt.day}';
      } else {
        const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return '${monthNames[dt.month - 1]} ${dt.day}, ${dt.year}';
      }
    } catch (_) {
      return dateStr;
    }
  }

  AdminReportData _toAdminReportData(_PendingReportData p) {
    return AdminReportData(
      reportId: p.reportId,
      status: p.status,
      type: p.type,
      title: '${p.type} — ${p.location}',
      description: p.description,
      date: p.date,
      location: p.location,
      lat: p.lat,
      lng: p.lng,
      reporter: p.reporter,
      trustScore: p.trustScore,
      upvotes: p.upvotes,
      downvotes: p.downvotes,
      mediaUrls: p.mediaUrls,
      submissions: p.submissions,
    );
  }

  Widget _buildPendingVerification(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final pendingModels =
        reportProvider.reports
            .where((r) => r.status.toLowerCase() == 'pending')
            .toList();
    final reports =
        pendingModels
            .map(
              (m) => _PendingReportData(
                reportId: 'RPT-${m.id}',
                status: m.status,
                submittedAgo: _relativeDate(m.createdAt),
                type: m.disasterType,
                location: m.title,
                description: m.description,
                severity: m.severity,
                upvotes: m.likes,
                downvotes: m.dislikes,
                date: m.createdAt,
                lat: m.latitude.toStringAsFixed(4) + '°N',
                lng: m.longitude.toStringAsFixed(4) + '°E',
                reporter: m.userName,
                trustScore: 80,
                mediaUrls: m.mediaUrls,
                submissions: m.submissions,
              ),
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            const Text(
              'Pending Verification',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (reports.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white54),
                          onPressed: _currentReportIndex > 0
                              ? () => setState(() => _currentReportIndex--)
                              : null,
                        ),
                        Text(
                          'Report ${_currentReportIndex + 1} of ${reports.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white54),
                          onPressed: _currentReportIndex < reports.length - 1
                              ? () => setState(() => _currentReportIndex++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View Archive', style: TextStyle(color: AppColors.orange)),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: reports.isEmpty
              ? Container(
                  key: const ValueKey('empty_pending'),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_rounded, color: AppColors.success, size: 32),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'All caught up!',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No pending reports require verification at this time.',
                        style: TextStyle(
                          color: AppColors.success.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Builder(
                  builder: (context) {
                    // Safe index access
                    if (_currentReportIndex >= reports.length) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _currentReportIndex = reports.length - 1);
                      });
                      return const SizedBox.shrink();
                    }
                    final report = reports[_currentReportIndex];
                    final adminReport = _toAdminReportData(report);
                    final intId = int.tryParse(report.reportId.replaceAll(RegExp(r'[^0-9]'), ''));
                    final isPendingDeletion = intId != null && reportProvider.pendingDeletions.contains(intId);

                    if (isPendingDeletion) {
                      return _buildInlineUndoCard(context, report, intId);
                    }

                    return _SinglePendingReportCard(
                      key: ValueKey(report.reportId),
                      report: report,
                      onTap: () => Navigator.push(
                        context,
                        _fadeRoute(AdminReportDetailScreen(report: adminReport)),
                      ),
                      onVerify: () async {
                        try {
                          final intId = int.tryParse(report.reportId.replaceAll(RegExp(r'[^0-9]'), ''));
                          if (intId != null) await reportProvider.verifyReport(intId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report verified')));
                            if (_currentReportIndex >= reports.length - 1 && _currentReportIndex > 0) {
                              setState(() => _currentReportIndex--);
                            }
                          }
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verify failed: $e')));
                        }
                      },
                      onReject: () {
                         final rc = TextEditingController();
                         showDialog(
                           context: context,
                           builder: (_) => _RejectionDialog(
                             report: adminReport,
                             reasonController: rc,
                             onConfirmReject: (reason) async {
                               Navigator.pop(context);
                               final intId = int.tryParse(report.reportId.replaceAll(RegExp(r'[^0-9]'), ''));
                               if (intId != null) {
                                 try {
                                   await reportProvider.rejectReport(intId);
                                   if (mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report rejected')));
                                     if (_currentReportIndex >= reports.length - 1 && _currentReportIndex > 0) {
                                       setState(() => _currentReportIndex--);
                                     }
                                   }
                                 } catch (e) {
                                   if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reject failed: $e')));
                                 }
                               }
                             },
                           ),
                         );
                      },
                      onReview: () => Navigator.push(
                        context,
                        _fadeRoute(AdminReportDetailScreen(report: adminReport)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInlineUndoCard(BuildContext context, _PendingReportData report, int intId) {
    final color = AppColors.danger;
    final icon = Icons.delete_outline;
    final titleText = '${report.reportId} Deleted';
    final subtitleText = 'Deleting permanently in 5s...';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              context.read<ReportProvider>().undoInlineDeletion(intId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('UNDO', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRejectionSheet(
    BuildContext context,
    AdminReportData adminReport,
    _PendingReportData report,
  ) {
    final reasonController = TextEditingController();
    final isMobile = _Breakpoint.isMobile(context);

    final onConfirm = (String reason) {
      Navigator.pop(context);
      final intId = int.tryParse(report.reportId.replaceAll(RegExp(r'[^0-9]'), ''));
      if (intId != null) {
        context.read<ReportProvider>().rejectReport(intId);
      }
    };

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RejectionBottomSheet(
          report: adminReport,
          reasonController: reasonController,
          onConfirmReject: onConfirm,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => _RejectionDialog(
          report: adminReport,
          reasonController: reasonController,
          onConfirmReject: onConfirm,
        ),
      );
    }
  }

  // ─── Rescue Team Status ───────────────────────────────────────────────────
  Widget _buildRescueTeamStatus(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final activeRescues = reportProvider.activeRescues;

    final teams = activeRescues.map((rescue) {
      return _RescueTeamData(
        initials: rescue['initials'] ?? 'RT',
        initialsColor: AppColors.info,
        name: rescue['name'] ?? 'Unknown Team',
        locationStatus: rescue['locationStatus'] ?? 'Unknown',
        badge: rescue['badge'] ?? 'Dispatch',
        badgeColor: rescue['badge'] == 'Active' ? AppColors.success : AppColors.info,
        reportType: rescue['reportType'] ?? 'Unknown',
        title: rescue['title'] ?? 'Unknown',
        flag: rescue['flag'] ?? 'Ongoing',
      );
    }).toList();

    final isWide =
        _Breakpoint.isTablet(context) || _Breakpoint.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('RESCUE TEAM STATUS'),
        const SizedBox(height: 12),
        if (teams.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No active rescue operations.', style: TextStyle(color: Colors.white54)),
          )
        else if (isWide)
            _threeColumnGrid(
              teams
                  .map(
                    (team) => _AnimatedRescueCard(
                      team: team,
                      onTap: () => _showRescueTeamDialog(context, team),
                    ),
                  )
                  .toList(),
            )
        else
            Column(
              children:
                  teams
                      .map(
                        (team) => _AnimatedRescueCard(
                          team: team,
                          onTap: () => _showRescueTeamDialog(context, team),
                        ),
                      )
                      .toList(),
            ),
      ],
    );
  }

  void _showRescueTeamDialog(BuildContext context, _RescueTeamData team) {
    showDialog(
      context: context,
      builder:
          (_) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Dialog(
                backgroundColor: AppColors.bgSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: team.initialsColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                team.initials,
                                style: TextStyle(
                                  color: team.initialsColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              team.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _HoverAnimatedWidget(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white38,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 16),
                      _DialogInfoRow(
                        label: 'Report Type',
                        value: team.reportType,
                      ),
                      const SizedBox(height: 10),
                      _DialogInfoRow(label: 'Title', value: team.title),
                      const SizedBox(height: 10),
                      _DialogInfoRow(
                        label: 'Location',
                        value: team.locationStatus,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          _FlagBadge(flag: team.flag),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _HoverButton(
                        label: 'Close',
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // ─── Duplicate Reports ────────────────────────────────────────────────────
  Widget _buildDuplicateReports(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final duplicateReports = reportProvider.duplicateReports;

    final duplicates = duplicateReports.map((dup) {
      final mergedReportsRaw = dup['mergedReports'] as List<dynamic>? ?? [];
      final mergedReports = mergedReportsRaw.map((r) {
        return _MergedReportItem(
          id: r['id'] ?? 'Unknown',
          title: r['title'] ?? 'Unknown',
          date: r['date'] ?? 'Unknown',
          reporter: r['reporter'] ?? 'Unknown',
        );
      }).toList();

      return _DuplicateReportData(
        summary: dup['summary'] ?? '',
        detail: dup['detail'] ?? '',
        mergedReports: mergedReports,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('DUPLICATE REPORTS'),
        const SizedBox(height: 12),
        if (duplicates.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No duplicate reports found.', style: TextStyle(color: Colors.white54)),
          )
        else
          ...duplicates.map(
            (dup) => _AnimatedDuplicateCard(
              data: dup,
              onTap: () => _showMergedReportsDialog(context, dup),
            ),
          ),
      ],
    );
  }

  void _showMergedReportsDialog(
    BuildContext context,
    _DuplicateReportData data,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Dialog(
                backgroundColor: AppColors.bgSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.merge_type_rounded,
                              color: AppColors.warning,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Merged Reports',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          _HoverAnimatedWidget(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white38,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.detail,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 14),
                      ...data.mergedReports.map(
                        (report) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '#${report.id}',
                                    style: const TextStyle(
                                      color: AppColors.info,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    report.date,
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                report.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Reported by ${report.reporter}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _HoverButton(
                        label: 'Close',
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // ─── Bottom Nav (mobile) ───────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AnimatedNavItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            index: 0,
            activeIndex: _activeNav,
            onTap: _navigateTo,
          ),
          _AnimatedNavItem(
            icon: Icons.warning_amber_rounded,
            label: 'Reports',
            index: 1,
            activeIndex: _activeNav,
            onTap: _navigateTo,
          ),
          _AnimatedNavItem(
            icon: Icons.map_outlined,
            label: 'Risk Map',
            index: 2,
            activeIndex: _activeNav,
            onTap: _navigateTo,
          ),
          _AnimatedNavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Analytics',
            index: 3,
            activeIndex: _activeNav,
            onTap: _navigateTo,
          ),
          _AnimatedNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            index: 4,
            activeIndex: _activeNav,
            onTap: _navigateTo,
          ),
          _AnimatedNavItem(
            icon: Icons.people_alt_outlined,
            label: 'Users',
            index: 5,
            activeIndex: _activeNav,
            onTap: _navigateTo,
          ),
        ],
      ),
    );
  }

  // ─── Layout helpers ────────────────────────────────────────────────────────
  Widget _twoColumnGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (_, c) {
        final half = (c.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              children.map((w) => SizedBox(width: half, child: w)).toList(),
        );
      },
    );
  }

  Widget _threeColumnGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (_, c) {
        final third = (c.maxWidth - 24) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              children.map((w) => SizedBox(width: third, child: w)).toList(),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SIDE RAIL — Tablet / Desktop persistent navigation
// ══════════════════════════════════════════════════════════════════════════════

class _SideRail extends StatelessWidget {
  final int activeNav;
  final ValueChanged<int> onNavTap;
  final bool expanded;

  const _SideRail({
    required this.activeNav,
    required this.onNavTap,
    required this.expanded,
  });

  static const _items = [
    _NavData(Icons.dashboard_rounded, 'Dashboard'),
    _NavData(Icons.warning_amber_rounded, 'Reports'),
    _NavData(Icons.map_outlined, 'Risk Map'),
    _NavData(Icons.bar_chart_rounded, 'Analytics'),
    _NavData(Icons.person_outline_rounded, 'Profile'),
    _NavData(Icons.people_alt_outlined, 'Users'),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: expanded ? 220 : 72,
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child:
                  expanded
                      ? const Text(
                        'DISASTER360',
                        style: TextStyle(
                          color: AppColors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      )
                      : const Icon(
                        Icons.shield_outlined,
                        color: AppColors.orange,
                        size: 28,
                      ),
            ),
            const SizedBox(height: 28),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            ...List.generate(
              _items.length,
              (i) => _SideRailItem(
                icon: _items[i].icon,
                label: _items[i].label,
                isActive: activeNav == i,
                expanded: expanded,
                onTap: () => onNavTap(i),
              ),
            ),
            const Spacer(),
            const Divider(color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.bgDark,
                    child: Icon(Icons.person, size: 18, color: Colors.white70),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('System Console', style: TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('Admin', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideRailItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool expanded;
  final VoidCallback onTap;

  const _SideRailItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_SideRailItem> createState() => _SideRailItemState();
}

class _SideRailItemState extends State<_SideRailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? AppColors.orange : Colors.white38;
    final bg =
        widget.isActive
            ? AppColors.bgDark
            : _hovered
            ? Colors.white.withOpacity(0.05)
            : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          padding: EdgeInsets.symmetric(
            horizontal: widget.expanded ? 14 : 0,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border:
                widget.isActive
                    ? Border.all(
                      color: AppColors.border,
                      width: 1,
                    )
                    : null,
          ),
          child: Row(
            mainAxisAlignment:
                widget.expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _hovered && !widget.isActive ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 150),
                child:
                    widget.expanded
                        ? Icon(widget.icon, color: color, size: 20)
                        : Tooltip(
                          message: widget.label,
                          preferBelow: false,
                          child: Icon(widget.icon, color: color, size: 20),
                        ),
              ),
              if (widget.expanded) ...[
                const SizedBox(width: 12),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    color: color,
                    fontSize: _hovered && !widget.isActive ? 13.5 : 13,
                    fontWeight:
                        widget.isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED STAT CARD
// ══════════════════════════════════════════════════════════════════════════════

class _AnimatedStatCard extends StatefulWidget {
  final _StatCardData data;
  const _AnimatedStatCard({required this.data});

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color:
              _hovered
                  ? AppColors.bgSurface.withOpacity(0.9)
                  : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                _hovered
                    ? widget.data.color.withOpacity(0.35)
                    : Colors.transparent,
            width: 1,
          ),
          boxShadow:
              _hovered
                  ? [
                    BoxShadow(
                      color: widget.data.color.withOpacity(0.08),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                  : [],
        ),
        child: Column(
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: widget.data.color,
                fontSize: _hovered ? 32 : 28,
                fontWeight: FontWeight.w800,
              ),
              child: Text(widget.data.value),
            ),
            const SizedBox(height: 4),
            Text(
              widget.data.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED PENDING REPORT CARD
// ══════════════════════════════════════════════════════════════════════════════

class _SinglePendingReportCard extends StatefulWidget {
  final _PendingReportData report;
  final VoidCallback onTap;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback onReview;

  const _SinglePendingReportCard({
    super.key,
    required this.report,
    required this.onTap,
    required this.onVerify,
    required this.onReject,
    required this.onReview,
  });

  @override
  State<_SinglePendingReportCard> createState() => _SinglePendingReportCardState();
}

class _SinglePendingReportCardState extends State<_SinglePendingReportCard> {
  bool _hovered = false;

  String _relativeDate(String dateStr) {
    try {
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) dateStr += 'Z';
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inHours < 1) {
        if (diff.inMinutes < 1) return 'Just now';
        return '${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) return '${diff.inHours} hours ago';
      else if (diff.inDays < 30) return '${diff.inDays} days ago';
      else return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return dateStr; }
  }

  Color _getTypeColor(String type) {
    type = type.toLowerCase();
    if (type.contains('fire')) return AppColors.orange;
    if (type.contains('flood') || type.contains('water')) return AppColors.info;
    if (type.contains('earthquake')) return Colors.brown;
    if (type.contains('accident')) return AppColors.danger;
    return AppColors.warning;
  }

  (Color, String) _getSeverityInfo(String severity) {
    final s = severity.toLowerCase();
    if (s == 'low' || s == '1') return (const Color(0xFF4CAF50), 'LOW');
    if (s == 'moderate' || s == 'medium' || s == '2') return (const Color(0xFF8BC34A), 'MODERATE');
    if (s == 'high' || s == '3') return (const Color(0xFFFFB800), 'HIGH');
    if (s == 'severe' || s == '4') return (const Color(0xFFFF6B2B), 'SEVERE');
    if (s == 'extreme' || s == 'critical' || s == '5') return (const Color(0xFFFF3B3B), 'CRITICAL');
    return (AppColors.warning, severity.toUpperCase().isNotEmpty ? severity.toUpperCase() : 'UNKNOWN');
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(widget.report.type);
    final severityInfo = _getSeverityInfo(widget.report.severity);
    final severityColor = severityInfo.$1;
    final severityLabel = severityInfo.$2;
    final String? heroImage = widget.report.mediaUrls.isNotEmpty 
        ? widget.report.mediaUrls.first 
        : null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? typeColor.withOpacity(0.45) : AppColors.border,
              width: 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: typeColor.withOpacity(0.06),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: heroImage != null
                          ? Image.network(
                              heroImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: typeColor.withOpacity(0.2),
                                child: Center(
                                  child: Icon(Icons.image_not_supported_rounded, color: typeColor.withOpacity(0.5), size: 48),
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    typeColor.withOpacity(0.4),
                                    typeColor.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Icon(Icons.satellite_alt_rounded, color: typeColor.withOpacity(0.5), size: 48),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(severityLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bgDark.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white24, width: 0.5),
                          ),
                          child: Text(widget.report.type.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.report.location,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'REPORTED BY',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.report.reporter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.white54, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${widget.report.lat}, ${widget.report.lng}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.access_time_rounded, color: Colors.white54, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _relativeDate(widget.report.date),
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.report.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: widget.onVerify,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Verify', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: widget.onReview,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24, width: 1),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_rounded, color: Colors.white70, size: 20),
                                  SizedBox(width: 8),
                                  Text('Review', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: widget.onReject,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24, width: 1),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.highlight_off_rounded, color: AppColors.danger, size: 20),
                                  SizedBox(width: 8),
                                  Text('Reject', style: TextStyle(color: AppColors.danger, fontSize: 15, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED ACTION BUTTON (Verify / Reject / Review)
// ══════════════════════════════════════════════════════════════════════════════

class _AnimatedActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final bool fullWidth;
  final VoidCallback onTap;

  const _AnimatedActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
    this.fullWidth = false,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: widget.fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                widget.outlined
                    ? (_hovered
                        ? Colors.white.withOpacity(0.05)
                        : Colors.transparent)
                    : (_hovered
                        ? widget.color.withOpacity(0.28)
                        : widget.color.withOpacity(0.18)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  widget.outlined
                      ? (_hovered ? Colors.white38 : AppColors.border)
                      : widget.color.withOpacity(_hovered ? 0.65 : 0.45),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _hovered ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  widget.icon,
                  color:
                      widget.outlined
                          ? (_hovered ? Colors.white70 : Colors.white54)
                          : widget.color,
                  size: 14,
                ),
              ),
              const SizedBox(width: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  color:
                      widget.outlined
                          ? (_hovered ? Colors.white70 : Colors.white54)
                          : widget.color,
                  fontSize: _hovered ? 12.8 : 12,
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

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED RESCUE TEAM CARD
// ══════════════════════════════════════════════════════════════════════════════

class _AnimatedRescueCard extends StatefulWidget {
  final _RescueTeamData team;
  final VoidCallback onTap;
  const _AnimatedRescueCard({required this.team, required this.onTap});

  @override
  State<_AnimatedRescueCard> createState() => _AnimatedRescueCardState();
}

class _AnimatedRescueCardState extends State<_AnimatedRescueCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 280;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 12 : 16,
                vertical: isNarrow ? 16 : 14,
              ),
              decoration: BoxDecoration(
                color:
                    _hovered
                        ? AppColors.bgSurface.withOpacity(0.85)
                        : AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      _hovered
                          ? widget.team.initialsColor.withOpacity(0.35)
                          : AppColors.border,
                  width: 1,
                ),
                boxShadow:
                    _hovered
                        ? [
                          BoxShadow(
                            color: widget.team.initialsColor.withOpacity(0.07),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                        : [],
              ),
              child:
                  isNarrow
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: widget.team.initialsColor.withOpacity(
                                    _hovered ? 0.28 : 0.18,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.team.initials,
                                    style: TextStyle(
                                      color: widget.team.initialsColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              _TeamBadge(
                                label: widget.team.badge,
                                color: widget.team.badgeColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _hovered ? 13.5 : 13,
                              fontWeight: FontWeight.w600,
                            ),
                            child: Text(
                              widget.team.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.team.locationStatus,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: widget.team.initialsColor.withOpacity(
                                _hovered ? 0.28 : 0.18,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                widget.team.initials,
                                style: TextStyle(
                                  color: widget.team.initialsColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 150),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _hovered ? 14.8 : 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  child: Text(widget.team.name),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.team.locationStatus,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _TeamBadge(
                            label: widget.team.badge,
                            color: widget.team.badgeColor,
                          ),
                        ],
                      ),
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED DUPLICATE REPORT CARD
// ══════════════════════════════════════════════════════════════════════════════

class _AnimatedDuplicateCard extends StatefulWidget {
  final _DuplicateReportData data;
  final VoidCallback onTap;
  const _AnimatedDuplicateCard({required this.data, required this.onTap});

  @override
  State<_AnimatedDuplicateCard> createState() => _AnimatedDuplicateCardState();
}

class _AnimatedDuplicateCardState extends State<_AnimatedDuplicateCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  _hovered
                      ? AppColors.warning.withOpacity(0.45)
                      : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 12, top: 2),
                child: AnimatedScale(
                  scale: _hovered ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.merge_type_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _hovered ? 13.8 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                      child: Text(widget.data.summary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.data.detail,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                scale: _hovered ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED BOTTOM NAV ITEM (Mobile)
// ══════════════════════════════════════════════════════════════════════════════

class _AnimatedNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _AnimatedNavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.index == widget.activeIndex;
    final color = isActive ? AppColors.orange : Colors.white38;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color:
                isActive
                    ? AppColors.orange.withOpacity(0.10)
                    : (_hovered
                        ? Colors.white.withOpacity(0.05)
                        : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isActive ? 1.15 : (_hovered ? 1.10 : 1.0),
                duration: const Duration(milliseconds: 180),
                child: Icon(widget.icon, color: color, size: 22),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  color: color,
                  fontSize: isActive ? 10.5 : 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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

// ══════════════════════════════════════════════════════════════════════════════
//  SHARED REUSABLE ANIMATED WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _HoverAnimatedWidget extends StatefulWidget {
  final Widget child;
  const _HoverAnimatedWidget({required this.child});

  @override
  State<_HoverAnimatedWidget> createState() => _HoverAnimatedWidgetState();
}

class _HoverAnimatedWidgetState extends State<_HoverAnimatedWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: widget.child,
      ),
    );
  }
}

class _HoverButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _HoverButton({required this.label, required this.onTap});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withOpacity(0.08) : AppColors.bgDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? Colors.white38 : AppColors.border,
            ),
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                color: _hovered ? Colors.white70 : Colors.white54,
                fontSize: _hovered ? 13.5 : 13,
                fontWeight: FontWeight.w600,
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}

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

// ══════════════════════════════════════════════════════════════════════════════
//  PAGE TRANSITION HELPER
// ══════════════════════════════════════════════════════════════════════════════

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
            begin: const Offset(0, 0.025),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  UNCHANGED SUPPORTING WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (status) {
      case 'In Progress':
        bg = AppColors.orange.withOpacity(0.18);
        text = AppColors.orange;
        break;
      case 'Controlled':
      case 'Verified':
        bg = AppColors.success.withOpacity(0.15);
        text = AppColors.success;
        break;
      case 'Rejected':
        bg = AppColors.danger.withOpacity(0.15);
        text = AppColors.danger;
        break;
      default:
        bg = AppColors.warning.withOpacity(0.15);
        text = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: text.withOpacity(0.4), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TeamBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TeamBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
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
}

class _FlagBadge extends StatelessWidget {
  final String flag;
  const _FlagBadge({required this.flag});

  Color get _color {
    switch (flag) {
      case 'Rescuer Reached':
        return AppColors.success;
      case 'En Route':
        return AppColors.info;
      case 'Ongoing':
        return AppColors.orange;
      case 'Controlled':
        return AppColors.success;
      case 'Pending':
        return AppColors.warning;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        flag,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _DialogInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  REJECTION DIALOG
// ══════════════════════════════════════════════════════════════════════════════

class _RejectionDialog extends StatelessWidget {
  final AdminReportData report;
  final TextEditingController reasonController;
  final void Function(String reason) onConfirmReject;

  const _RejectionDialog({
    required this.report,
    required this.reasonController,
    required this.onConfirmReject,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.danger.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  blurRadius: 48,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: AppColors.danger.withOpacity(0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.danger,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Reject Report',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    _AnimatedIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${report.reportId}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TypeChip(label: report.type),
                          const Spacer(),
                          _StatusBadge(status: report.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${report.date}  ·  ${report.location}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Reason for Rejection',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Describe why this report is being rejected...',
                    hintStyle: const TextStyle(
                      color: Colors.white24,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppColors.bgDark,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.danger.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Cancel',
                        icon: Icons.arrow_back_rounded,
                        color: Colors.white38,
                        fullWidth: true,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: 'Confirm Rejection',
                        icon: Icons.close_rounded,
                        color: AppColors.danger,
                        filled: true,
                        fullWidth: true,
                        onTap: () => onConfirmReject(reasonController.text),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ADDITIONAL SUPPORTING WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _AnimatedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 150),
          child: Icon(icon, color: Colors.white38, size: 20),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  const _TypeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.orange,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final bool fullWidth;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.fullWidth = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: widget.fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                widget.filled
                    ? (_hovered ? widget.color : widget.color.withOpacity(0.9))
                    : (_hovered
                        ? widget.color.withOpacity(0.15)
                        : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  widget.filled
                      ? widget.color
                      : (_hovered
                          ? widget.color
                          : widget.color.withOpacity(0.5)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.filled ? Colors.white : widget.color,
                size: 14,
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  color: widget.filled ? Colors.white : widget.color,
                  fontSize: _hovered ? 13.2 : 13,
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

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

class _NavData {
  final IconData icon;
  final String label;
  const _NavData(this.icon, this.label);
}

class _StatCardData {
  final String value;
  final String label;
  final Color color;
  const _StatCardData(this.value, this.label, this.color);
}

class _PendingReportData {
  final String reportId;
  final String status;
  final String submittedAgo;
  final String type;
  final String location;
  final String description;
  final String severity;
  final int upvotes;
  final int downvotes;
  final String date;
  final String lat;
  final String lng;
  final String reporter;
  final int trustScore;
  final List<String> mediaUrls;
  final List<dynamic> submissions;

  const _PendingReportData({
    required this.reportId,
    required this.status,
    required this.submittedAgo,
    required this.type,
    required this.location,
    required this.description,
    required this.severity,
    required this.upvotes,
    required this.downvotes,
    required this.date,
    required this.lat,
    required this.lng,
    required this.reporter,
    required this.trustScore,
    required this.mediaUrls,
    this.submissions = const [],
  });
}

class _RescueTeamData {
  final String initials;
  final Color initialsColor;
  final String name;
  final String locationStatus;
  final String badge;
  final Color badgeColor;
  final String reportType;
  final String title;
  final String flag;

  const _RescueTeamData({
    required this.initials,
    required this.initialsColor,
    required this.name,
    required this.locationStatus,
    required this.badge,
    required this.badgeColor,
    required this.reportType,
    required this.title,
    required this.flag,
  });
}

class _DuplicateReportData {
  final String summary;
  final String detail;
  final List<_MergedReportItem> mergedReports;

  const _DuplicateReportData({
    required this.summary,
    required this.detail,
    required this.mergedReports,
  });
}

class _MergedReportItem {
  final String id;
  final String title;
  final String date;
  final String reporter;

  const _MergedReportItem({
    required this.id,
    required this.title,
    required this.date,
    required this.reporter,
  });
}
