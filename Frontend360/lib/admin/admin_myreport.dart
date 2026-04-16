import 'package:disaster360/admin/admin_report_details.dart';
import 'package:disaster360/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/providers/report_provider.dart';

// ─── Max content width — centers everything on ultra-wide screens ─────────────
const double _kMaxContentWidth = 1320.0;

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  String _activeFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<String> _filters = ['All', 'Pending', 'Verified', 'Closed'];

  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().fetchReports();
    });
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _entryController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  List<AdminReportData> get _filteredReports {
    final reportProvider = context.watch<ReportProvider>();
    final allReports = reportProvider.reports.map((m) {
      final s = m.status.isEmpty ? 'Pending' : (m.status.toLowerCase() == 'pending' ? 'Pending' : m.status);
      final capStatus = s[0].toUpperCase() + s.substring(1);
      return AdminReportData(
        reportId: 'RPT-${m.id}',
        status: capStatus,
        type: m.disasterType,
        title: '${m.disasterType} — ${m.title}',
        description: m.description,
        date: m.createdAt,
        location: m.title,
        lat: '${m.latitude.toStringAsFixed(4)}°N',
        lng: '${m.longitude.toStringAsFixed(4)}°E',
        reporter: m.userId.length > 8 ? m.userId.substring(0, 8) : m.userId,
        trustScore: 80,
        upvotes: m.likes,
        downvotes: m.dislikes,
        photoCount: 0,
      );
    }).toList();

    return allReports.where((r) {
      final matchesFilter = _activeFilter == 'All' || r.status.toLowerCase() == _activeFilter.toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty ||
          r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.reportId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.location.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  // Breakpoints: mobile < 680  |  tablet 680-1099  |  desktop >= 1100
  int _cols(double w) {
    if (w >= 1100) return 3;
    if (w >= 680) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final int cols = _cols(screenW);
    final double hPad = cols == 1 ? 16.0 : 24.0;

    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header centered within max content width
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _kMaxContentWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Reports',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _AnimatedSearchBar(
                          controller: _searchController,
                          onChanged:
                              (val) => setState(() => _searchQuery = val),
                        ),
                        const SizedBox(height: 14),
                        _FilterChipRow(
                          filters: _filters,
                          activeFilter: _activeFilter,
                          onSelect: (f) => setState(() => _activeFilter = f),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),

              // Body
              Expanded(
                child:
                    _filteredReports.isEmpty
                        ? const Center(
                          child: Text(
                            'No reports found.',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        )
                        : _ReportBody(
                          reports: _filteredReports,
                          cols: cols,
                          hPad: hPad,
                          onTap: _navigateToDetail,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(AdminReportData report) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (_, animation, __) => AdminReportDetailScreen(report: report),
        transitionsBuilder:
            (_, animation, __, child) => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }
}

// ─── Report Body ──────────────────────────────────────────────────────────────
// Owns scrolling + explicit width calculation.
// Using LayoutBuilder gives us a guaranteed finite maxWidth so every card
// child gets a real pixel width — root fix for all unbounded-width overflows.
class _ReportBody extends StatelessWidget {
  final List<AdminReportData> reports;
  final int cols;
  final double hPad;
  final ValueChanged<AdminReportData> onTap;

  const _ReportBody({
    required this.reports,
    required this.cols,
    required this.hPad,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (cols == 1) {
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder:
            (_, i) => _StaggeredCard(
              index: i,
              child: _AdminReportCard(
                report: reports[i],
                onTap: () => onTap(reports[i]),
              ),
            ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Cap to max content width for ultra-wide centering
        final double availW = constraints.maxWidth.clamp(
          0.0,
          _kMaxContentWidth,
        );
        const double gap = 14.0;
        final double innerW = availW - hPad * 2;
        // Explicit per-card width — eliminates unbounded-width RenderFlex errors
        final double cardW = (innerW - gap * (cols - 1)) / cols;
        final double extraPad = ((constraints.maxWidth - availW) / 2).clamp(
          0.0,
          double.infinity,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad + extraPad, 0, hPad + extraPad, 24),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: List.generate(
              reports.length,
              (i) => SizedBox(
                width: cardW,
                child: _StaggeredCard(
                  index: i,
                  child: _AdminReportCard(
                    report: reports[i],
                    onTap: () => onTap(reports[i]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Staggered Card Wrapper ───────────────────────────────────────────────────
class _StaggeredCard extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredCard({required this.index, required this.child});

  @override
  State<_StaggeredCard> createState() => _StaggeredCardState();
}

class _StaggeredCardState extends State<_StaggeredCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    final delay = Duration(milliseconds: (widget.index * 60).clamp(0, 300));
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

// ─── Animated Search Bar ──────────────────────────────────────────────────────
class _AnimatedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _AnimatedSearchBar({required this.controller, required this.onChanged});

  @override
  State<_AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<_AnimatedSearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _focused ? AppColors.orange.withOpacity(0.7) : AppColors.border,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow:
            _focused
                ? [
                  BoxShadow(
                    color: AppColors.orange.withOpacity(0.08),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
                : [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.search_rounded,
              key: ValueKey(_focused),
              color: _focused ? AppColors.orange : Colors.white38,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Focus(
              onFocusChange: (v) => setState(() => _focused = v),
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search reports...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chip Row ──────────────────────────────────────────────────────────
class _FilterChipRow extends StatelessWidget {
  final List<String> filters;
  final String activeFilter;
  final ValueChanged<String> onSelect;

  const _FilterChipRow({
    required this.filters,
    required this.activeFilter,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            filters
                .map(
                  (f) => _AnimatedFilterChip(
                    label: f,
                    isActive: activeFilter == f,
                    onTap: () => onSelect(f),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _AnimatedFilterChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _AnimatedFilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_AnimatedFilterChip> createState() => _AnimatedFilterChipState();
}

class _AnimatedFilterChipState extends State<_AnimatedFilterChip> {
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
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color:
                widget.isActive
                    ? AppColors.orange
                    : _hovered
                    ? AppColors.orange.withOpacity(0.12)
                    : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  widget.isActive
                      ? AppColors.orange
                      : _hovered
                      ? AppColors.orange.withOpacity(0.4)
                      : AppColors.border,
              width: 1,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              color:
                  widget.isActive
                      ? Colors.white
                      : _hovered
                      ? AppColors.orange
                      : Colors.white54,
              fontSize: _hovered && !widget.isActive ? 13.5 : 13,
              fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w400,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

// ─── Admin Report Card ────────────────────────────────────────────────────────
class _AdminReportCard extends StatefulWidget {
  final AdminReportData report;
  final VoidCallback onTap;
  const _AdminReportCard({required this.report, required this.onTap});

  @override
  State<_AdminReportCard> createState() => _AdminReportCardState();
}

class _AdminReportCardState extends State<_AdminReportCard> {
  String _cardState = 'pending';
  bool _hovered = false;

  void _onVerify() => Navigator.push(
    context,
    _pageRoute(
      AdminReportDetailScreen(
        report: widget.report,
        initialDecisionState: 'verified',
      ),
    ),
  );

  void _onReject() {
    final TextEditingController rc = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => RejectionBottomSheet(
            report: widget.report,
            reasonController: rc,
            onConfirmReject: (reason) {
              Navigator.pop(context);
              setState(() => _cardState = 'rejected');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.report.reportId} rejected.'),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
    );
  }

  void _onReview() => Navigator.push(
    context,
    _pageRoute(AdminReportDetailScreen(report: widget.report)),
  );

  PageRoute _pageRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, a, __) => page,
    transitionsBuilder:
        (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
            child: child,
          ),
        ),
    transitionDuration: const Duration(milliseconds: 300),
  );

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final bool isPending =
        report.status == 'Pending' && _cardState == 'pending';
    final bool isVerified = _cardState == 'verified';
    final bool isRejected = _cardState == 'rejected';
    final bool reviewOnly = !isPending;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              _hovered
                  ? AppColors.bgSurface.withOpacity(0.92)
                  : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                _hovered
                    ? AppColors.orange.withOpacity(0.35)
                    : AppColors.border,
            width: 1,
          ),
          boxShadow:
              _hovered
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: ID + badge + timestamp
            // FIX: Flexible on timestamp prevents RenderFlex overflow
            // on narrow grid cards where combined content is too wide.
            Row(
              children: [
                Text(
                  '#${report.reportId}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                _StatusBadge(
                  status:
                      isVerified
                          ? 'Verified'
                          : isRejected
                          ? 'Rejected'
                          : report.status,
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    '10 min ago',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              report.type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),

            Text(
              report.location,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 8),

            Text(
              report.description,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Image placeholders
            if (report.photoCount > 0) ...[
              _ImagePlaceholderRow(photoCount: report.photoCount),
              const SizedBox(height: 10),
            ],

            // Votes
            Row(
              children: [
                const Icon(
                  Icons.thumb_up_alt_outlined,
                  color: AppColors.success,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${report.upvotes}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.thumb_down_alt_outlined,
                  color: AppColors.danger,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${report.downvotes}',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Action buttons
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: _CardActionButton(
                      label: 'Verify',
                      icon: Icons.check_rounded,
                      color: AppColors.success,
                      filled: true,
                      onTap: _onVerify,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CardActionButton(
                      label: 'Reject',
                      icon: Icons.close_rounded,
                      color: AppColors.danger,
                      filled: true,
                      onTap: _onReject,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CardActionButton(
                      label: 'Review',
                      icon: Icons.remove_red_eye_outlined,
                      color: Colors.white54,
                      filled: false,
                      onTap: _onReview,
                    ),
                  ),
                ],
              ),

            if (reviewOnly)
              _CardActionButton(
                label: 'Review',
                icon: Icons.remove_red_eye_outlined,
                color: Colors.white60,
                filled: false,
                onTap: _onReview,
                fullWidth: true,
              ),

            if (isVerified) ...[
              const SizedBox(height: 10),
              _StatusBanner(
                icon: Icons.verified_rounded,
                color: AppColors.success,
                message: 'Verified — assign rescue team in detail view.',
              ),
            ],
            if (isRejected) ...[
              const SizedBox(height: 10),
              _StatusBanner(
                icon: Icons.cancel_rounded,
                color: AppColors.danger,
                message: 'This report has been rejected.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Image Placeholder Row ────────────────────────────────────────────────────
// 140px height = passport-photo visible size, clearly readable at a glance.
// Up to 3 tiles. If photoCount > 3, last tile shows "+N more" overlay.
// 1.5px border visible on every tile as requested.
class _ImagePlaceholderRow extends StatelessWidget {
  final int photoCount;
  const _ImagePlaceholderRow({required this.photoCount});

  @override
  Widget build(BuildContext context) {
    const int maxVisible = 3;
    final int visible = photoCount.clamp(1, maxVisible);
    final int extra = photoCount > maxVisible ? photoCount - maxVisible : 0;

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(visible, (i) {
          final bool isLast = i == visible - 1 && extra > 0;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < visible - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.image_rounded,
                      color: Colors.white.withOpacity(0.20),
                      size: 40,
                    ),
                    Positioned(
                      bottom: 8,
                      child: Text(
                        'Photo ${i + 1}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.28),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (isLast)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.60),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_library_rounded,
                                  color: Colors.white70,
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '+$extra more',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Status Banner ────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Action Button ───────────────────────────────────────────────────────
class _CardActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  final bool fullWidth;

  const _CardActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  State<_CardActionButton> createState() => _CardActionButtonState();
}

class _CardActionButtonState extends State<_CardActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _pressed ? 0.96 : (_hovered ? 1.02 : 1.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 130),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: widget.fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color:
                  widget.filled
                      ? widget.color.withOpacity(_hovered ? 0.28 : 0.18)
                      : _hovered
                      ? widget.color.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    widget.filled
                        ? widget.color.withOpacity(_hovered ? 0.7 : 0.5)
                        : _hovered
                        ? widget.color.withOpacity(0.5)
                        : AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.color, size: 13),
                const SizedBox(width: 5),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: TextStyle(
                    color: widget.color,
                    fontSize: _hovered ? 12.5 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
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
      case 'Verified':
      case 'Controlled':
        bg = AppColors.success.withOpacity(0.15);
        text = AppColors.success;
        break;
      case 'Closed':
        bg = AppColors.info.withOpacity(0.15);
        text = AppColors.info;
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



// you as a professonal forntend developer and best coder give me 3 sized responsive screens ....1 its alredy in mobile screen responsive, anothe is tablet and last is desktop form....it must be responsive and overflow error free....and .image must be double of passport size photo (which asked when we fill form in goverment sectors)   in that report if image is clicked show it in full screen form...... ....and button , links , cards etc must be in basic animation and transition and hand hoverd cursor .....clean and managed
