import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

// ─── COLOR PALETTE ──────────────────────────────────────────────────────────
const Color _bg = Color(0xFF0F1117);
const Color _cardSurface = Color(0xFF161B26);
const Color _elevatedPanel = Color(0xFF1C2333);
const Color _accent = Color(0xFFF56F2C);
const Color _fgText = Color(0xFFE2E4EB);
const Color _mutedText = Color(0xFF6B7585);
final Color _border = Colors.white.withOpacity(0.07);

class ReportVolumeDashboardScreen extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String timeRange; // '24H', '7D', '1M', '3M'

  const ReportVolumeDashboardScreen({
    super.key, 
    required this.data,
    required this.timeRange,
  });

  @override
  State<ReportVolumeDashboardScreen> createState() => _ReportVolumeDashboardScreenState();
}

class _ReportVolumeDashboardScreenState extends State<ReportVolumeDashboardScreen> {
  late int totalReports;
  late int peakCount;
  late String peakLabel;
  late int activeUnits;
  late double avgPerActiveUnit;
  late List<Map<String, dynamic>> activeData;

  bool _showAllActiveHours = false;

  @override
  void initState() {
    super.initState();
    _calculateMetrics();
  }

  void _calculateMetrics() {
    totalReports = 0;
    peakCount = -1;
    peakLabel = 'N/A';
    activeUnits = 0;
    activeData = [];

    for (var d in widget.data) {
      final count = (d['count'] as num).toInt();
      final label = d['label'] as String;

      totalReports += count;
      if (count > peakCount) {
        peakCount = count;
        peakLabel = label;
      }
      if (count > 0) {
        activeUnits++;
        activeData.add({...d, 'count': count});
      }
    }

    if (activeUnits > 0) {
      avgPerActiveUnit = totalReports / activeUnits;
    } else {
      avgPerActiveUnit = 0;
    }
  }

  String get _unitName {
    if (widget.timeRange == '24H') return 'Hour';
    if (widget.timeRange == '30D') return 'Week';
    if (widget.timeRange == '1Y') return 'Month';
    return 'Day';
  }

  String get _unitNamePlural {
    if (widget.timeRange == '24H') return 'Hours';
    if (widget.timeRange == '30D') return 'Weeks';
    if (widget.timeRange == '1Y') return 'Months';
    return 'Days';
  }

  String get _unitAbbr {
    if (widget.timeRange == '24H') return 'Hr';
    if (widget.timeRange == '30D') return 'Wk';
    if (widget.timeRange == '1Y') return 'Mo';
    return 'Day';
  }

  String get _breakdownLabel {
    if (widget.timeRange == '24H') return 'Hourly breakdown';
    if (widget.timeRange == '7D') return 'Daily breakdown';
    if (widget.timeRange == '30D') return 'Weekly breakdown';
    if (widget.timeRange == '1Y') return 'Monthly breakdown';
    return 'Detailed breakdown';
  }

