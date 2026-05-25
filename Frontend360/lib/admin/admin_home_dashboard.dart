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

  // Page-level entrance animation controller
  late AnimationController _pageEntryCtrl;
  late Animation<double> _pageOpacity;
  late Animation<Offset> _pageSlide;

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
  }

  @override
  void dispose() {
    _pageEntryCtrl.dispose();
    super.dispose();
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
              ? FloatingActionButton(
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
              )
              : FloatingActionButton.extended(
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
      child: SingleChildScrollView(
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
                _buildPendingVerification(context),
                const SizedBox(height: 28),
                _buildRescueTeamStatus(context),
                const SizedBox(height: 28),
                _buildDuplicateReports(context),
                const SizedBox(height: 16),
              ],
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
              children: const [
                Icon(
                  Icons.pending_actions_outlined,
                  color: AppColors.warning,
                  size: 15,
                ),
                SizedBox(width: 6),
                Text(
                  '2 Pending',
                  style: TextStyle(
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
                submittedAgo: 'Just now',
                type: m.disasterType,
                location: m.title,
                description: m.description,
                upvotes: m.likes,
                downvotes: m.dislikes,
                date: m.createdAt,
                lat: m.latitude.toStringAsFixed(4) + '°N',
                lng: m.longitude.toStringAsFixed(4) + '°E',
                reporter:
                    m.userId.length > 8 ? m.userId.substring(0, 8) : m.userId,
                trustScore: 80,
                mediaUrls: m.mediaUrls,
              ),
            )
            .toList();

    final isWide =
        _Breakpoint.isTablet(context) || _Breakpoint.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('PENDING VERIFICATION'),
        const SizedBox(height: 12),
        isWide
            ? _twoColumnGrid(
              reports.map((report) {
                final adminReport = _toAdminReportData(report);
                final intId = int.tryParse(report.reportId.replaceAll(RegExp(r'[^0-9]'), ''));
                final isPendingRejection = intId != null && reportProvider.pendingRejections.contains(intId);

                if (isPendingRejection) {
                  return _buildInlineUndoCard(context, report, intId);
                }

                return _AnimatedPendingCard(
                  report: report,
                  onTap:
                      () => Navigator.push(
                        context,
                        _fadeRoute(
                          AdminReportDetailScreen(report: adminReport),
                        ),
                      ),
                  onVerify: () async {
                    try {
                      final intId = int.tryParse(
                        report.reportId.replaceAll(RegExp(r'[^0-9]'), ''),
                      );
                      if (intId != null)
                        await reportProvider.verifyReport(intId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Report verified')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Verify failed: $e')),
                        );
                      }
                    }
                  },
                  onReject:
                      () => _showRejectionSheet(context, adminReport, report),
                  onReview:
                      () => Navigator.push(
                        context,
                        _fadeRoute(
                          AdminReportDetailScreen(report: adminReport),
                        ),
                      ),
                );
              }).toList(),
            )
            : Column(
              children:
                  reports.map((report) {
                    final adminReport = _toAdminReportData(report);
                    final intId = int.tryParse(report.reportId.replaceAll(RegExp(r'[^0-9]'), ''));
                    final isPendingRejection = intId != null && reportProvider.pendingRejections.contains(intId);

                    if (isPendingRejection) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildInlineUndoCard(context, report, intId),
                      );
                    }

                    return _AnimatedPendingCard(
                      report: report,
                      onTap:
                          () => Navigator.push(
                            context,
                            _fadeRoute(
                              AdminReportDetailScreen(report: adminReport),
                            ),
                          ),
                      onVerify: () async {
                        try {
                          final intId = int.tryParse(
                            report.reportId.replaceAll(RegExp(r'[^0-9]'), ''),
                          );
                          if (intId != null)
                            await reportProvider.verifyReport(intId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Report verified')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Verify failed: $e')),
                            );
                          }
                        }
                      },
                      onReject:
                          () =>
                              _showRejectionSheet(context, adminReport, report),
                      onReview:
                          () => Navigator.push(
                            context,
                            _fadeRoute(
                              AdminReportDetailScreen(report: adminReport),
                            ),
                          ),
                    );
                  }).toList(),
            ),
      ],
    );
  }

  Widget _buildInlineUndoCard(BuildContext context, _PendingReportData report, int intId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${report.reportId} Rejected',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Deleting permanently in 5s...',
                    style: TextStyle(
                      color: AppColors.danger.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              context.read<ReportProvider>().undoInlineRejection(intId);
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
        context.read<ReportProvider>().rejectReportWithInlineUndo(intId);
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
            ? AppColors.orange.withOpacity(0.12)
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
                      color: AppColors.orange.withOpacity(0.25),
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

class _AnimatedPendingCard extends StatefulWidget {
  final _PendingReportData report;
  final VoidCallback onTap;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback onReview;

  const _AnimatedPendingCard({
    required this.report,
    required this.onTap,
    required this.onVerify,
    required this.onReject,
    required this.onReview,
  });

  @override
  State<_AnimatedPendingCard> createState() => _AnimatedPendingCardState();
}

class _AnimatedPendingCardState extends State<_AnimatedPendingCard> {
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
            final isNarrow = constraints.maxWidth < 380;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
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
                boxShadow:
                    _hovered
                        ? [
                          BoxShadow(
                            color: AppColors.warning.withOpacity(0.06),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ]
                        : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isNarrow
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '#${widget.report.reportId}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusBadge(status: widget.report.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.report.submittedAgo,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          Text(
                            '#${widget.report.reportId}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: widget.report.status),
                          const Spacer(),
                          Text(
                            widget.report.submittedAgo,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  const SizedBox(height: 10),
                  Text(
                    widget.report.type,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isNarrow ? 16 : 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.report.location,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.report.description,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.thumb_up_alt_outlined,
                        color: AppColors.success,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.report.upvotes}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.thumb_down_alt_outlined,
                        color: AppColors.danger,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.report.downvotes}',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  isNarrow
                      ? Column(
                        children: [
                          _AnimatedActionButton(
                            label: 'Verify',
                            icon: Icons.check_rounded,
                            color: AppColors.success,
                            onTap: widget.onVerify,
                            fullWidth: true,
                          ),
                          const SizedBox(height: 8),
                          _AnimatedActionButton(
                            label: 'Reject',
                            icon: Icons.close_rounded,
                            color: AppColors.danger,
                            onTap: widget.onReject,
                            fullWidth: true,
                          ),
                          const SizedBox(height: 8),
                          _AnimatedActionButton(
                            label: 'Review',
                            icon: Icons.visibility_outlined,
                            color: Colors.white54,
                            outlined: true,
                            onTap: widget.onReview,
                            fullWidth: true,
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          Expanded(
                            child: _AnimatedActionButton(
                              label: 'Verify',
                              icon: Icons.check_rounded,
                              color: AppColors.success,
                              onTap: widget.onVerify,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _AnimatedActionButton(
                              label: 'Reject',
                              icon: Icons.close_rounded,
                              color: AppColors.danger,
                              onTap: widget.onReject,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _AnimatedActionButton(
                              label: 'Review',
                              icon: Icons.visibility_outlined,
                              color: Colors.white54,
                              outlined: true,
                              onTap: widget.onReview,
                            ),
                          ),
                        ],
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
  final int upvotes;
  final int downvotes;
  final String date;
  final String lat;
  final String lng;
  final String reporter;
  final int trustScore;
  final List<String> mediaUrls;

  const _PendingReportData({
    required this.reportId,
    required this.status,
    required this.submittedAgo,
    required this.type,
    required this.location,
    required this.description,
    required this.upvotes,
    required this.downvotes,
    required this.date,
    required this.lat,
    required this.lng,
    required this.reporter,
    required this.trustScore,
    required this.mediaUrls,
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
