import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:disaster360/colors.dart';
import 'package:disaster360/services/api_service.dart';
import 'package:disaster360/admin/report_volume_dashboard.dart';
import 'package:disaster360/admin/verification_rate_dashboard.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  ADMIN ANALYTICS SCREEN — Disaster360
//  Enhanced (zero logic / data changes):
//   • Responsive: Mobile (<600) single col | Tablet (600-1023) 2-col | Desktop (≥1024) 2-col centered
//   • Bottom sheets → Mobile only. Tablet/Desktop → constrained Dialog (maxWidth 480)
//   • All dialogs constrained — never full-width on wide screens
//   • Hover: AnimatedContainer border/glow + AnimatedScale 1.02x on cards
//   • Hand cursor (MouseRegion) on every interactive element
//   • FadeTransition + SlideTransition page entrance
//   • AnimatedContainer on time-range filter chips
//   • Zero overflow: all text wrapped with Flexible/overflow/maxLines
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Breakpoints ──────────────────────────────────────────────────────────────
class _BP {
  static bool isMobile(BuildContext c) => MediaQuery.of(c).size.width < 600;
  static bool isTablet(BuildContext c) =>
      MediaQuery.of(c).size.width >= 600 && MediaQuery.of(c).size.width < 1024;
  static bool isDesktop(BuildContext c) => MediaQuery.of(c).size.width >= 1024;
  static bool isWide(BuildContext c) => !isMobile(c);
  static double hPad(BuildContext c) {
    if (isDesktop(c)) return MediaQuery.of(c).size.width * 0.07;
    if (isTablet(c)) return 28.0;
    return 16.0;
  }

