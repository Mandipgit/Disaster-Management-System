import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── COLOR PALETTE ──────────────────────────────────────────────────────────
const Color _bg = Color(0xFF0F1117);
const Color _cardSurface = Color(0xFF161B26);
const Color _elevatedPanel = Color(0xFF1C2333);
const Color _accent = Color(0xFFF56F2C);
const Color _fgText = Color(0xFFE2E4EB);
const Color _mutedText = Color(0xFF6B7585);
final Color _border = Colors.white.withOpacity(0.07);

const Color _verified = Color(0xFF00D4AA);
const Color _rejected = Color(0xFFFF3B3B);
const Color _pending = Color(0xFFFFB800);

// ═══════════════════════════════════════════════════════════════════════════════
//  VERIFICATION RATE DASHBOARD SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class VerificationRateDashboardScreen extends StatefulWidget {
  final int totalReports;
  final int verifiedCount;
  final int rejectedCount;
  final int pendingCount;
  final String timeRange;

  const VerificationRateDashboardScreen({
    super.key,
    required this.totalReports,
    required this.verifiedCount,
    required this.rejectedCount,
    required this.pendingCount,
    required this.timeRange,
  });

  @override
  State<VerificationRateDashboardScreen> createState() =>
      _VerificationRateDashboardScreenState();
}