  @override
  Widget build(BuildContext context) {
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
                        .slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 48),
                    _buildTitleSection()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 100.ms)
                        .slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 24),
                    _buildKPIGrid(MediaQuery.of(context).size.width < 600),
                    const SizedBox(height: 24),
                    _buildChartSection(context)
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 400.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 24),
                    _buildBreakdownSection()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 500.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
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
            color: _accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.show_chart, color: _accent, size: 16),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'ReportMetrics',
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
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(6),
            color: _cardSurface,
          ),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download_outlined, size: 14, color: _mutedText),
                  const SizedBox(width: 6),
                  Text(
                    'Export',
                    style: GoogleFonts.outfit(color: _mutedText, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Volume Analytics',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _breakdownLabel,
          style: GoogleFonts.dmMono(color: _mutedText, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildKPIGrid(bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 1.5 : 2.0, // Fixed aspect ratio to avoid overflow
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildKPICard(
          title: 'Total Reports',
          value: totalReports.toDouble(),
          subtitle: 'across all ${_unitNamePlural.toLowerCase()}',
          icon: Icons.show_chart,
          valueColor: _accent,
          isOrangeIcon: true,
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
        _buildKPICard(
          title: 'Peak $_unitName',
          valueString: peakLabel,
          subtitle: '$peakCount reports logged',
          icon: Icons.access_time,
        ).animate().fadeIn(duration: 500.ms, delay: 180.ms).slideY(begin: 0.2, end: 0),
        _buildKPICard(
          title: 'Active $_unitNamePlural',
          value: activeUnits.toDouble(),
          subtitle: 'of ${widget.data.length} had activity',
          icon: Icons.timeline,
        ).animate().fadeIn(duration: 500.ms, delay: 260.ms).slideY(begin: 0.2, end: 0),
        _buildKPICard(
          title: 'Avg / Active $_unitAbbr',
          value: avgPerActiveUnit,
          isDouble: true,
          subtitle: 'reports per ${_unitName.toLowerCase()}',
          icon: Icons.check_circle_outline,
        ).animate().fadeIn(duration: 500.ms, delay: 340.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    double? value,
    String? valueString,
    bool isDouble = false,
    required String subtitle,
    required IconData icon,
    Color valueColor = Colors.white,
    bool isOrangeIcon = false,
  }) {
    return HoverKPICard(
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
                    style: GoogleFonts.dmMono(color: _fgText, fontSize: 11, letterSpacing: 1.0, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isOrangeIcon ? _accent.withOpacity(0.15) : _elevatedPanel,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: isOrangeIcon ? _accent : _mutedText, size: 12),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value != null)
                  AnimatedCounter(
                    value: value,
                    isDouble: isDouble,
                    style: GoogleFonts.outfit(
                      color: valueColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    valueString ?? '',
                    style: GoogleFonts.outfit(
                      color: valueColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.dmMono(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
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

  Widget _buildChartSection(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280, // Compact height
      padding: const EdgeInsets.all(20),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Volume by $_unitName', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Reports submitted per ${_unitName.toLowerCase()} window', style: GoogleFonts.dmMono(color: _mutedText, fontSize: 11), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Live', style: GoogleFonts.outfit(color: _accent, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF1C2333), height: 1),
          const SizedBox(height: 32),
          Expanded(
            child: _CustomDashboardBarChart(
              data: widget.data,
              peakCount: peakCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection() {
    final hasMore = activeData.length > 6;
    final displayData = _showAllActiveHours || !hasMore
        ? activeData
        : activeData.sublist(activeData.length - 6);

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
                  'Detailed Breakdown',
                  style: GoogleFonts.outfit(color: _fgText, fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$activeUnits active ${_unitNamePlural.toLowerCase()}',
                style: GoogleFonts.dmMono(color: _mutedText, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activeData.isEmpty)
            Text(
              'No reports recorded in the past 24 hours.',
              style: GoogleFonts.outfit(color: _mutedText),
            )
          else ...[
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  ...displayData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final d = entry.value;
                    final count = d['count'] as int;
                    final isPeak = count == peakCount && count > 0;
                    final widthRatio = peakCount > 0 ? count / peakCount : 0.0;
                    return _buildBreakdownRow(d['label'], count, widthRatio, isPeak)
                        .animate()
                        .fadeIn(delay: (600 + index * 60).ms, duration: 400.ms)
                        .slideX(begin: -0.05, end: 0);
                  }),
                ],
              ),
            ),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showAllActiveHours = !_showAllActiveHours),
                    child: Text(
                      _showAllActiveHours ? 'Show Less' : 'See More',
                      style: GoogleFonts.outfit(color: _accent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              )
          ]
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, int count, double widthRatio, bool isPeak) {
    return HoverRow(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                label,
                style: GoogleFonts.dmMono(color: _fgText, fontSize: 14),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedProgressBar(
                      widthRatio: widthRatio,
                      color: isPeak ? _accent : _accent.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isPeak)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _accent.withOpacity(0.3)),
                ),
                child: Text(
                  'PEAK',
                  style: GoogleFonts.dmMono(color: _accent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 1.seconds, curve: Curves.easeInOut),
            Text(
              count.toString(),
              style: GoogleFonts.dmMono(color: _fgText, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Text(
              count == 1 ? 'report' : 'reports',
              style: GoogleFonts.outfit(color: _mutedText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'Data refreshes every 60 seconds · Timezone: UTC+0',
        style: GoogleFonts.dmMono(color: _mutedText, fontSize: 12),
      ),
    );
  }
}

// ─── CUSTOM CHART PAINTER ───────────────────────────────────────────────────

class _CustomDashboardBarChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final int peakCount;

  const _CustomDashboardBarChart({required this.data, required this.peakCount});

  @override
  State<_CustomDashboardBarChart> createState() => _CustomDashboardBarChartState();
}

class _CustomDashboardBarChartState extends State<_CustomDashboardBarChart> {
  int? hoveredIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double yAxisWidth = 30.0;
        final double availableWidth = constraints.maxWidth - yAxisWidth;
        
        // Show exactly 12 bars on screen if data length is >= 12
        final int visibleBars = 12;
        final double widthPerBar = availableWidth / math.min(visibleBars, widget.data.isEmpty ? 1 : widget.data.length);
        final double totalBarsWidth = widthPerBar * widget.data.length;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          builder: (context, animValue, child) {
            return Stack(
              children: [
                // 1. Background Grid & Y-Axis
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _YAxisAndGridPainter(
                    peakCount: widget.peakCount,
                    yAxisWidth: yAxisWidth,
                  ),
                ),
                // 2. Scrollable Bars
                Padding(
                  padding: EdgeInsets.only(left: yAxisWidth, bottom: 8), // Padding for scrollbar
                  child: RawScrollbar(
                    controller: _scrollController,
                    thumbColor: Colors.white24, // Make it actually visible
                    radius: const Radius.circular(4),
                    thickness: 8,
                    thumbVisibility: true, // Always show so user knows it's scrollable
                    interactive: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: MouseRegion(
                        onHover: (e) {
                          final idx = (e.localPosition.dx / widthPerBar).floor();
                          if (idx >= 0 && idx < widget.data.length) {
                            if (hoveredIndex != idx) {
                              setState(() => hoveredIndex = idx);
                            }
                          }
                        },
                        onExit: (e) {
                          setState(() => hoveredIndex = null);
                        },
                        child: CustomPaint(
                          size: Size(totalBarsWidth, constraints.maxHeight),
                          painter: _BarsPainter(
                            data: widget.data,
                            peakCount: widget.peakCount,
                            hoveredIndex: hoveredIndex,
                            animationProgress: animValue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _YAxisAndGridPainter extends CustomPainter {
  final int peakCount;
  final double yAxisWidth;

  _YAxisAndGridPainter({
    required this.peakCount,
    required this.yAxisWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int yMax = ((peakCount / 4).ceil() * 4);
    if (yMax < 12) yMax = 12;
    int step = yMax ~/ 4;

    final chartRect = Rect.fromLTWH(yAxisWidth, 0, size.width - yAxisWidth, size.height - 36);

    final gridPaint = Paint()
      ..color = _border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
      
    for (int i = 0; i <= 4; i++) {
      final val = i * step;
      final y = chartRect.bottom - (i * (chartRect.height / 4));
      
      final tp = TextPainter(
        text: TextSpan(
          text: '$val',
          style: GoogleFonts.dmMono(color: _mutedText, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(0, y - (tp.height / 2)));

      canvas.drawLine(Offset(yAxisWidth, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _YAxisAndGridPainter oldDelegate) {
    return oldDelegate.peakCount != peakCount;
  }
}

class _BarsPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final int peakCount;
  final int? hoveredIndex;
  final double animationProgress;

  _BarsPainter({
    required this.data,
    required this.peakCount,
    this.hoveredIndex,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int yMax = ((peakCount / 4).ceil() * 4);
    if (yMax < 12) yMax = 12;

    final chartRect = Rect.fromLTWH(0, 0, size.width, size.height - 36);
    final barWidth = 36.0;
    final spacing = size.width / data.length;

    for (int i = 0; i < data.length; i++) {
      final count = (data[i]['count'] as num).toInt();
      final isHovered = hoveredIndex == i;
      final isPeak = count == peakCount && count > 0;

      final x = (i * spacing) + (spacing / 2) - (barWidth / 2);
      
      final double startTime = (i * 30.0) / 1500.0;
      final double localDuration = 600.0 / 1500.0;
      
      double barProgress = 0.0;
      if (animationProgress >= startTime) {
        barProgress = (animationProgress - startTime) / localDuration;
        if (barProgress > 1.0) barProgress = 1.0;
      }
      
      barProgress = 1.0 - math.pow(1.0 - barProgress, 3);
      if (barProgress < 0.0) barProgress = 0.0;

      final barHeight = count > 0 ? (count / yMax) * chartRect.height * barProgress : 0.0;
      final finalHeight = count > 0 ? math.max(barHeight, 4.0) : 4.0 * barProgress;
      final finalY = chartRect.bottom - finalHeight;

      Color color = Colors.white10;
      if (count > 0) {
        color = isPeak ? _accent : _accent.withOpacity(0.4);
        if (isHovered) color = _accent;
      }

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, finalY, barWidth, finalHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, Paint()..color = color);

      if (isHovered && count > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$count',
            style: GoogleFonts.dmMono(color: _fgText, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x + (barWidth / 2) - (tp.width / 2), finalY - 20));
      }

      final label = data[i]['label'] as String;
      final tpLabel = TextPainter(
        text: TextSpan(
          text: label,
          style: GoogleFonts.dmMono(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      );
      tpLabel.layout();
      tpLabel.paint(canvas, Offset(x + (barWidth / 2) - (tpLabel.width / 2), chartRect.bottom + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex || 
           oldDelegate.data != data || 
           oldDelegate.animationProgress != animationProgress;
  }
}

// ─── ANIMATION HELPERS ──────────────────────────────────────────────────────

class AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle style;
  final bool isDouble;

  const AnimatedCounter({
    Key? key,
    required this.value,
    required this.style,
    this.isDouble = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        final displayString = isDouble ? val.toStringAsFixed(1) : val.toInt().toString();
        return Text(displayString, style: style);
      },
    );
  }
}

class HoverKPICard extends StatefulWidget {
  final Widget child;
  const HoverKPICard({Key? key, required this.child}) : super(key: key);

  @override
  State<HoverKPICard> createState() => _HoverKPICardState();
}

class _HoverKPICardState extends State<HoverKPICard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}

class HoverRow extends StatefulWidget {
  final Widget child;
  const HoverRow({Key? key, required this.child}) : super(key: key);

  @override
  State<HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<HoverRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack, // Mimics stiffness 300 spring
        transform: Matrix4.translationValues(_isHovered ? 4 : 0, 0, 0),
        child: widget.child,
      ),
    );
  }
}

class AnimatedProgressBar extends StatefulWidget {
  final double widthRatio;
  final Color color;
  const AnimatedProgressBar({Key? key, required this.widthRatio, required this.color}) : super(key: key);

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        height: 6,
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          height: 6,
          width: _visible ? constraints.maxWidth * widget.widthRatio : 0,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
    });
  }
}