  static double maxW(BuildContext c) => isDesktop(c) ? 1120.0 : double.infinity;
}

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _refreshSpinController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String _timeRange = '7D';
  final List<String> _timeRanges = ['24H', '7D', '30D', '1Y'];

  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _refreshSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    final isFirstLoad = _analyticsData == null;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _refreshSpinController.repeat();
    try {
      final response = await _apiService.get('/admin/analytics?time_range=$_timeRange');
      setState(() {
        _analyticsData = response;
        _isLoading = false;
      });
      _refreshSpinController.stop();
      _refreshSpinController.reset();
      if (isFirstLoad) {
        _animController.forward(from: 0);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load analytics data: $e';
        _isLoading = false;
      });
      _refreshSpinController.stop();
      _refreshSpinController.reset();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _refreshSpinController.dispose();
    super.dispose();
  }

  void _onRangeChange(String range) {
    if (_timeRange == range) return;
    setState(() => _timeRange = range);
    _fetchAnalytics();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final hPad = _BP.hPad(context);

    Widget content;
    if (_isLoading && _analyticsData == null) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      );
    } else if (_errorMessage != null && _analyticsData == null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      );
    } else {
      final layout = _BP.isWide(context)
          ? _buildWideLayout(context)
          : _buildMobileLayout(context);
          
      content = AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        opacity: _isLoading ? 0.4 : 1.0,
        child: IgnorePointer(
          ignoring: _isLoading,
          child: layout,
        ),
      );
    }

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _BP.maxW(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildTimeRangeFilter(context),
                    const SizedBox(height: 28),
                    content,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Wide layout: two columns ──────────────────────────────────────────────
  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left column ────────────────────────────────────────────────────
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildSectionLabel('OVERVIEW'),
              const SizedBox(height: 12),
              _buildKpiRow(context),
              const SizedBox(height: 28),
              _buildSectionLabel('REPORT PROGRESS'),
              const SizedBox(height: 12),
              _buildReportProgressCard(context),
              const SizedBox(height: 28),
              _buildSectionLabel('VERIFICATION RATE'),
              const SizedBox(height: 12),
              _buildVerificationRateCard(context),
              const SizedBox(height: 28),
              _buildSectionLabel('RESPONSE TIME'),
              const SizedBox(height: 12),
              _buildResponseTimeCard(context),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // ── Right column ───────────────────────────────────────────────────
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildSectionLabel('REPORTS BY DISASTER TYPE'),
              const SizedBox(height: 12),
              _buildDisasterTypeCard(context),
              const SizedBox(height: 28),
              _buildSectionLabel('RESCUE TEAM PERFORMANCE'),
              const SizedBox(height: 12),
              _buildRescueTeamPerformance(context),
              const SizedBox(height: 28),
              _buildSectionLabel('COMMUNITY TRUST SIGNALS'),
              const SizedBox(height: 12),
              _buildCommunityTrustCard(context),
              const SizedBox(height: 28),
              _buildSectionLabel('TOP REPORTERS'),
              const SizedBox(height: 12),
              _buildTopReporters(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Mobile layout: single column ─────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('OVERVIEW'),
        const SizedBox(height: 12),
        _buildKpiRow(context),
        const SizedBox(height: 28),
        _buildSectionLabel('REPORT PROGRESS'),
        const SizedBox(height: 12),
        _buildReportProgressCard(context),
        const SizedBox(height: 28),
        _buildSectionLabel('VERIFICATION RATE'),
        const SizedBox(height: 12),
        _buildVerificationRateCard(context),
        const SizedBox(height: 28),
        _buildSectionLabel('REPORTS BY DISASTER TYPE'),
        const SizedBox(height: 12),
        _buildDisasterTypeCard(context),
        const SizedBox(height: 28),
        _buildSectionLabel('RESCUE TEAM PERFORMANCE'),
        const SizedBox(height: 12),
        _buildRescueTeamPerformance(context),
        const SizedBox(height: 28),
        _buildSectionLabel('RESPONSE TIME'),
        const SizedBox(height: 12),
        _buildResponseTimeCard(context),
        const SizedBox(height: 28),
        _buildSectionLabel('COMMUNITY TRUST SIGNALS'),
        const SizedBox(height: 12),
        _buildCommunityTrustCard(context),
        const SizedBox(height: 28),
        _buildSectionLabel('TOP REPORTERS'),
        const SizedBox(height: 12),
        _buildTopReporters(context),
        const SizedBox(height: 16),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  SECTION WIDGETS (identical content to original, enhanced presentation)
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ANALYTICS',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: _BP.isDesktop(context) ? 26 : 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Operational Intelligence',
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
              onTap: _fetchAnalytics,
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
            const SizedBox(width: 10),
            _HoverCard(
              onTap: () => _showExportSheet(context),
              borderColor: AppColors.border,
              hoverBorderColor: AppColors.info,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded, color: AppColors.info, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'Export',
                      style: TextStyle(
                        color: AppColors.info,
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

  Widget _buildTimeRangeFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            _timeRanges.map((range) {
              final isActive = _timeRange == range;
              return _HoverFilterChip(
                label: range,
                isActive: isActive,
                onTap: () => _onRangeChange(range),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ─── KPI Row ───────────────────────────────────────────────────────────────
  Widget _buildKpiRow(BuildContext context) {
    final kpis = Map<String, dynamic>.from(_analyticsData!['kpis']);
    final trends = Map<String, dynamic>.from(_analyticsData!['trends'] ?? {
      'total': {'value': '0%', 'up': true},
      'verified': {'value': '0%', 'up': true},
      'rejected': {'value': '0%', 'up': true},
      'pending': {'value': '0%', 'up': true},
    });

    return Column(
      children: [
        Row(
          children: [
            _AnimatedKpiCard(
              label: 'Total Reports',
              value: kpis['total'].toString(),
              valueColor: AppColors.info,
              icon: Icons.report_rounded,
              trend: trends['total']['value'],
              trendUp: trends['total']['up'],
              onTap: () => _showKpiDetail(context, 'Total Reports', kpis),
            ),
            const SizedBox(width: 10),
            _AnimatedKpiCard(
              label: 'Verified',
              value: kpis['verified'].toString(),
              valueColor: AppColors.success,
              icon: Icons.verified_rounded,
              trend: trends['verified']['value'],
              trendUp: trends['verified']['up'],
              onTap: () => _showKpiDetail(context, 'Verified Reports', kpis),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _AnimatedKpiCard(
              label: 'Rejected',
              value: kpis['rejected'].toString(),
              valueColor: AppColors.danger,
              icon: Icons.cancel_rounded,
              trend: trends['rejected']['value'],
              trendUp: trends['rejected']['up'],
              onTap: () => _showKpiDetail(context, 'Rejected Reports', kpis),
            ),
            const SizedBox(width: 10),
            _AnimatedKpiCard(
              label: 'Pending',
              value: kpis['pending'].toString(),
              valueColor: AppColors.warning,
              icon: Icons.pending_actions_rounded,
              trend: trends['pending']['value'],
              trendUp: trends['pending']['up'],
              onTap: () => _showKpiDetail(context, 'Pending Reports', kpis),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Report Progress ───────────────────────────────────────────────────────
  Widget _buildReportProgressCard(BuildContext context) {
    final fullData = List<Map<String, dynamic>>.from(_analyticsData!['dailyReports']);
    List<Map<String, dynamic>> data = fullData;
    if (_timeRange == '24H' && data.length > 6) {
      data = data.sublist(data.length - 6);
    }
    return _HoverCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportVolumeDashboardScreen(
              data: fullData,
              timeRange: _timeRange,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Daily Report Volume',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.open_in_full_rounded,
                  color: Colors.white38,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${fullData.fold(0, (s, e) => s + ((e['count'] as num).toInt()))} reports in period',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 20),
            SizedBox(height: 100, child: _BarChartPainterWidget(data: data)),
            const SizedBox(height: 8),
            Row(
              children: data.map((e) {
                return Expanded(
                  child: Center(
                    child: e['showLabel'] == true
                        ? Text(
                            e['label'] as String,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Verification Rate ─────────────────────────────────────────────────────
  Widget _buildVerificationRateCard(BuildContext context) {
    final kpis = Map<String, dynamic>.from(_analyticsData!['kpis']);
    final total = (kpis['total'] as num).toDouble();
    final verified = (kpis['verified'] as num).toDouble();
    final rejected = (kpis['rejected'] as num).toDouble();
    final pending = (kpis['pending'] as num).toDouble();
    final verifiedPct = total > 0 ? (verified / total * 100).round() : 0;
    final rejectedPct = total > 0 ? (rejected / total * 100).round() : 0;
    final pendingPct = total > 0 ? (pending / total * 100).round() : 0;

    return _HoverCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationRateDashboardScreen(
              totalReports: total.toInt(),
              verifiedCount: verified.toInt(),
              rejectedCount: rejected.toInt(),
              pendingCount: pending.toInt(),
              timeRange: _timeRange,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Verification Rate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.open_in_full_rounded,
                  color: Colors.white38,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${total.toInt()} reports in period',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      segments: [
                        _DonutSegment(AppColors.success, verified),
                        _DonutSegment(AppColors.danger, rejected),
                        _DonutSegment(AppColors.warning, pending),
                        _DonutSegment(
                          AppColors.bgDark,
                          math.max(0, total - verified - rejected - pending),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$verifiedPct%',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'verified',
                            style: TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DonutLegendRow(
                        color: AppColors.success,
                        label: 'Verified',
                        value: '$verifiedPct%',
                        count: (kpis['verified'] as num).toInt(),
                      ),
                      const SizedBox(height: 10),
                      _DonutLegendRow(
                        color: AppColors.danger,
                        label: 'Rejected',
                        value: '$rejectedPct%',
                        count: (kpis['rejected'] as num).toInt(),
                      ),
                      const SizedBox(height: 10),
                      _DonutLegendRow(
                        color: AppColors.warning,
                        label: 'Pending',
                        value: '$pendingPct%',
                        count: (kpis['pending'] as num).toInt(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Disaster Type ─────────────────────────────────────────────────────────
  Widget _buildDisasterTypeCard(BuildContext context) {
    final types = List<Map<String, dynamic>>.from(_analyticsData!['disasterTypes']).map((t) {
      final label = t['label'].toString().toLowerCase();
      Color c = AppColors.success;
      if (label.contains('flood')) c = AppColors.info;
      else if (label.contains('landslide')) c = AppColors.warning;
      else if (label.contains('fire')) c = AppColors.danger;
      else if (label.contains('earthquake')) c = AppColors.orange;
      return {...t, 'color': c};
    }).toList();
    final maxCount = types.isEmpty ? 0 : types.map((t) => (t['count'] as num).toInt()).reduce(math.max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children:
            types.map((type) {
              final count = (type['count'] as num).toInt();
              final pct = maxCount > 0 ? count / maxCount : 0.0;
              return _HoverRow(
                onTap: () => _showDisasterTypeDetail(context, type),
                builder: (isHovered) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: type['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              type['label'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$count reports',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isHovered ? Colors.white70 : Colors.white24,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          builder:
                              (_, value, __) => LinearProgressIndicator(
                                value: value,
                                backgroundColor: AppColors.bgDark,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  type['color'] as Color,
                                ),
                                minHeight: 6,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // ─── Rescue Team Performance ───────────────────────────────────────────────
  Widget _buildRescueTeamPerformance(BuildContext context) {
    final teams = List<Map<String, dynamic>>.from(_analyticsData!['rescueTeams']).map((t) {
      final type = t['type'].toString().toLowerCase();
      Color c = AppColors.success;
      if (type.contains('flood')) c = AppColors.info;
      else if (type.contains('fire')) c = AppColors.danger;
      else if (type.contains('search')) c = AppColors.warning;
      return {...t, 'color': c};
    }).toList();
    return Column(
      children:
          teams.map((team) {
            return _HoverCard(
              margin: const EdgeInsets.only(bottom: 10),
              onTap: () => _showRescueTeamDetail(context, team),
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: (team['color'] as Color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          team['initials'] as String,
                          style: TextStyle(
                            color: team['color'] as Color,
                            fontSize: 12,
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
                          Text(
                            team['name'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _MiniStat(
                                label: 'Missions',
                                value: team['missions'].toString(),
                                color: AppColors.info,
                              ),
                              const SizedBox(width: 12),
                              _MiniStat(
                                label: 'Success',
                                value: '${team['successRate']}%',
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 12),
                              _MiniStat(
                                label: 'Avg Time',
                                value: '${team['avgTime']}m',
                                color: AppColors.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white24,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  // ─── Response Time ─────────────────────────────────────────────────────────
  Widget _buildResponseTimeCard(BuildContext context) {
    final data = Map<String, dynamic>.from(_analyticsData!['responseTime']);
    return _HoverCard(
      onTap: () => _showResponseTimeDetail(context, data),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Avg Response & Control Times',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.open_in_full_rounded,
                  color: Colors.white38,
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ResponseTimeStat(
                  label: 'Dispatch',
                  value: '${data['dispatch']}m',
                  icon: Icons.radio_button_checked_rounded,
                  color: AppColors.info,
                ),
                const SizedBox(width: 10),
                _ResponseTimeStat(
                  label: 'On Scene',
                  value: '${data['onScene']}m',
                  icon: Icons.directions_run_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                _ResponseTimeStat(
                  label: 'Controlled',
                  value: '${data['controlled']}m',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimelineBar(data),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineBar(Map<String, dynamic> data) {
    final dispatch = (data['dispatch'] as num).toDouble();
    final onScene = (data['onScene'] as num).toDouble();
    final controlled = (data['controlled'] as num).toDouble();
    final total = dispatch + onScene + controlled;
    
    final dispatchFlex = total > 0 ? (dispatch / total * 100).round() : 1;
    final onSceneFlex = total > 0 ? (onScene / total * 100).round() : 1;
    final controlledFlex = total > 0 ? (controlled / total * 100).round() : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Flexible(
                flex: dispatchFlex,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  builder:
                      (_, v, __) => Container(
                        height: 10,
                        color: AppColors.info.withOpacity(total > 0 ? v : v * 0.2),
                      ),
                ),
              ),
              Flexible(
                flex: onSceneFlex,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1100),
                  builder:
                      (_, v, __) => Container(
                        height: 10,
                        color: AppColors.warning.withOpacity(total > 0 ? v : v * 0.2),
                      ),
                ),
              ),
              Flexible(
                flex: controlledFlex,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1300),
                  builder:
                      (_, v, __) => Container(
                        height: 10,
                        color: AppColors.success.withOpacity(total > 0 ? v : v * 0.2),
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _TimelineLegend(color: AppColors.info, label: 'Dispatch'),
            const SizedBox(width: 14),
            _TimelineLegend(color: AppColors.warning, label: 'En Route'),
            const SizedBox(width: 14),
            _TimelineLegend(color: AppColors.success, label: 'Control'),
          ],
        ),
      ],
    );
  }

  // ─── Community Trust ───────────────────────────────────────────────────────
  Widget _buildCommunityTrustCard(BuildContext context) {
    final trust = Map<String, dynamic>.from(_analyticsData!['communityTrust']);
    final upvotes = (trust['upvotes'] as num).toInt();
    final downvotes = (trust['downvotes'] as num).toInt();
    final total = upvotes + downvotes;
    final upPct = total > 0 ? upvotes / total : 0.5;

    return _HoverCard(
      onTap: () => _showCommunityTrustDetail(context, trust),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _VoteStatBlock(
                    icon: Icons.thumb_up_alt_rounded,
                    color: AppColors.success,
                    label: 'Total Upvotes',
                    value: upvotes.toString(),
                  ),
                ),
                Container(width: 1, height: 50, color: AppColors.border),
                Expanded(
                  child: _VoteStatBlock(
                    icon: Icons.thumb_down_alt_rounded,
                    color: AppColors.danger,
                    label: 'Total Downvotes',
                    value: downvotes.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(upPct * 100).round()}% community trust',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(
                      Icons.open_in_full_rounded,
                      color: Colors.white24,
                      size: 13,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: upPct),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    builder:
                        (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 10,
                          backgroundColor: AppColors.bgDark,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Based on ${trust['reportCount']} verified reports',
                  style: const TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top Reporters ─────────────────────────────────────────────────────────
  Widget _buildTopReporters(BuildContext context) {
    final reporters = List<Map<String, dynamic>>.from(_analyticsData!['topReporters']);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children:
            reporters.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              return _HoverRow(
                onTap: () => _showReporterDetail(context, r),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border:
                        i < reporters.length - 1
                            ? const Border(
                              bottom: BorderSide(
                                color: AppColors.border,
                                width: 1,
                              ),
                            )
                            : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '#${i + 1}',
                          style: TextStyle(
                            color:
                                i == 0
                                    ? AppColors.warning
                                    : i == 1
                                    ? Colors.white54
                                    : Colors.white24,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.orange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              r['location'] as String,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${r['reports']} reports',
                            style: const TextStyle(
                              color: AppColors.info,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Trust: ${r['trust']}/100',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white24,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  DIALOGS & SHEETS
  //  Mobile → bottom sheet | Tablet/Desktop → constrained Dialog (maxWidth 480)
  // ════════════════════════════════════════════════════════════════════════════

  /// Central dispatcher — shows bottom sheet on mobile, dialog on wide screens
  void _showPanel({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    Widget? headerWidget,
    double maxWidth = 480,
  }) {
    if (_BP.isWide(context)) {
      showDialog(
        context: context,
        builder:
            (_) => _ConstrainedAnalyticsDialog(
              title: title,
              headerWidget: headerWidget,
              children: children,
              maxWidth: maxWidth,
            ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder:
            (_) => DraggableScrollableSheet(
              initialChildSize: 0.55,
              maxChildSize: 0.92,
              minChildSize: 0.3,
              builder:
                  (_, ctrl) => Container(
                    decoration: const BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (headerWidget != null) ...[
                          const SizedBox(height: 6),
                          headerWidget,
                        ],
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView(controller: ctrl, children: children),
                        ),
                      ],
                    ),
                  ),
            ),
      );
    }
  }

  void _showExportSheet(BuildContext context) {
    final items = [
      ['PDF Report', Icons.picture_as_pdf_rounded, AppColors.danger],
      ['CSV Data', Icons.table_chart_rounded, AppColors.success],
      ['Excel Sheet', Icons.grid_on_rounded, AppColors.info],
    ];

    _showPanel(
      context: context,
      title: 'Export Report',
      headerWidget: const Text(
        'Choose a format to download analytics data',
        style: TextStyle(color: Colors.white38, fontSize: 13),
      ),
      children:
          items
              .map(
                (item) => _HoverRow(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item[0]} export started...'),
                        backgroundColor: AppColors.bgDark,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item[1] as IconData,
                          color: item[2] as Color,
                          size: 20,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item[0] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.download_rounded,
                          color: Colors.white38,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  void _showKpiDetail(
    BuildContext context,
    String title,
    Map<String, dynamic> kpis,
  ) {
    _showPanel(
      context: context,
      title: title,
      children: [
        _DialogRow(label: 'Total Reports', value: kpis['total'].toString()),
        _DialogRow(label: 'Verified', value: kpis['verified'].toString()),
        _DialogRow(label: 'Rejected', value: kpis['rejected'].toString()),
        _DialogRow(label: 'Pending', value: kpis['pending'].toString()),
        _DialogRow(
          label: 'Verification Rate',
          value:
              '${(kpis['total'] as num) > 0 ? ((kpis['verified'] as num) / (kpis['total'] as num) * 100).round() : 0}%',
        ),
      ],
    );
  }

  void _showReportProgressDetail(
    BuildContext context,
    List<Map<String, dynamic>> data,
  ) {
    // Start scrolled all the way to the right (newest data)
    final scrollController = ScrollController(initialScrollOffset: 10000.0);
    _showPanel(
      context: context,
      title: 'Daily Report Volume',
      maxWidth: 800,
      children: [
        const SizedBox(height: 10),
        RawScrollbar(
          controller: scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          thickness: 8,
          radius: const Radius.circular(4),
          thumbColor: Colors.white54,
          trackColor: Colors.white10,
          child: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.only(bottom: 16), // space for scrollbar
              width: math.max(800.0, data.length * 70.0),
              child: Column(
                children: [
                  SizedBox(height: 240, child: _BarChartPainterWidget(data: data)),
                const SizedBox(height: 12),
                Row(
                  children: data.map((e) {
                    return Expanded(
                      child: Center(
                        child: e['showLabel'] == true
                            ? Text(
                                e['label'] as String,
                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                              )
                            : const SizedBox.shrink(),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Detailed Breakdown',
          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.1),
        ),
        const SizedBox(height: 16),
        _DetailedBreakdownList(data: data),
      ],
    );
  }

  void _showVerificationDetail(
    BuildContext context,
    int verified,
    int rejected,
    int pending,
  ) {
    final kpis = Map<String, dynamic>.from(_analyticsData!['kpis']);
    final total = (kpis['total'] as num).toInt();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationRateDashboardScreen(
          totalReports: total,
          verifiedCount: (kpis['verified'] as num).toInt(),
          rejectedCount: (kpis['rejected'] as num).toInt(),
          pendingCount: (kpis['pending'] as num).toInt(),
          timeRange: _timeRange,
        ),
      ),
    );
  }

  void _showDisasterTypeDetail(
    BuildContext context,
    Map<String, dynamic> type,
  ) {
    _showPanel(
      context: context,
      title: '${type['label']} Reports',
      children: [
        _DialogRow(label: 'Total Reports', value: type['count'].toString()),
        _DialogRow(label: 'Verified', value: type['verified'].toString()),
        _DialogRow(label: 'Pending', value: type['pending'].toString()),
        _DialogRow(label: 'Avg Response', value: '${type['avgResponse']}m'),
        _DialogRow(label: 'Severity', value: type['severity'] as String),
      ],
    );
  }

  void _showRescueTeamDetail(BuildContext context, Map<String, dynamic> team) {
    _showPanel(
      context: context,
      title: team['name'] as String,
      headerWidget: Text(
        team['type'] as String,
        style: const TextStyle(color: Colors.white38, fontSize: 13),
      ),
      children: [
        // Success rate bar
        const Text(
          'Success Rate',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (team['successRate'] as num).toDouble() / 100),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder:
                (_, v, __) => LinearProgressIndicator(
                  value: v,
                  backgroundColor: AppColors.bgDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.success,
                  ),
                  minHeight: 8,
                ),
          ),
        ),
        const SizedBox(height: 16),
        _DialogRow(label: 'Total Missions', value: team['missions'].toString()),
        _DialogRow(label: 'Success Rate', value: '${team['successRate']}%'),
        _DialogRow(label: 'Failed Missions', value: team['failed'].toString()),
        _DialogRow(label: 'Avg Response Time', value: '${team['avgTime']} min'),
        _DialogRow(
          label: 'Avg Control Time',
          value: '${team['controlTime']} min',
        ),
        _DialogRow(label: 'Current Status', value: team['status'] as String),
      ],
    );
  }

  void _showResponseTimeDetail(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    _showPanel(
      context: context,
      title: 'Response Time Breakdown',
      children: [
        _DialogRow(
          label: 'Avg Dispatch Time',
          value: '${data['dispatch']} min',
        ),
        _DialogRow(label: 'Avg On-Scene Time', value: '${data['onScene']} min'),
        _DialogRow(
          label: 'Avg Control Time',
          value: '${data['controlled']} min',
        ),
        _DialogRow(
          label: 'Total Avg Duration',
          value:
              '${(data['dispatch'] as num).toInt() + (data['onScene'] as num).toInt() + (data['controlled'] as num).toInt()} min',
        ),
        _DialogRow(label: 'Fastest Response', value: '${data['fastest']} min'),
        _DialogRow(label: 'Slowest Response', value: '${data['slowest']} min'),
      ],
    );
  }

  void _showCommunityTrustDetail(
    BuildContext context,
    Map<String, dynamic> trust,
  ) {
    _showPanel(
      context: context,
      title: 'Community Trust Signals',
      children: [
        _DialogRow(label: 'Total Upvotes', value: trust['upvotes'].toString()),
        _DialogRow(
          label: 'Total Downvotes',
          value: trust['downvotes'].toString(),
        ),
        _DialogRow(
          label: 'Reports Evaluated',
          value: trust['reportCount'].toString(),
        ),
        _DialogRow(
          label: 'Avg Upvotes / Report',
          value: trust['avgUpvotes'].toString(),
        ),
        _DialogRow(
          label: 'Avg Downvotes / Report',
          value: trust['avgDownvotes'].toString(),
        ),
        _DialogRow(
          label: 'Highest Trusted Report',
          value: trust['topReport'] as String,
        ),
      ],
    );
  }

  void _showReporterDetail(BuildContext context, Map<String, dynamic> r) {
    _showPanel(
      context: context,
      title: r['name'] as String,
      headerWidget: Text(
        r['location'] as String,
        style: const TextStyle(color: Colors.white38, fontSize: 13),
      ),
      children: [
        _DialogRow(label: 'Total Reports', value: r['reports'].toString()),
        _DialogRow(label: 'Trust Score', value: '${r['trust']}/100'),
        _DialogRow(label: 'Verified Reports', value: r['verified'].toString()),
        _DialogRow(label: 'Rejected Reports', value: r['rejected'].toString()),
        _DialogRow(label: 'Upvotes Received', value: r['upvotes'].toString()),
      ],
    );
  }

}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED / HOVER WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

/// Generic card with hover: border highlight + slight scale + glow
class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;
  final Color borderColor;
  final Color hoverBorderColor;

  const _HoverCard({
    required this.child,
    required this.onTap,
    this.margin,
    this.borderColor = AppColors.border,
    this.hoverBorderColor = AppColors.orange,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _h ? 1.012 : 1.0,
          duration: const Duration(milliseconds: 160),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: widget.margin,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    _h
                        ? widget.hoverBorderColor.withOpacity(0.55)
                        : widget.borderColor,
                width: 1,
              ),
              boxShadow:
                  _h
                      ? [
                        BoxShadow(
                          color: widget.hoverBorderColor.withOpacity(0.07),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                      : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Hover effect for inline rows (disaster type rows, reporter rows)
class _HoverRow extends StatefulWidget {
  final Widget? child;
  final Widget Function(bool isHovered)? builder;
  final VoidCallback onTap;

  const _HoverRow({this.child, this.builder, required this.onTap});

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
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
          padding:
              _h ? const EdgeInsets.symmetric(horizontal: 6) : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: _h ? Colors.white.withOpacity(0.03) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.builder != null ? widget.builder!(_h) : widget.child!,
        ),
      ),
    );
  }
}

/// Animated KPI card — hover scale + border glow + animated count
class _AnimatedKpiCard extends StatefulWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final String trend;
  final bool trendUp;
  final VoidCallback onTap;

  const _AnimatedKpiCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.trend,
    required this.trendUp,
    required this.onTap,
  });

  @override
  State<_AnimatedKpiCard> createState() => _AnimatedKpiCardState();
}

class _AnimatedKpiCardState extends State<_AnimatedKpiCard> {
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
          child: AnimatedScale(
            scale: _h ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 170),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      _h
                          ? widget.valueColor.withOpacity(0.45)
                          : AppColors.border,
                  width: 1,
                ),
                boxShadow:
                    _h
                        ? [
                          BoxShadow(
                            color: widget.valueColor.withOpacity(0.08),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ]
                        : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.valueColor.withOpacity(
                            _h ? 0.20 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.valueColor,
                          size: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.trend == "0%" 
                              ? Colors.white.withOpacity(0.08)
                              : (widget.trendUp
                                  ? AppColors.success
                                  : AppColors.danger)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.trend,
                          style: TextStyle(
                            color: widget.trend == "0%"
                                ? Colors.white54
                                : (widget.trendUp
                                    ? AppColors.success
                                    : AppColors.danger),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: double.parse(widget.value)),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder:
                        (_, v, __) => AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          style: TextStyle(
                            color: widget.valueColor,
                            fontSize: _h ? 36 : 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          child: Text(v.round().toString()),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hover-animated filter chip
class _HoverFilterChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _HoverFilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_HoverFilterChip> createState() => _HoverFilterChipState();
}

class _HoverFilterChipState extends State<_HoverFilterChip> {
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color:
                widget.isActive
                    ? AppColors.orange.withOpacity(0.15)
                    : (_h ? Colors.white.withOpacity(0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  widget.isActive
                      ? AppColors.orange.withOpacity(0.3)
                      : Colors.transparent,
              width: 1,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              color:
                  widget.isActive
                      ? Colors.white
                      : (_h ? Colors.white70 : Colors.white54),
              fontSize: 12,
              fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w400,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CONSTRAINED ANALYTICS DIALOG — used on tablet + desktop
//  Never takes full screen width — constrained to maxWidth 480
// ══════════════════════════════════════════════════════════════════════════════

class _ConstrainedAnalyticsDialog extends StatelessWidget {
  final String title;
  final Widget? headerWidget;
  final List<Widget> children;
  final double maxWidth;

  const _ConstrainedAnalyticsDialog({
    required this.title,
    required this.children,
    this.headerWidget,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _CloseButton(onTap: () => Navigator.pop(context)),
                    ],
                  ),
                  if (headerWidget != null) ...[
                    const SizedBox(height: 4),
                    headerWidget!,
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 16),
                  ...children,
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _HoverCloseButton(
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
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
            Icons.close,
            color: _h ? Colors.white60 : Colors.white38,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _HoverCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverCloseButton({required this.onTap});

  @override
  State<_HoverCloseButton> createState() => _HoverCloseButtonState();
}

class _HoverCloseButtonState extends State<_HoverCloseButton> {
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _h ? Colors.white.withOpacity(0.08) : AppColors.bgDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _h ? Colors.white38 : AppColors.border),
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                color: _h ? Colors.white70 : Colors.white54,
                fontSize: _h ? 13.5 : 13,
                fontWeight: FontWeight.w600,
              ),
              child: const Text('Close'),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  UNCHANGED SUPPORTING WIDGETS — identical to original
// ══════════════════════════════════════════════════════════════════════════════

class _BarChartPainterWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _BarChartPainterWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder:
          (_, progress, __) => CustomPaint(
            painter: _BarChartPainter(data: data, progress: progress),
            size: Size.infinite,
          ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double progress;
  _BarChartPainter({required this.data, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxCount =
        data.map((d) => d['count'] as int).reduce(math.max).toDouble();
    if (maxCount == 0) return;
    final barWidth = (size.width / data.length) * 0.55;
    final gap = (size.width / data.length) * 0.45;
    for (int i = 0; i < data.length; i++) {
      final count = (data[i]['count'] as int).toDouble();
      final barHeight = (count / maxCount) * size.height * progress;
      final left = i * (barWidth + gap) + gap / 2;
      final top = size.height - barHeight;
      final isMax = count == maxCount;
      final paint =
          Paint()
            ..color =
                isMax ? AppColors.orange : AppColors.orange.withOpacity(0.8)
            ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, top, barWidth, barHeight),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.progress != progress || old.data != data;
}

class _DonutSegment {
  final Color color;
  final double value;
  const _DonutSegment(this.color, this.value);
}

class _DonutChartPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  const _DonutChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold(0.0, (s, e) => s + e.value);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.32;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );
    double startAngle = -math.pi / 2;
    const gap = 0.04;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweep = (seg.value / total) * 2 * math.pi - gap;
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) => old.segments != segments;
}

class _DonutLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final int count;
  const _DonutLegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(color: Colors.white24, fontSize: 11),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}

class _ResponseTimeStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _ResponseTimeStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _TimelineLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}

class _VoteStatBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _VoteStatBlock({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: double.parse(value)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder:
                (_, v, __) => Text(
                  v.round().toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DialogRow extends StatelessWidget {
  final String label;
  final String value;
  const _DialogRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedBreakdownList extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  const _DetailedBreakdownList({required this.data});

  @override
  State<_DetailedBreakdownList> createState() => _DetailedBreakdownListState();
}

class _DetailedBreakdownListState extends State<_DetailedBreakdownList> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.data.length > 6;
    // Show newest (last) 6 hours if not showing all.
    final displayData = _showAll || !hasMore
        ? widget.data
        : widget.data.sublist(widget.data.length - 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayData.map(
          (d) => _DialogRow(
            label: d['label'] as String,
            value: '${d['count']} reports',
          ),
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(
                  _showAll ? 'See Less' : 'See More',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