class _VerificationRateDashboardScreenState
    extends State<VerificationRateDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _chartAnimController;
  late Animation<double> _chartAnim;

  // Derived metrics
  late double verifiedPct;
  late double rejectedPct;
  late double pendingPct;
  late double otherPct;
  late int otherCount;

  @override
  void initState() {
    super.initState();

    final total = widget.totalReports.toDouble();
    verifiedPct = total > 0 ? (widget.verifiedCount / total * 100) : 0;
    rejectedPct = total > 0 ? (widget.rejectedCount / total * 100) : 0;
    pendingPct = total > 0 ? (widget.pendingCount / total * 100) : 0;
    otherCount = widget.totalReports -
        widget.verifiedCount -
        widget.rejectedCount -
        widget.pendingCount;
    if (otherCount < 0) otherCount = 0;
    otherPct = total > 0 ? (otherCount / total * 100) : 0;

    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _chartAnim = CurvedAnimation(
      parent: _chartAnimController,
      curve: Curves.easeOutCubic,
    );
    _chartAnimController.forward();
  }

  @override
  void dispose() {
    _chartAnimController.dispose();
    super.dispose();
  }

  String get _rangeLabel {
    switch (widget.timeRange) {
      case '24H':
        return 'Last 24 Hours';
      case '7D':
        return 'Last 7 Days';
      case '30D':
        return 'Last 30 Days';
      case '1Y':
        return 'Last Year';
      default:
        return widget.timeRange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(context)
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(
                            begin: 0.5,
                            end: 0,
                            curve: Curves.easeOutCubic),
                    const SizedBox(height: 48),
                    _buildTitleSection()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 100.ms)
                        .slideY(
                            begin: 0.5,
                            end: 0,
                            curve: Curves.easeOutCubic),
                    const SizedBox(height: 24),
                    _buildKPIGrid(isMobile),
                    const SizedBox(height: 24),
                    _buildPieChartSection(isMobile)
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 400.ms)
                        .slideY(
                            begin: 0.1,
                            end: 0,
                            curve: Curves.easeOutCubic),
                    const SizedBox(height: 24),
                    _buildBreakdownSection()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 500.ms)
                        .slideY(
                            begin: 0.1,
                            end: 0,
                            curve: Curves.easeOutCubic),
                    const SizedBox(height: 24),
                    _buildDistributionSummary()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 600.ms)
                        .slideY(
                            begin: 0.1,
                            end: 0,
                            curve: Curves.easeOutCubic),
                    const SizedBox(height: 64),
                    _buildFooter()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 1200.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── TOP HEADER ───────────────────────────────────────────────────────────
  Widget _buildTopHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: _fgText, size: 20),
          tooltip: 'Back',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _verified.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.verified_rounded, color: _verified, size: 16),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'VerifyMetrics',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isMobile) ...[
          Container(
            height: 14,
            width: 1,
            color: _border,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Text(
            'Analytics Console',
            style: GoogleFonts.dmMono(
              color: _mutedText,
              fontSize: 12,
            ),
          ),
        ],
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _verified.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _verified,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _rangeLabel,
                style: GoogleFonts.outfit(
                  color: _verified,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── TITLE SECTION ────────────────────────────────────────────────────────
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Rate Analytics',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Report verification status distribution',
          style: GoogleFonts.dmMono(color: _mutedText, fontSize: 11),
        ),
      ],
    );
  }

  // ─── KPI GRID ─────────────────────────────────────────────────────────────
  Widget _buildKPIGrid(bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.5 : 2.0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildKPICard(
          title: 'Total Reports',
          value: widget.totalReports,
          subtitle: 'in $_rangeLabel',
          icon: Icons.assessment_rounded,
          valueColor: _accent,
          bgTint: _accent,
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 100.ms)
            .slideY(begin: 0.2, end: 0),
        _buildKPICard(
          title: 'Verified',
          value: widget.verifiedCount,
          subtitle: '${verifiedPct.toStringAsFixed(1)}% of total',
          icon: Icons.verified_rounded,
          valueColor: _verified,
          bgTint: _verified,
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 180.ms)
            .slideY(begin: 0.2, end: 0),
        _buildKPICard(
          title: 'Rejected',
          value: widget.rejectedCount,
          subtitle: '${rejectedPct.toStringAsFixed(1)}% of total',
          icon: Icons.cancel_rounded,
          valueColor: _rejected,
          bgTint: _rejected,
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 260.ms)
            .slideY(begin: 0.2, end: 0),
        _buildKPICard(
          title: 'Pending',
          value: widget.pendingCount,
          subtitle: '${pendingPct.toStringAsFixed(1)}% of total',
          icon: Icons.pending_actions_rounded,
          valueColor: _pending,
          bgTint: _pending,
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 340.ms)
            .slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required int value,
    required String subtitle,
    required IconData icon,
    required Color valueColor,
    required Color bgTint,
  }) {
    return _HoverKPICard(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: GoogleFonts.dmMono(
                      color: _fgText,
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: bgTint.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: bgTint, size: 12),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedCounter(
                  value: value.toDouble(),
                  style: GoogleFonts.outfit(
                    color: valueColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.dmMono(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── PIE CHART SECTION ────────────────────────────────────────────────────
  Widget _buildPieChartSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification Distribution',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Report status breakdown by category',
                    style: GoogleFonts.dmMono(
                      color: _mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF1C2333), height: 1),
          const SizedBox(height: 32),
          isMobile ? _buildPieChartMobile() : _buildPieChartWide(),
        ],
      ),
    );
  }

  Widget _buildPieChartWide() {
    return Row(
      children: [
        // Pie chart
        Expanded(
          flex: 5,
          child: Center(
            child: AnimatedBuilder(
              animation: _chartAnim,
              builder: (context, child) {
                return SizedBox(
                  width: 220,
                  height: 220,
                  child: CustomPaint(
                    painter: _AnimatedPieChartPainter(
                      segments: _buildSegments(),
                      animationValue: _chartAnim.value,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${verifiedPct.round()}%',
                            style: GoogleFonts.outfit(
                              color: _verified,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'verified',
                            style: GoogleFonts.dmMono(
                              color: _mutedText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 32),
        // Legend
        Expanded(
          flex: 5,
          child: _buildLegend(),
        ),
      ],
    );
  }

  Widget _buildPieChartMobile() {
    return Column(
      children: [
        Center(
          child: AnimatedBuilder(
            animation: _chartAnim,
            builder: (context, child) {
              return SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _AnimatedPieChartPainter(
                    segments: _buildSegments(),
                    animationValue: _chartAnim.value,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${verifiedPct.round()}%',
                          style: GoogleFonts.outfit(
                            color: _verified,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'verified',
                          style: GoogleFonts.dmMono(
                            color: _mutedText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildLegend(),
      ],
    );
  }

  List<_PieSegment> _buildSegments() {
    final segs = <_PieSegment>[];
    if (widget.verifiedCount > 0) {
      segs.add(_PieSegment(_verified, widget.verifiedCount.toDouble(), 'Verified'));
    }
    if (widget.rejectedCount > 0) {
      segs.add(_PieSegment(_rejected, widget.rejectedCount.toDouble(), 'Rejected'));
    }
    if (widget.pendingCount > 0) {
      segs.add(_PieSegment(_pending, widget.pendingCount.toDouble(), 'Pending'));
    }
    if (otherCount > 0) {
      segs.add(_PieSegment(const Color(0xFF2A3548), otherCount.toDouble(), 'Other'));
    }
    if (segs.isEmpty) {
      segs.add(_PieSegment(const Color(0xFF2A3548), 1, 'No Data'));
    }
    return segs;
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem(
          color: _verified,
          label: 'Verified',
          count: widget.verifiedCount,
          pct: verifiedPct,
          icon: Icons.verified_rounded,
        ),
        const SizedBox(height: 16),
        _buildLegendItem(
          color: _rejected,
          label: 'Rejected',
          count: widget.rejectedCount,
          pct: rejectedPct,
          icon: Icons.cancel_rounded,
        ),
        const SizedBox(height: 16),
        _buildLegendItem(
          color: _pending,
          label: 'Pending',
          count: widget.pendingCount,
          pct: pendingPct,
          icon: Icons.pending_actions_rounded,
        ),
        if (otherCount > 0) ...[
          const SizedBox(height: 16),
          _buildLegendItem(
            color: const Color(0xFF2A3548),
            label: 'Other',
            count: otherCount,
            pct: otherPct,
            icon: Icons.help_outline_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int count,
    required double pct,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: _fgText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$count reports',
                style: GoogleFonts.dmMono(
                  color: _mutedText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Text(
            '${pct.toStringAsFixed(1)}%',
            style: GoogleFonts.dmMono(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ─── BREAKDOWN SECTION ────────────────────────────────────────────────────
  Widget _buildBreakdownSection() {
    final items = <_BreakdownItem>[
      _BreakdownItem('Verified', widget.verifiedCount, _verified, Icons.verified_rounded),
      _BreakdownItem('Rejected', widget.rejectedCount, _rejected, Icons.cancel_rounded),
      _BreakdownItem('Pending', widget.pendingCount, _pending, Icons.pending_actions_rounded),
    ];
    if (otherCount > 0) {
      items.add(_BreakdownItem('Other', otherCount, const Color(0xFF2A3548), Icons.help_outline_rounded));
    }

    final maxCount = items.isEmpty
        ? 1
        : items.map((e) => e.count).reduce(math.max).clamp(1, double.infinity).toInt();

    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Status Breakdown',
                  style: GoogleFonts.outfit(
                    color: _fgText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.where((e) => e.count > 0).length} active statuses',
                style: GoogleFonts.dmMono(color: _mutedText, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final widthRatio =
                maxCount > 0 ? item.count / maxCount : 0.0;
            final isMax = item.count == maxCount && item.count > 0;
            return _buildBreakdownRow(item, widthRatio, isMax)
                .animate()
                .fadeIn(delay: (600 + idx * 80).ms, duration: 400.ms)
                .slideX(begin: -0.05, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
      _BreakdownItem item, double widthRatio, bool isMax) {
    return _HoverRow(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(item.icon, color: item.color, size: 13),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.outfit(
                      color: _fgText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isMax)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: item.color.withOpacity(0.3)),
                    ),
                    child: Text(
                      'HIGHEST',
                      style: GoogleFonts.dmMono(
                        color: item.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      .animate(
                          onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.08, 1.08),
                          duration: 1.seconds,
                          curve: Curves.easeInOut),
                Text(
                  item.count.toString(),
                  style: GoogleFonts.dmMono(
                    color: _fgText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item.count == 1 ? 'report' : 'reports',
                  style: GoogleFonts.outfit(color: _mutedText, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: widthRatio),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  backgroundColor: _elevatedPanel,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isMax ? item.color : item.color.withOpacity(0.6),
                  ),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DISTRIBUTION SUMMARY ─────────────────────────────────────────────────
  Widget _buildDistributionSummary() {
    final total = widget.totalReports;
    final verifiedRatio =
        total > 0 ? widget.verifiedCount / total : 0.0;
    final healthLabel = verifiedRatio >= 0.7
        ? 'Excellent'
        : verifiedRatio >= 0.5
            ? 'Good'
            : verifiedRatio >= 0.3
                ? 'Needs Improvement'
                : 'Critical';
    final healthColor = verifiedRatio >= 0.7
        ? _verified
        : verifiedRatio >= 0.5
            ? _pending
            : _rejected;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Health',
            style: GoogleFonts.outfit(
              color: _fgText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (_, progress, __) {
                  return Row(
                    children: [
                      if (verifiedPct > 0)
                        Flexible(
                          flex: (verifiedPct * progress * 10).round().clamp(1, 1000),
                          child: Container(color: _verified),
                        ),
                      if (rejectedPct > 0)
                        Flexible(
                          flex: (rejectedPct * progress * 10).round().clamp(1, 1000),
                          child: Container(color: _rejected),
                        ),
                      if (pendingPct > 0)
                        Flexible(
                          flex: (pendingPct * progress * 10).round().clamp(1, 1000),
                          child: Container(color: _pending),
                        ),
                      if (otherPct > 0)
                        Flexible(
                          flex: (otherPct * progress * 10).round().clamp(1, 1000),
                          child: Container(color: const Color(0xFF2A3548)),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Status: ',
                style: GoogleFonts.dmMono(color: _mutedText, fontSize: 12),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: healthColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: healthColor.withOpacity(0.3)),
                ),
                child: Text(
                  healthLabel,
                  style: GoogleFonts.outfit(
                    color: healthColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  '${(verifiedRatio * 100).toStringAsFixed(1)}% verified',
                  style: GoogleFonts.dmMono(color: _mutedText, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick stat row
          Row(
            children: [
              _buildQuickStat(
                  'Verified-to-Rejected Ratio',
                  widget.rejectedCount > 0
                      ? '${(widget.verifiedCount / widget.rejectedCount).toStringAsFixed(1)}:1'
                      : '∞:1',
                  _verified),
              const SizedBox(width: 16),
              _buildQuickStat(
                  'Pending Queue',
                  widget.pendingCount.toString(),
                  _pending),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _elevatedPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmMono(
                color: _mutedText,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── FOOTER ───────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Center(
      child: Text(
        'Data refreshes every 60 seconds · Timezone: UTC+0',
        style: GoogleFonts.dmMono(color: _mutedText, fontSize: 12),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ANIMATED PIE CHART PAINTER
// ═══════════════════════════════════════════════════════════════════════════════
class _PieSegment {
  final Color color;
  final double value;
  final String label;
  const _PieSegment(this.color, this.value, this.label);
}

class _AnimatedPieChartPainter extends CustomPainter {
  final List<_PieSegment> segments;
  final double animationValue;

  const _AnimatedPieChartPainter({
    required this.segments,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold(0.0, (s, e) => s + e.value);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.28;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    // Draw background track
    canvas.drawCircle(
      center,
      radius - strokeWidth / 2,
      Paint()
        ..color = const Color(0xFF1C2333)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    double startAngle = -math.pi / 2;
    const gap = 0.06;
    final totalSweep = 2 * math.pi * animationValue;

    double accumSweep = 0;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final fullSweep = (seg.value / total) * 2 * math.pi - gap;
      final availableSweep = math.max(0.0, math.min(fullSweep, totalSweep - accumSweep));

      if (availableSweep <= 0) break;

      canvas.drawArc(
        rect,
        startAngle,
        availableSweep,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += fullSweep + gap;
      accumSweep += fullSweep + gap;
    }
  }

  @override
  bool shouldRepaint(_AnimatedPieChartPainter old) =>
      old.animationValue != animationValue || old.segments != segments;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  UTILITY WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _BreakdownItem {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _BreakdownItem(this.label, this.count, this.color, this.icon);
}

class _HoverKPICard extends StatefulWidget {
  final Widget child;
  const _HoverKPICard({required this.child});

  @override
  State<_HoverKPICard> createState() => _HoverKPICardState();
}

class _HoverKPICardState extends State<_HoverKPICard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _HoverRow extends StatefulWidget {
  final Widget child;
  const _HoverRow({required this.child});

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _hovered ? Colors.white.withOpacity(0.03) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: widget.child,
      ),
    );
  }
}

class _AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle style;

  const _AnimatedCounter({required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) {
        return Text(
          v.round().toString(),
          style: style,
        );
      },
    );
  }
}
