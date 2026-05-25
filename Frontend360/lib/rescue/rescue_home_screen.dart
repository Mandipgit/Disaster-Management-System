import 'package:disaster360/rescue/rescue_disaster_report.dart';
import 'package:disaster360/rescue/rescue_motion.dart';
import 'package:disaster360/rescue/rescue_profile_screen.dart';
import 'package:disaster360/rescue/rescue_tasks_screen.dart';
import 'package:disaster360/services/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/providers/report_provider.dart';
import 'package:disaster360/services/notification_alert.dart';
import 'package:disaster360/colors.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  RESCUE HOME SCREEN — with fixed header only on Home tab
// ═══════════════════════════════════════════════════════════════════════════════

class RescueHomeScreen extends StatefulWidget {
  const RescueHomeScreen({super.key});

  @override
  State<RescueHomeScreen> createState() => _RescueHomeScreenState();
}

class _RescueHomeScreenState extends State<RescueHomeScreen>
    with TickerProviderStateMixin {
  int _activeNav = 0; // 0: Home, 1: Map, 2: Tasks, 3: Reports, 4: Profile

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().fetchReports();
    });
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _switchNav(int index) {
    if (_activeNav == index) return;
    _fadeController.reset();
    setState(() => _activeNav = index);
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      bottomNavigationBar: _buildBottomNav(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(position: _slideAnim, child: _getScreenForNav()),
      ),
    );
  }

  Widget _getScreenForNav() {
    switch (_activeNav) {
      case 0:
        // Home screen: includes fixed header + scrollable content
        return Column(
          children: [
            SafeArea(bottom: false, child: _buildHeader()),
            Expanded(child: _RescueHomeBody(onGoToTasks: () => _switchNav(2))),
          ],
        );
      case 1:
        return const DisasterMapScreen();
      case 2:
        return const RescueTasksScreen();
      case 3:
        return const PostDisasterReportScreen();
      case 4:
        return const RescueProfileScreen();
      default:
        return const SizedBox();
    }
  }

  // ── Fixed header (only shown on Home screen) ────────────────────────────────
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
                'Rescue Team',
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'On duty',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap:
                    () =>
                        RescueMotion.push(context, const NotificationsScreen()),
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
        ],
      ),
    );
  }

  // ── Bottom navigation with active pill background + raised effect ────────────
  Widget _buildBottomNav() {
    return Container(
      // Allow raised items to extend upward without clipping
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      // Extra top padding to give room for the raised (translateY) effect
      padding: const EdgeInsets.only(top: 9, bottom: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AnimatedNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            isActive: _activeNav == 0,
            onTap: () => _switchNav(0),
          ),
          _AnimatedNavItem(
            icon: Icons.map_outlined,
            label: 'Map',
            isActive: _activeNav == 1,
            onTap: () => _switchNav(1),
          ),
          _AnimatedNavItem(
            icon: Icons.checklist_rounded,
            label: 'Tasks',
            isActive: _activeNav == 2,
            onTap: () => _switchNav(2),
          ),
          _AnimatedNavItem(
            icon: Icons.insert_drive_file_outlined,
            label: 'Reports',
            isActive: _activeNav == 3,
            onTap: () => _switchNav(3),
          ),
          _AnimatedNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            isActive: _activeNav == 4,
            onTap: () => _switchNav(4),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ANIMATED NAV ITEM (SQUARE BACKGROUND + REDUCED HEIGHT + RAISED)
// ═══════════════════════════════════════════════════════════════════════════════

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
  bool _hovered = false;

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
    // --- RAISED EFFECT: translate Y up when active ---
    final translateY = widget.isActive ? -1.0 : 0.0;

    // --- ACTIVE STYLES (bigger icon/text, square background) ---
    final activeIconSize = 24.0;
    final inactiveIconSize = 18.0;
    final activeFontSize = 12.0;
    final inactiveFontSize = 10.0;

    final currentIconSize = widget.isActive ? activeIconSize : inactiveIconSize;
    final currentFontSize = widget.isActive ? activeFontSize : inactiveFontSize;

    // Square background (small radius) instead of pill
    final backgroundColor =
        widget.isActive
            ? AppColors.orange.withOpacity(0.2)
            : Colors.transparent;
    final borderColor =
        widget.isActive
            ? AppColors.orange.withOpacity(0.35)
            : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Transform.translate(
          offset: Offset(0, translateY),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            // REDUCED HEIGHT: smaller vertical padding (was 8.0)
            padding: EdgeInsets.symmetric(
              horizontal:
                  widget.isActive
                      ? 16.0
                      : 10.0, // horizontal padding slightly reduced
              vertical: 4.0, // was 8.0 → now shorter height
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              // SQUARE shape (small radius, not pill)
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: borderColor,
                width: widget.isActive ? 1.2 : 0,
              ),
              boxShadow:
                  widget.isActive
                      ? [
                        BoxShadow(
                          color: AppColors.orange.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: ScaleTransition(
              scale: _bounceAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder:
                        (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      widget.icon,
                      key: ValueKey('${widget.icon}_${widget.isActive}'),
                      color:
                          widget.isActive ? AppColors.orange : Colors.white38,
                      size: currentIconSize,
                    ),
                  ),
                  // Reduced gap between icon and text (was 5.0)
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color:
                          widget.isActive ? AppColors.orange : Colors.white38,
                      fontSize: currentFontSize,
                      fontWeight:
                          widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                    child: Text(widget.label),
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
// ═══════════════════════════════════════════════════════════════════════════════
//  HOME BODY (scrollable content, without header)
// ═══════════════════════════════════════════════════════════════════════════════

class _RescueHomeBody extends StatelessWidget {
  final VoidCallback onGoToTasks;
  const _RescueHomeBody({required this.onGoToTasks});

  @override
  Widget build(BuildContext context) {
    // ── Sample data ──────────────────────────────────────────────────────────
    final activeMissions = <_MissionData>[];

    final pendingMissions = <_MissionData>[];

    final completedMissions = <_MissionData>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NewMissionBanner(onTap: onGoToTasks),
          const SizedBox(height: 20),
          _buildStatCards(
            active: activeMissions.length,
            pending: pendingMissions.length,
            completed: completedMissions.length,
          ),
          const SizedBox(height: 28),
          _MissionSection(
            label: 'ACTIVE MISSIONS',
            missions: activeMissions,
            accentColor: AppColors.danger,
            status: 'Active',
          ),
          const SizedBox(height: 20),
          _MissionSection(
            label: 'PENDING MISSIONS',
            missions: pendingMissions,
            accentColor: AppColors.warning,
            status: 'Pending',
          ),
          const SizedBox(height: 20),
          _TodaysCompleted(missions: completedMissions),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCards({
    required int active,
    required int pending,
    required int completed,
  }) {
    return Row(
      children: [
        _StatCard(
          value: '$active',
          label: 'Active',
          valueColor: AppColors.danger,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '$pending',
          label: 'Pending',
          valueColor: AppColors.warning,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '$completed',
          label: 'Completed',
          valueColor: AppColors.success,
        ),
      ],
    );
  }
}

// ─── New Mission Banner (subtle pulse) ───────────────────────────────────────

class _NewMissionBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _NewMissionBanner({required this.onTap});

  @override
  State<_NewMissionBanner> createState() => _NewMissionBannerState();
}

class _NewMissionBannerState extends State<_NewMissionBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pulseAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.danger.withOpacity(0.45),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New mission assigned',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Flood — Koshi Bridge · Respond immediately',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mission Section ──────────────────────────────────────────────────────────

class _MissionSection extends StatelessWidget {
  final String label;
  final List<_MissionData> missions;
  final Color accentColor;
  final String status;

  const _MissionSection({
    required this.label,
    required this.missions,
    required this.accentColor,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...missions.map(
          (m) => _MissionCard(
            mission: m,
            accentColor: accentColor,
            status: status,
          ),
        ),
      ],
    );
  }
}

// ─── Mission Card (with tap feedback) ────────────────────────────────────────

class _MissionCard extends StatefulWidget {
  final _MissionData mission;
  final Color accentColor;
  final String status;

  const _MissionCard({
    required this.mission,
    required this.accentColor,
    required this.status,
  });

  @override
  State<_MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<_MissionCard> {
  bool _hovered = false;

  void _showDetails(BuildContext context) {
    RescueMotion.showSweetBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.65,
            maxChildSize: 0.92,
            minChildSize: 0.4,
            builder:
                (_, ctrl) => Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: _sheetHandle()),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${widget.mission.incidentId}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                          _statusBadge(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.mission.type} — ${widget.mission.location}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.mission.description,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          controller: ctrl,
                          children: [
                            _DetailRow(
                              icon: Icons.location_on_outlined,
                              label: 'GPS',
                              value: widget.mission.location,
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              icon: Icons.straighten_outlined,
                              label: 'Distance',
                              value: widget.mission.distance,
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              icon: Icons.report_outlined,
                              label: 'Report ID',
                              value: '#${widget.mission.reportId}',
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              icon: Icons.image_outlined,
                              label: 'Photos',
                              value: '${widget.mission.photoCount} attached',
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              icon: Icons.access_time_outlined,
                              label: 'Assigned',
                              value: widget.mission.assignedAgo,
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              icon: Icons.priority_high_outlined,
                              label: 'Priority',
                              value: widget.mission.priority,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _statusBadge() {
    Color bg, text;
    String label;
    if (widget.status == 'Active') {
      bg = AppColors.danger.withOpacity(0.18);
      text = AppColors.danger;
      label = 'Active';
    } else if (widget.status == 'Pending') {
      bg = AppColors.warning.withOpacity(0.15);
      text = AppColors.warning;
      label = 'Pending';
    } else {
      bg = AppColors.success.withOpacity(0.15);
      text = AppColors.success;
      label = 'Completed';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: text.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.status == 'Active';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _hovered
                        ? widget.accentColor.withOpacity(0.4)
                        : AppColors.border,
                width: isActive ? 1.5 : 1,
              ),
              boxShadow:
                  _hovered
                      ? [
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.08),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                      : [],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.mission.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _PriorityBadge(priority: widget.mission.priority),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.mission.incidentId} · ${widget.mission.assignedAgo}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Location',
                          value: widget.mission.location,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Distance',
                          value: widget.mission.distance,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MissionButton(
                          label: 'Accept mission',
                          filled: true,
                          color: widget.accentColor,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✓ Mission ${widget.mission.incidentId} accepted',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: AppColors.success.withOpacity(
                                  0.9,
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MissionButton(
                          label: 'View on map',
                          filled: false,
                          color: widget.accentColor,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Map feature coming soon',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: AppColors.info.withOpacity(
                                  0.9,
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Left accent stripe
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: widget.accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Mission Button (tap feedback) ──────────────────────────────────

class _MissionButton extends StatefulWidget {
  final String label;
  final bool filled;
  final Color color;
  final VoidCallback onTap;

  const _MissionButton({
    required this.label,
    required this.filled,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MissionButton> createState() => _MissionButtonState();
}

class _MissionButtonState extends State<_MissionButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _tapCtrl;
  late Animation<double> _tapAnim;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _tapAnim = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _tapCtrl.forward(),
        onTapUp: (_) {
          _tapCtrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _tapCtrl.reverse(),
        child: ScaleTransition(
          scale: _tapAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 48,
            decoration: BoxDecoration(
              color:
                  widget.filled
                      ? (_hovered
                          ? widget.color.withOpacity(0.28)
                          : widget.color.withOpacity(0.18))
                      : (_hovered
                          ? Colors.white.withOpacity(0.06)
                          : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    widget.filled
                        ? widget.color.withOpacity(_hovered ? 0.7 : 0.45)
                        : (_hovered ? Colors.white54 : AppColors.border),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.filled ? widget.color : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Today's Completed ────────────────────────────────────────────────────────

class _TodaysCompleted extends StatelessWidget {
  final List<_MissionData> missions;
  const _TodaysCompleted({required this.missions});

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "TODAY'S COMPLETED",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...missions.map((m) => _CompletedCard(mission: m)),
      ],
    );
  }
}

class _CompletedCard extends StatefulWidget {
  final _MissionData mission;
  const _CompletedCard({required this.mission});

  @override
  State<_CompletedCard> createState() => _CompletedCardState();
}

class _CompletedCardState extends State<_CompletedCard> {
  bool _hovering = false;

  void _showDetail(BuildContext context) {
    RescueMotion.showSweetDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: AppColors.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.mission.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white38,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.mission.incidentId,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  _InfoRow(label: 'Type', value: widget.mission.type),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Completed',
                    value: widget.mission.assignedAgo,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Location', value: widget.mission.location),
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Distance', value: widget.mission.distance),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Controlled',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.bgDark : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mission.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Completed · ${widget.mission.assignedAgo}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Controlled',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

// ═══════════════════════════════════════════════════════════════════════════════
//  SUPPORTING WIDGETS (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

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
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    switch (priority) {
      case 'Urgent':
        bg = AppColors.danger.withOpacity(0.15);
        text = AppColors.danger;
        break;
      case 'High':
        bg = AppColors.orange.withOpacity(0.15);
        text = AppColors.orange;
        break;
      case 'Medium':
        bg = AppColors.warning.withOpacity(0.15);
        text = AppColors.warning;
        break;
      default:
        bg = AppColors.info.withOpacity(0.15);
        text = AppColors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: text.withOpacity(0.4), width: 1),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class _MissionData {
  final String title;
  final String incidentId;
  final String assignedAgo;
  final String location;
  final String distance;
  final String priority;
  final String status;
  final String type;
  final String description;
  final String lat;
  final String lng;
  final String reportId;
  final int photoCount;

  const _MissionData({
    required this.title,
    required this.incidentId,
    required this.assignedAgo,
    required this.location,
    required this.distance,
    required this.priority,
    required this.status,
    required this.type,
    required this.description,
    required this.lat,
    required this.lng,
    required this.reportId,
    required this.photoCount,
  });
}

