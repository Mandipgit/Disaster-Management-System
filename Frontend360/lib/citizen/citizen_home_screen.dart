import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/providers/report_provider.dart';
import 'package:disaster360/providers/auth_provider.dart';
import 'package:disaster360/citizen/citizen_profile_screen.dart';
import 'package:disaster360/citizen/citizen_my_reports.dart';
import 'package:disaster360/services/map_screen.dart';
import 'package:disaster360/colors.dart';
import 'package:disaster360/services/fab_add_report.dart';
import 'package:disaster360/services/notification_alert.dart';
import 'package:disaster360/citizen/citizen_report_detail_screen.dart';

class AlertData {
  final String title;
  final String date;
  final String location;
  final String status;
  final Color dotColor;
  final String reportId;
  final String description;
  final String lat;
  final String lng;
  final String reporter;
  final int upvotes;
  final int downvotes;
  final int photos;
  final String type;
  final String currentStatus;

  const AlertData({
    required this.title,
    required this.date,
    required this.location,
    required this.status,
    required this.dotColor,
    required this.reportId,
    required this.description,
    required this.lat,
    required this.lng,
    required this.reporter,
    required this.upvotes,
    required this.downvotes,
    required this.photos,
    required this.type,
    required this.currentStatus,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

class ReportModelMock {
  final String title;
  final String date;
  final String location;
  final String status;
  final Color dotColor;
  final String reportId;
  final String description;
  final String lat;
  final String lng;
  final String reporter;
  final int upvotes;
  final int downvotes;
  final int photos;
  final String type;
  final String currentStatus;

  const ReportModelMock({
    required this.title,
    required this.date,
    required this.location,
    required this.status,
    required this.dotColor,
    required this.reportId,
    required this.description,
    required this.lat,
    required this.lng,
    required this.reporter,
    required this.upvotes,
    required this.downvotes,
    required this.photos,
    required this.type,
    required this.currentStatus,
  });
}

/// Mutable wrapper for each card — upvotes/downvotes change on tap
class _ReportCardModel {
  final ReportModelMock alert;
  final List<String> tags;
  int upvotes;
  int downvotes;
  // -1 = downvoted, 0 = none, 1 = upvoted
  int voteState;

  _ReportCardModel({required this.alert, required this.tags})
    : upvotes = alert.upvotes,
      downvotes = alert.downvotes,
      voteState = 0;
}

class _NavData {
  final IconData icon;
  final String label;
  const _NavData(this.icon, this.label);
}

// ══════════════════════════════════════════════════════════════════════════════
//  SORT ORDER FOR STATUS
// ══════════════════════════════════════════════════════════════════════════════

int _statusSortOrder(String status) {
  switch (status) {
    case 'Pending':
      return 0;
    case 'Verified':
      return 1;
    case 'In Progress':
      return 2;
    case 'Controlled':
      return 3;
    case 'Rejected':
      return 4;
    default:
      return 5;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CITIZEN HOME SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  String _selectedHomeFilter = 'All';
  final List<String> _homeFilters = [
    'All',
    'My Reports',
    'Pending',
    'On Rescue',
    'Verified',
    'Fire',
    'Landslide',
    'Road Blockage',
    'Flood',
    'Earthquake'
  ];

  String _selectedSortOption = 'Date';
  final List<String> _sortOptions = [
    'Date',
    'Severity',
    'Most Reported'
  ];

  int _activeNav = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: IndexedStack(
        index: _activeNav,
        children: [
          _buildHomeTab(),
          const CitizenMyReportsScreen(),
          const DisasterMapScreen(),
          const CitizenProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportDisasterScreen()),
              ),
          backgroundColor: AppColors.orange,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        SafeArea(bottom: false, child: _buildHeader()),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.orange,
            backgroundColor: AppColors.bgSurface,
            onRefresh: () async {
              await context.read<ReportProvider>().fetchReports();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCards(),
                  const SizedBox(height: 28),
                  _buildFilterAndSortButtons(context),
                  _buildReportCardsSection(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── FIXED HEADER (only shown on Home screen) ─────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.bgPrimary,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DISASTER360',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Namaste, ${context.watch<AuthProvider>().user?.fullName ?? 'Citizen'}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
            child: Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.bgDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── STAT CARDS ──────────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    final reports = context.watch<ReportProvider>().reports;
    final pending = reports.where((r) => r.status.toLowerCase().contains('pending')).length;
    final inProgress = reports.where((r) => r.status.toLowerCase().contains('progress')).length;
    final controlled = reports.where((r) => r.status.toLowerCase().contains('controlled') || r.status.toLowerCase().contains('verified')).length;
    return Row(
      children: [
        _StatCard(
          value: '$pending',
          label: 'Pending',
          valueColor: AppColors.warning,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '$inProgress',
          label: 'In Progress',
          valueColor: AppColors.orange,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '$controlled',
          label: 'Controlled',
          valueColor: AppColors.success,
        ),
      ],
    );
  }


  Widget _buildFilterAndSortButtons(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showFilterBottomSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list_rounded, color: AppColors.orange, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _selectedHomeFilter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _showSortBottomSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.sort_rounded, color: AppColors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedSortOption,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sort By',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _sortOptions.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (ctx, index) {
                    final option = _sortOptions[index];
                    final isSelected = option == _selectedSortOption;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? AppColors.orange : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.orange, size: 22)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedSortOption = option);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Filter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _homeFilters.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (ctx, index) {
                    final filter = _homeFilters[index];
                    final isSelected = filter == _selectedHomeFilter;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? AppColors.orange : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.orange, size: 22)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedHomeFilter = filter);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── REPORT CARDS SECTION ────────────────────────────────────────────────────

  List<ReportModel> _getFilteredReports(BuildContext context) {
    final all = context.watch<ReportProvider>().reports;
    List<ReportModel> filtered = [];

    if (_selectedHomeFilter == 'All') {
      filtered = List.from(all);
    } else if (_selectedHomeFilter == 'My Reports') {
      final auth = context.read<AuthProvider>();
      filtered = all.where((r) => r.userId == auth.user?.id).toList();
    } else if (['Pending', 'On Rescue', 'Verified'].contains(_selectedHomeFilter)) {
      if (_selectedHomeFilter == 'On Rescue') {
         filtered = all.where((r) => r.status.toLowerCase().contains('progress')).toList();
      } else {
         filtered = all.where((r) => r.status == _selectedHomeFilter).toList();
      }
    } else {
      // Type filters
      filtered = all.where((r) => r.disasterType == _selectedHomeFilter).toList();
    }

    // Sort rules
    if (_selectedSortOption == 'Severity') {
      filtered.sort((a, b) => _getSeverityScore(b.severity).compareTo(_getSeverityScore(a.severity)));
    } else if (_selectedSortOption == 'Most Reported') {
      filtered.sort((a, b) => b.submissions.length.compareTo(a.submissions.length));
    } else {
      // Default: Date (Recent to oldest)
      filtered.sort((a, b) {
        DateTime dateA = DateTime.tryParse(a.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
        DateTime dateB = DateTime.tryParse(b.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA); 
      });
    }

    return filtered;
  }

  int _getSeverityScore(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return 4;
      case 'high': return 3;
      case 'medium': return 2;
      case 'low': return 1;
      default: return 0;
    }
  }

  Widget _buildReportCardsSection(BuildContext context) {
    final reports = _getFilteredReports(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedSortOption == 'Most Reported'
              ? 'HOT REPORTS'
              : 'RECENT REPORTS',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 12),
        ...reports.map((report) {
          return _ReportCard(
            key: ValueKey(report.id.toString()),
            report: report,
            animationDelay: Duration(milliseconds: 60 * reports.indexOf(report)),
            onUpvote: () => context.read<ReportProvider>().reactToReport(report.id, 'LIKE'),
            onDownvote: () => context.read<ReportProvider>().reactToReport(report.id, 'DISLIKE'),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── BOTTOM NAV ──────────────────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      _NavData(Icons.home_rounded, 'Home'),
      _NavData(Icons.warning_amber_rounded, 'Reports'),
      _NavData(Icons.map_outlined, 'Map'),
      _NavData(Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          return _AnimatedNavItem(
            icon: items[i].icon,
            label: items[i].label,
            isActive: _activeNav == i,
            onTap: () => setState(() => _activeNav = i),
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ANIMATED NAV ITEM
// ══════════════════════════════════════════════════════════════════════════════

class _AnimatedNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.22), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.22, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_AnimatedNavItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) _bounceCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: widget.isActive ? 76 : 56,
        height: 54,
        decoration: BoxDecoration(
          color:
              widget.isActive
                  ? AppColors.orange.withOpacity(0.15)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border:
              widget.isActive
                  ? Border.all(
                    color: AppColors.orange.withOpacity(0.25),
                    width: 1,
                  )
                  : null,
        ),
        child: ScaleTransition(
          scale: _bounceAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder:
                    (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  widget.icon,
                  key: ValueKey('${widget.icon}_${widget.isActive}'),
                  color: widget.isActive ? AppColors.orange : Colors.white38,
                  size: widget.isActive ? 24 : 22,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: widget.isActive ? AppColors.orange : Colors.white38,
                  fontSize: widget.isActive ? 10.5 : 10,
                  fontWeight:
                      widget.isActive ? FontWeight.w700 : FontWeight.w400,
                  decoration: TextDecoration.none,
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
//  FULL-SCREEN IMAGE VIEWER OVERLAY (FIXED: full width & height)
// ══════════════════════════════════════════════════════════════════════════════

class ImageViewerOverlay extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;
  final String reportId;

  const ImageViewerOverlay({
    required this.mediaUrls,
    required this.initialIndex,
    required this.reportId,
  });

  @override
  State<ImageViewerOverlay> createState() => _ImageViewerOverlayState();
}

class _ImageViewerOverlayState extends State<ImageViewerOverlay>
    with SingleTickerProviderStateMixin {
  late PageController _pageCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  int _currentIndex = 0;

  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    _focusNode = FocusNode()..requestFocus();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _close() {
    _fadeCtrl.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              if (_currentIndex > 0) {
                _pageCtrl.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              if (_currentIndex < widget.mediaUrls.length - 1) {
                _pageCtrl.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              _close();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
        children: [
          // Blurred + darkened background
          GestureDetector(
            onTap: _close,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.88)),
            ),
          ),

          // Full-screen swipeable images – now edge‑to‑edge
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.mediaUrls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) {
              return Container(
                color: AppColors.bgDark,
                child: Center(
                  child: Image.network(
                    widget.mediaUrls[i],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white.withOpacity(0.2),
                          size: 72,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Error loading image',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Next/Prev Arrows (Desktop navigation)
          if (widget.mediaUrls.length > 1) ...[
            if (_currentIndex > 0)
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28),
                    onPressed: () {
                      _pageCtrl.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
            if (_currentIndex < widget.mediaUrls.length - 1)
              Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 28),
                    onPressed: () {
                      _pageCtrl.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
          ],

          // Top bar: report ID (left), counter (center), close button (right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      '#${widget.reportId}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      'Photo ${_currentIndex + 1} of ${widget.mediaUrls.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _close,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dot indicators at bottom
          if (widget.mediaUrls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.mediaUrls.length, (i) {
                  final active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? AppColors.orange : Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    ),
  );
}
}

// ══════════════════════════════════════════════════════════════════════════════
//  REPORT CARD (with two‑image grid)
// ══════════════════════════════════════════════════════════════════════════════

class _ReportCard extends StatefulWidget {
  final ReportModel report;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;
  final Duration animationDelay;

  const _ReportCard({
    super.key,
    required this.report,
    required this.onUpvote,
    required this.onDownvote,
    this.animationDelay = Duration.zero,
  });

  @override
  State<_ReportCard> createState() => _ReportCardWidgetState();
}

class _ReportCardWidgetState extends State<_ReportCard>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  bool _isExpanded = false;
  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _entryFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutCubic,
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _openImageViewer(int index) {
    if (widget.report.mediaUrls.isEmpty) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder:
          (_, __, ___) => ImageViewerOverlay(
            mediaUrls: widget.report.mediaUrls,
            initialIndex: index,
            reportId: widget.report.id.toString(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CitizenReportDetailScreen(report: widget.report),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        _hovering
                            ? AppColors.orange.withOpacity(0.35)
                            : AppColors.border,
                    width: 1,
                  ),
                  boxShadow:
                      _hovering
                          ? [
                            BoxShadow(
                              color: AppColors.orange.withOpacity(0.06),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ]
                          : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: Status + Date ──────────────────────────
                Row(
                  children: [
                    _StatusBadge(status: report.status),
                    const Spacer(),
                    Text(
                      _relativeDate(report.createdAt),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Type title + Reporter alongside ──────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        report.disasterType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white38,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "Citizen",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 3),



                // ── Description ──────────────────────────────────────────
                Text(
                  report.description,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                    height: 1.4,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                                if (report.submissions.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.group_outlined, color: Colors.white54, size: 14),
                      const Text(
                        'Reported by:',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      ...report.submissions.map((sub) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (sub['user_name'] ?? 'Citizen').toString(),
                              style: const TextStyle(
                                  color: AppColors.orange, fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                            ),
                          )),
                    ],
                  ),
                if (report.submissions.isNotEmpty) const SizedBox(height: 14),

                // ── TWO‑IMAGE GRID (restored) ────────────────────────────
                _buildImageGrid(report.mediaUrls),
                const SizedBox(height: 14),

                // ── Vote Buttons ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _VoteButton(
                        label: '${report.likes}',
                        icon: Icons.thumb_up_alt_outlined,
                        activeIcon: Icons.thumb_up_alt_rounded,
                        color: AppColors.success,
                        active: report.userReaction == 'LIKE',
                        onTap: widget.onUpvote,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _VoteButton(
                        label: '${report.dislikes}',
                        icon: Icons.thumb_down_alt_outlined,
                        activeIcon: Icons.thumb_down_alt_rounded,
                        color: AppColors.danger,
                        active: report.userReaction == 'DISLIKE',
                        onTap: widget.onDownvote,
                      ),
                    ),
                  ],
                ),
                
                // ── Nested Submissions Dropdown ─────────────────────────
                if (report.submissions.length > 1) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12, height: 1),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isExpanded
                                ? 'Hide Matched Reports'
                                : 'Show Matched Reports (${report.submissions.length - 1})',
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.orange,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isExpanded)
                    ...report.submissions
                        .skip(1)
                        .map((sub) => _buildNestedReportCard(sub, report)),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildNestedReportCard(dynamic sub, ReportModel mainReport) {
    return GestureDetector(
      onTap: () {
        // Show popup info
        _showNestedReportDetails(sub, mainReport);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    sub['title'] ?? mainReport.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _formatTime(sub['timestamp'] ?? mainReport.createdAt),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              sub['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.orange,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  sub['user_name'] ?? 'Citizen',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String raw) {
    return _relativeDate(raw);
  }

  void _showNestedReportDetails(dynamic sub, ReportModel mainReport) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sub['title'] ?? mainReport.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, color: AppColors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      sub['user_name'] ?? 'Citizen',
                      style: const TextStyle(color: AppColors.orange, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(sub['timestamp'] ?? mainReport.createdAt),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Nested Image
                if (sub['media_urls'] != null && (sub['media_urls'] as List).isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      (sub['media_urls'] as List).first.toString(),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      color: AppColors.bgDark,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.image_outlined, color: Colors.white24, size: 40),
                          Positioned(
                            bottom: 8,
                            child: Text(
                              'No Evidence Photo',
                              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                Text(
                  'Description',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sub['description'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Likes/Dislikes (Using main report's for now as nested reports don't have separate likes strictly in the DB design yet, or we show 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.thumb_up_alt_outlined, color: AppColors.success, size: 20),
                        const SizedBox(width: 6),
                        Text('${mainReport.likes}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.thumb_down_alt_outlined, color: AppColors.danger, size: 20),
                        const SizedBox(width: 6),
                        Text('${mainReport.dislikes}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── TWO‑IMAGE GRID (original style: two thumbnails, second shows +N if more) ──
  Widget _buildImageGrid(List<String> mediaUrls) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();
    final actualCount = mediaUrls.length.clamp(1, 5);
    final visibleCards = actualCount == 1 ? 1 : 2;
    final extraCount = actualCount - visibleCards;

    return Row(
      children: List.generate(visibleCards, (i) {
        final isLast = i == visibleCards - 1 && extraCount > 0;
        return Expanded(
          child: GestureDetector(
            onTap: () => _openImageViewer(i),
            child: Container(
              height: 130,
              margin: EdgeInsets.only(right: i < visibleCards - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      mediaUrls[i],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white.withOpacity(0.2),
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                    // +N overlay on last visible card
                    if (isLast)
                      Container(
                        color: Colors.black.withOpacity(0.65),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '+$extraCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'more',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

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
}

// ══════════════════════════════════════════════════════════════════════════════
//  VOTE BUTTON
// ══════════════════════════════════════════════════════════════════════════════

class _VoteButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _VoteButton({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  State<_VoteButton> createState() => _VoteButtonState();
}

class _VoteButtonState extends State<_VoteButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _tapCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _tapCtrl.forward();
    _tapCtrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color:
                  widget.active
                      ? widget.color.withOpacity(0.25)
                      : _hovered
                      ? widget.color.withOpacity(0.18)
                      : widget.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.color.withOpacity(
                  widget.active
                      ? 0.8
                      : _hovered
                      ? 0.55
                      : 0.30,
                ),
                width: widget.active ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder:
                      (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    widget.active ? widget.activeIcon : widget.icon,
                    key: ValueKey(widget.active),
                    color: widget.color,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    color: widget.color,
                    fontSize: widget.active || _hovered ? 12.8 : 12,
                    fontWeight:
                        widget.active ? FontWeight.w800 : FontWeight.w600,
                    decoration: TextDecoration.none,
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

// ══════════════════════════════════════════════════════════════════════════════
//  STAT CARD
// ══════════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  STATUS BADGE
// ══════════════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    final lowercaseStatus = status.toLowerCase();
    
    if (lowercaseStatus.contains('progress')) {
        bg = AppColors.orange.withOpacity(0.18);
        text = AppColors.orange;
    } else if (lowercaseStatus.contains('controlled') || lowercaseStatus.contains('verified')) {
        bg = AppColors.success.withOpacity(0.15);
        text = AppColors.success;
    } else if (lowercaseStatus.contains('rejected')) {
        bg = AppColors.danger.withOpacity(0.15);
        text = AppColors.danger;
    } else { // Pending
        bg = AppColors.warning.withOpacity(0.15);
        text = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
