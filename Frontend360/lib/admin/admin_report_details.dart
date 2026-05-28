import 'package:disaster360/colors.dart';
import 'package:flutter/material.dart';
import 'package:disaster360/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/providers/report_provider.dart';
import 'package:disaster360/citizen/citizen_home_screen.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

class AdminReportData {
  final String reportId;
  final String status;
  final String type;
  final String title;
  final String description;
  final String date;
  final String location;
  final String lat;
  final String lng;
  final String reporter;
  final int trustScore;
  final int upvotes;
  final int downvotes;
  final List<String> mediaUrls;
  final List<dynamic> submissions;

  const AdminReportData({
    required this.reportId,
    required this.status,
    required this.type,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.lat,
    required this.lng,
    required this.reporter,
    required this.trustScore,
    required this.upvotes,
    required this.downvotes,
    required this.mediaUrls,
    this.submissions = const [],
  });
}

// ─── Breakpoints ──────────────────────────────────────────────────────────────

class _BP {
  static bool isMobile(BuildContext ctx) => MediaQuery.of(ctx).size.width < 600;
  static bool isTablet(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 600 &&
      MediaQuery.of(ctx).size.width < 1024;
  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 1024;
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class AdminReportDetailScreen extends StatefulWidget {
  final AdminReportData report;
  final String initialDecisionState;

  const AdminReportDetailScreen({
    super.key,
    required this.report,
    this.initialDecisionState = 'pending',
  });

  @override
  State<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen>
    with TickerProviderStateMixin {
  late String _decisionState;
  final List<String> _selectedTeams = [];

  // Animation controllers
  late AnimationController _cardController;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  late AnimationController _decisionController;
  late Animation<double> _decisionFade;
  late Animation<Offset> _decisionSlide;

  @override
  void initState() {
    super.initState();
    // Derive initial decision state from passed value or report status
    _decisionState = widget.initialDecisionState;
    try {
      if (widget.report.status.toLowerCase() == 'verified') {
        _decisionState = 'verified';
      } else if (widget.report.status.toLowerCase() == 'rejected') {
        _decisionState = 'rejected';
      }
    } catch (_) {}

    // Card entrance animation
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    // Decision area animation
    _decisionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _decisionFade = CurvedAnimation(
      parent: _decisionController,
      curve: Curves.easeOut,
    );
    _decisionSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _decisionController, curve: Curves.easeOut),
    );

    _cardController.forward();
    _decisionController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _decisionController.dispose();
    super.dispose();
  }

  final List<String> _availableTeams = [
    'Fire Response Team A',
    'Fire Response Team B',
    'Ambulance Unit 1',
    'Ambulance Unit 2',
    'Flood Response Team A',
    'Flood Response Team B',
    'Search & Rescue Unit',
    'Police Response Unit',
  ];

  // ─── Actions ────────────────────────────────────────────────────────────

  void _verifyApiCall() async {
    try {
      final api = ApiService();
      // Handle mock UI report ID (e.g. "RPT-00420") vs actual API ID logic
      final intId = int.tryParse(
        widget.report.reportId.replaceAll(RegExp(r'[^0-9]'), ''),
      );

      if (intId != null) {
        await api.put('/admin/reports/$intId/verify');
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Verified successfully')));
        _decisionController.reverse().then((_) {
          setState(() => _decisionState = 'verified');
          _decisionController.forward();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _rejectApiCall(String reason) {
    final intId = int.tryParse(
      widget.report.reportId.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    
    if (intId != null) {
      context.read<ReportProvider>().rejectReport(intId);
      Navigator.pop(context); // Navigate back to the dashboard immediately
    }
  }

  void _onUndoReject() async {
    final intId = int.tryParse(
      widget.report.reportId.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (intId != null) {
      await context.read<ReportProvider>().undoRejectReport(intId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report reverted to Pending')),
        );
        _decisionController.reverse().then((_) {
          setState(() => _decisionState = 'pending');
          _decisionController.forward();
        });
      }
    }
  }

  void _onVerify() {
    _verifyApiCall();
  }

  void _onReject() {
    if (_BP.isMobile(context)) {
      _showRejectionBottomSheet();
    } else {
      _showRejectionDialog();
    }
  }

  void _showRejectionDialog() {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder:
          (_) => _RejectionDialog(
            report: widget.report,
            reasonController: reasonController,
            onConfirmReject: (reason) {
              Navigator.pop(context);
              _rejectApiCall(reason);
            },
          ),
    );
  }

  void _onAssign() async {
    if (_selectedTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one rescue team.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      final intId = int.tryParse(
        widget.report.reportId.replaceAll(RegExp(r'[^0-9]'), ''),
      );

      if (intId != null) {
        final api = ApiService();
        await api.post('/admin/reports/$intId/assign', body: {
          'team_names': _selectedTeams,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedTeams.length} team(s) assigned to ${widget.report.reportId}',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign teams: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onUnverify() async {
    final intId = int.tryParse(
      widget.report.reportId.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (intId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Undo Verification?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text(
          'This will reset the report back to Pending status.',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unverify',
                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ReportProvider>().unverifyReport(intId);
      if (!mounted) return;
      _decisionController.reverse().then((_) {
        setState(() => _decisionState = 'pending');
        _decisionController.forward();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.report.reportId} reset to Pending.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unverify failed: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showRejectionBottomSheet() {
    final TextEditingController reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => RejectionBottomSheet(
            report: widget.report,
            reasonController: reasonController,
            onConfirmReject: (reason) {
              Navigator.pop(context);
              _rejectApiCall(reason);
            },
          ),
    );
  }

  String _relativeDate(String dateStr) {
    if (dateStr.isEmpty) return 'Just now';
    try {
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
        dateStr += 'Z';
      }
      final dt = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return dateStr.split("T").first;
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_BP.isDesktop(context)) return _buildDesktopLayout();
          if (_BP.isTablet(context)) return _buildTabletLayout();
          return _buildMobileLayout();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      leading: _AnimatedIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.pop(context),
      ),
      title: Text(
        'Report #${widget.report.reportId}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _StatusBadge(status: widget.report.status),
        ),
      ],
    );
  }

  // ─── Mobile Layout (single column) ────────────────────────────────────────

  Widget _buildMobileLayout() {
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportInfoCard(),
              const SizedBox(height: 14),
              _buildGpsPhotosCard(),
              const SizedBox(height: 14),
              _buildReporterCard(),
              const SizedBox(height: 14),
              _buildVotesRow(),
              const SizedBox(height: 24),
              _buildDecisionArea(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tablet Layout (2-column grid, centered up to 820px) ─────────────────

  Widget _buildTabletLayout() {
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildReportInfoCard(),
                          const SizedBox(height: 14),
                          _buildGpsPhotosCard(),
                          const SizedBox(height: 14),
                          _buildVotesRow(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right column
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildReporterCard(),
                          const SizedBox(height: 14),
                          _buildDecisionArea(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Desktop Layout (centered 2-column, same as tablet, grows with screen) ──

  Widget _buildDesktopLayout() {
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ConstrainedBox(
              // Content grows up to 960px then stays centered — whitespace fills sides
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column — same as tablet
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildReportInfoCard(),
                          const SizedBox(height: 16),
                          _buildGpsPhotosCard(),
                          const SizedBox(height: 16),
                          _buildVotesRow(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    // Right column — same as tablet
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildReporterCard(),
                          const SizedBox(height: 16),
                          _buildDecisionArea(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Report Info Card ──────────────────────────────────────────────────────

  Widget _buildReportInfoCard() {
    return _AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeChip(label: widget.report.type),
              const Spacer(),
              _StatusBadge(status: widget.report.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.report.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.report.description,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _MetaItem(
                icon: Icons.access_time_rounded,
                label: _relativeDate(widget.report.date),
              ),
              _MetaItem(
                icon: Icons.location_on_outlined,
                label: widget.report.location,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── GPS & Photos Card ────────────────────────────────────────────────────

  Widget _buildGpsPhotosCard() {
    return _AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GPS row
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.orange,
                size: 18,
              ),
              Text(
                '${widget.report.lat}, ${widget.report.lng}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'GPS verified',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.image_outlined, color: Colors.white38, size: 15),
              const SizedBox(width: 6),
              Text(
                '${widget.report.mediaUrls.length} photo(s) attached',
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPhotoGrid(),
        ],
      ),
    );
  }

  // ─── Photo Grid
  // Passport size (India/Nepal govt standard): 35mm × 45mm
  // Double = 70mm × 90mm → aspect ratio 7:9
  // We use intrinsic sizing so it never overflows regardless of screen width.

  Widget _buildPhotoGrid() {
    if (widget.report.mediaUrls.isEmpty) return const SizedBox.shrink();

    final count = widget.report.mediaUrls.length.clamp(1, 5);
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGap = 8.0 * (count - 1);
        final photoWidth = (constraints.maxWidth - totalGap) / count;
        final photoHeight = photoWidth * (9 / 7);

        return Row(
          children: List.generate(count, (index) {
            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        barrierColor: Colors.transparent,
                        transitionDuration: const Duration(milliseconds: 250),
                        pageBuilder: (_, __, ___) => ImageViewerOverlay(
                          mediaUrls: widget.report.mediaUrls,
                          initialIndex: index,
                          reportId: widget.report.reportId,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.report.mediaUrls[index],
                      width: photoWidth,
                      height: photoHeight,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: photoWidth,
                        height: photoHeight,
                        color: Colors.white12,
                        child: const Icon(Icons.broken_image, color: Colors.white38),
                      ),
                    ),
                  ),
                ),
                if (index < count - 1) const SizedBox(width: 8),
              ],
            );
          }),
        );
      },
    );
  }

  // ─── Reporter Card ─────────────────────────────────────────────────────────

  Widget _buildReporterCard() {
    return _AnimatedCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.report.reporter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      'Trust Score: ${widget.report.trustScore}/100',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Votes Row ─────────────────────────────────────────────────────────────

  Widget _buildVotesRow() {
    return Row(
      children: [
        Expanded(
          child: _AnimatedVoteBox(
            icon: Icons.thumb_up_alt_outlined,
            label: '+${widget.report.upvotes}  Upvotes',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AnimatedVoteBox(
            icon: Icons.thumb_down_alt_outlined,
            label: '-${widget.report.downvotes}  Downvotes',
            color: AppColors.danger,
          ),
        ),
      ],
    );
  }

  // ─── Decision Area ─────────────────────────────────────────────────────────

  Widget _buildDecisionArea() {
    return FadeTransition(
      opacity: _decisionFade,
      child: SlideTransition(
        position: _decisionSlide,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder:
              (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
          child:
              _decisionState == 'rejected'
                  ? _buildRejectedBanner()
                  : _decisionState == 'verified'
                  ? _buildAssignTeamSection()
                  : _buildPendingButtons(),
        ),
      ),
    );
  }

  Widget _buildPendingButtons() {
    return Row(
      key: const ValueKey('pending'),
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Verify',
            icon: Icons.check_rounded,
            color: AppColors.success,
            onTap: _onVerify,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: 'Reject',
            icon: Icons.close_rounded,
            color: AppColors.danger,
            onTap: _onReject,
          ),
        ),
      ],
    );
  }

  Widget _buildAssignTeamSection() {
    return Column(
      key: const ValueKey('verified'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verified banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.success.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppColors.success, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Report verified. Assign rescue team(s) below.',
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
        const Text(
          'ASSIGN RESCUE TEAMS',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ..._availableTeams.map(
          (team) => _TeamCheckTile(
            label: team,
            isSelected: _selectedTeams.contains(team),
            onToggle: () {
              setState(() {
                if (_selectedTeams.contains(team)) {
                  _selectedTeams.remove(team);
                } else {
                  _selectedTeams.add(team);
                }
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        _ActionButton(
          fullWidth: true,
          label:
              _selectedTeams.isEmpty
                  ? 'Assign Team'
                  : 'Assign ${_selectedTeams.length} Team(s)',
          icon: Icons.group_rounded,
          color: AppColors.orange,
          filled: true,
          onTap: _onAssign,
        ),
        const SizedBox(height: 10),
        _ActionButton(
          fullWidth: true,
          label: 'Undo Verification',
          icon: Icons.undo_rounded,
          color: AppColors.warning,
          filled: false,
          onTap: _onUnverify,
        ),
      ],
    );
  }

  Widget _buildRejectedBanner() {
    return Column(
      key: const ValueKey('rejected'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.danger.withOpacity(0.3), width: 1),
          ),
          child: const Row(
            children: [
              Icon(Icons.cancel_rounded, color: AppColors.danger, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This report has been rejected.',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ActionButton(
          fullWidth: true,
          label: 'Undo Rejection',
          icon: Icons.undo_rounded,
          color: AppColors.orange,
          filled: false,
          onTap: _onUndoReject,
        ),
      ],
    );
  }
}

// ─── Photo Thumb (full-screen on tap) ────────────────────────────────────────

class _PhotoThumb extends StatefulWidget {
  final int index;
  final double width;
  final double height;
  final int totalCount;
  final String reportId;

  const _PhotoThumb({
    required this.index,
    required this.width,
    required this.height,
    required this.totalCount,
    required this.reportId,
  });

  @override
  State<_PhotoThumb> createState() => _PhotoThumbState();
}

class _PhotoThumbState extends State<_PhotoThumb>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _hoverCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder:
            (_, animation, __) => FadeTransition(
              opacity: animation,
              child: _FullScreenPhotoViewer(
                photoIndex: widget.index,
                totalCount: widget.totalCount,
                reportId: widget.reportId,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.zoomIn,
      onEnter: (_) {
        setState(() => _hovering = true);
        _hoverCtrl.forward();
      },
      onExit: (_) {
        setState(() => _hovering = false);
        _hoverCtrl.reverse();
      },
      child: GestureDetector(
        onTap: () => _openFullScreen(context),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    _hovering
                        ? AppColors.orange.withOpacity(0.6)
                        : AppColors.border,
                width: 1,
              ),
              boxShadow:
                  _hovering
                      ? [
                        BoxShadow(
                          color: AppColors.orange.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_rounded,
                      color: Colors.white.withOpacity(_hovering ? 0.5 : 0.2),
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Photo ${widget.index}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(_hovering ? 0.5 : 0.2),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // Hover overlay hint
                AnimatedOpacity(
                  opacity: _hovering ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 160),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.zoom_in_rounded,
                        color: AppColors.orange,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Full-Screen Photo Viewer ─────────────────────────────────────────────────

class _FullScreenPhotoViewer extends StatelessWidget {
  final int photoIndex;
  final int totalCount;
  final String reportId;

  const _FullScreenPhotoViewer({
    required this.photoIndex,
    required this.totalCount,
    required this.reportId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: Stack(
        children: [
          // Background dismiss
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),

          // Photo container
          Center(
            child: Hero(
              tag: 'photo_$photoIndex',
              child: Container(
                // Double-passport: maintain 7:9 aspect ratio
                // Max 80% of screen dimensions
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.80,
                  maxHeight: MediaQuery.of(context).size.height * 0.80,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: 7 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_rounded,
                          color: Colors.white.withOpacity(0.12),
                          size: 64,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Photo $photoIndex',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Close button (top-right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _AnimatedIconButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),

          // Badge (bottom)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Text(
                  'Photo $photoIndex of $totalCount  ·  #$reportId',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rejection Dialog (tablet & desktop) ─────────────────────────────────────

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
                // Header row
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
                    // Close X
                    _AnimatedIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Minimal report info card
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

                // Reason label
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

                // Action row — Cancel + Confirm
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

// ─── Rejection Bottom Sheet (mobile only) ────────────────────────────────────

class RejectionBottomSheet extends StatelessWidget {
  final AdminReportData report;
  final TextEditingController reasonController;
  final void Function(String reason) onConfirmReject;

  const RejectionBottomSheet({
    super.key,
    required this.report,
    required this.reasonController,
    required this.onConfirmReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
            const SizedBox(height: 20),
            const Text(
              'Reject Report',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            // Minimal report info
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
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
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
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
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
            _ActionButton(
              fullWidth: true,
              label: 'Confirm Rejection',
              icon: Icons.close_rounded,
              color: AppColors.danger,
              filled: true,
              onTap: () => onConfirmReject(reasonController.text),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Animated Widgets ────────────────────────────────────────────────

/// Card with lift-on-hover animation
class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _AnimatedCard({required this.child, this.padding});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _ctrl;
  late Animation<double> _elevation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _elevation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) {
        setState(() => _hovering = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovering = false);
        _ctrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _elevation,
        builder:
            (_, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: widget.padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      _hovering
                          ? AppColors.orange.withOpacity(0.22)
                          : AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.18 + _elevation.value * 0.12,
                    ),
                    blurRadius: 8 + _elevation.value * 12,
                    offset: Offset(0, 2 + _elevation.value * 6),
                  ),
                ],
              ),
              child: child,
            ),
        child: widget.child,
      ),
    );
  }
}

/// Animated icon-only button (back button, close button)
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedIconButton({required this.icon, required this.onTap});

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovering = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovering = false);
        _ctrl.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  _hovering
                      ? AppColors.orange.withOpacity(0.15)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

/// Vote box with hover animation
class _AnimatedVoteBox extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AnimatedVoteBox({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  State<_AnimatedVoteBox> createState() => _AnimatedVoteBoxState();
}

class _AnimatedVoteBoxState extends State<_AnimatedVoteBox>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) {
        setState(() => _hovering = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovering = false);
        _ctrl.reverse();
      },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_hovering ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.color.withOpacity(_hovering ? 0.45 : 0.25),
              width: 1,
            ),
            boxShadow:
                _hovering
                    ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 16),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action button — can be inline or full-width, filled or outlined
class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
    this.filled = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  bool _pressed = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.filled
            ? widget.color
            : widget.color.withOpacity(_hovering ? 0.26 : 0.18);
    final borderColor =
        widget.filled
            ? Colors.transparent
            : widget.color.withOpacity(_hovering ? 0.7 : 0.45);

    Widget btn = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: widget.fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow:
            _hovering && widget.filled
                ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
                : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            color: widget.filled ? Colors.white : widget.color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              color: widget.filled ? Colors.white : widget.color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovering = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovering = false);
        _ctrl.reverse();
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: btn,
          ),
        ),
      ),
    );
  }
}

/// Team checkbox tile with hover + animated check
class _TeamCheckTile extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onToggle;

  const _TeamCheckTile({
    required this.label,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  State<_TeamCheckTile> createState() => _TeamCheckTileState();
}

class _TeamCheckTileState extends State<_TeamCheckTile>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovering = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovering = false);
        _ctrl.reverse();
      },
      child: GestureDetector(
        onTap: widget.onToggle,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color:
                  widget.isSelected
                      ? AppColors.orange.withOpacity(0.1)
                      : _hovering
                      ? AppColors.bgDark
                      : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    widget.isSelected
                        ? AppColors.orange.withOpacity(0.5)
                        : _hovering
                        ? AppColors.orange.withOpacity(0.2)
                        : AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color:
                        widget.isSelected
                            ? AppColors.orange
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          widget.isSelected ? AppColors.orange : Colors.white24,
                      width: 1.5,
                    ),
                  ),
                  child:
                      widget.isSelected
                          ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 13,
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isSelected ? Colors.white : Colors.white54,
                      fontSize: 13,
                      fontWeight:
                          widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Small Utility Widgets ────────────────────────────────────────────────────

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;

  const _TypeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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
