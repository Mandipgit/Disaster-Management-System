import 'package:provider/provider.dart';
import 'package:disaster360/providers/auth_provider.dart';
import 'package:disaster360/auth/auth_wrapper.dart';
import 'package:disaster360/colors.dart';
import 'package:disaster360/main.dart';
import 'package:disaster360/services/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  RESCUE PROFILE SCREEN — Disaster360 Rescue Module
//
//  Sections (top → bottom):
//    1. Header: "My Profile" + Edit button
//    2. Avatar with online indicator
//    3. Name + role badge (Rescue Team) + location badge (Dharan)
//    4. Stats row: Missions Completed · Missions Done · Currently Working
//    5. Details info card (editable via dialog)
//    6. System Online toggle card
//    7. Duty Status card:
//         – Current Status (On Duty / Off Duty) with animated indicator
//         – Current Mission / Task (tappable)
//    8. Provide Feedback row (→ FeedbackScreen)
//    9. Go Off Duty button + Sign Out button (same _TaskButton architecture)
//
//  Animations:
//    • Entrance: FadeTransition + SlideTransition
//    • Buttons: ScaleTransition on tap (0.94x) + hover AnimatedContainer
//    • System toggle: AnimatedDefaultTextStyle color transition
//    • Duty dot: pulsing AnimationController when On Duty
//    • Hand cursor on all interactive elements
// ═══════════════════════════════════════════════════════════════════════════════

class RescueProfileScreen extends StatefulWidget {
  const RescueProfileScreen({super.key});

  @override
  State<RescueProfileScreen> createState() => _RescueProfileScreenState();
}

class _RescueProfileScreenState extends State<RescueProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── Editable profile data ──────────────────────────────────────────────────
  String _name = 'Binod Gurung';
  String _initials = 'BG';
  String _teamId = 'RSC-T001';
  String _phone = '+977  98XXXXXXXX';
  String _email = 'binod.rescue@disaster360.gov.np';
  String _location = 'Dharan';
  String _teamName = 'Team Alpha';
  String _speciality = 'Flood & Swift Water Rescue';

  // ── Stats (read-only) ──────────────────────────────────────────────────────
  final int _missionsCompleted = 23;
  final int _missionsDone = 24; // total including current
  final int _currentlyWorking = 1;

  // ── System / duty state ────────────────────────────────────────────────────
  bool _systemOnline = true;
  bool _isOnDuty = true;

  // ── Current mission (null if off duty / no active task) ───────────────────
  final String? _currentMissionId = 'TSK-00420';
  final String? _currentMissionLabel =
      'Active #TSK-00420 · Flood, Ward 5 Dharan';

  // ── Entrance + pulse animations ───────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.45,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Entrance animation (reuse same controller with a one-shot forward pass)
    _fadeAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut);
    // Use a separate tween for the slide because we want it only once
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(context),
              const SizedBox(height: 28),
              _buildAvatar(),
              const SizedBox(height: 14),
              _buildNameAndBadges(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 20),
              _buildDetailsCard(context),
              const SizedBox(height: 16),
              _buildSystemStatusCard(),
              const SizedBox(height: 16),
              _buildDutyStatusCard(context),
              const SizedBox(height: 16),
              _buildMenuCard(context),
              const SizedBox(height: 24),
              _buildGoOffDutyButton(context),
              const SizedBox(height: 12),
              _buildSignOutButton(context),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
          ),
        ),
        _ProfileTextButton(
          label: 'Edit',
          color: AppColors.orange,
          onTap: () => _showEditDialog(context),
        ),
      ],
    );
  }

  // ── 2. Avatar ──────────────────────────────────────────────────────────────
  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.success.withOpacity(0.4),
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              _initials,
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
              color: _isOnDuty ? AppColors.success : Colors.white38,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.bgPrimary, width: 2.5),
            ),
            child: Icon(
              _isOnDuty ? Icons.shield_rounded : Icons.shield_outlined,
              color: Colors.white,
              size: 10,
            ),
          ),
        ),
      ],
    );
  }

  // ── 3. Name + badges ───────────────────────────────────────────────────────
  Widget _buildNameAndBadges() {
    return Column(
      children: [
        Text(
          _name,
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
            _roleBadge('Rescue Team', AppColors.success),
            _roleBadge(_location, AppColors.info),
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

  // ── 4. Stats row ───────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      _Stat('Missions\nCompleted', '$_missionsCompleted', AppColors.success),
      _Stat('Total\nMissions', '$_missionsDone', AppColors.info),
      _Stat('Currently\nWorking', '$_currentlyWorking', AppColors.warning),
    ];

    return Row(
      children:
          stats.map((s) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      s.value,
                      style: TextStyle(
                        color: s.color,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.label,
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
          }).toList(),
    );
  }

  // ── 5. Details card (editable) ─────────────────────────────────────────────
  Widget _buildDetailsCard(BuildContext context) {
    final rows = [
      _InfoRow(label: 'Team ID', value: _teamId),
      _InfoRow(label: 'Team Name', value: _teamName),
      _InfoRow(label: 'Speciality', value: _speciality),
      _InfoRow(label: 'Email', value: _email),
      _InfoRow(label: 'Phone', value: _phone),
      _InfoRow(label: 'Base', value: _location, valueColor: AppColors.info),
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
                        maxLines: 1,
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

  // ── 6. System status card ──────────────────────────────────────────────────
  Widget _buildSystemStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
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
                  color: _systemOnline ? AppColors.success : AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  color: _systemOnline ? AppColors.success : AppColors.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                child: Text(_systemOnline ? 'System Online' : 'System Offline'),
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
    );
  }

  // ── 7. Duty status card ────────────────────────────────────────────────────
  Widget _buildDutyStatusCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'DUTY STATUS',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Current status row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Status',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                Row(
                  children: [
                    // Pulsing dot when on duty
                    if (_isOnDuty)
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder:
                            (_, __) => Opacity(
                              opacity: _pulseAnim.value,
                              child: Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _isOnDuty
                                ? AppColors.success.withOpacity(0.18)
                                : Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              _isOnDuty
                                  ? AppColors.success.withOpacity(0.5)
                                  : Colors.white24,
                        ),
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: _isOnDuty ? AppColors.success : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        child: Text(_isOnDuty ? 'On Duty' : 'Off Duty'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Current mission row
          MouseRegion(
            cursor:
                _currentMissionId != null
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
            child: GestureDetector(
              onTap:
                  _currentMissionId != null
                      ? () => _showCurrentMissionSheet(context)
                      : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Mission',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    Row(
                      children: [
                        Text(
                          _currentMissionId != null
                              ? 'Active #$_currentMissionId'
                              : 'None',
                          style: TextStyle(
                            color:
                                _currentMissionId != null
                                    ? AppColors.danger
                                    : Colors.white38,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (_currentMissionId != null) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white24,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 8. Menu card: Provide Feedback ────────────────────────────────────────
  Widget _buildMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: _ProfileMenuTile(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Provide Feedback',
        onTap:
            () => Navigator.push(context, _fadeRoute(const FeedbackScreen())),
      ),
    );
  }

  // ── 9a. Go Off Duty button ─────────────────────────────────────────────────
  Widget _buildGoOffDutyButton(BuildContext context) {
    return _ProfileActionButton(
      label: _isOnDuty ? 'Go Off Duty' : 'Go On Duty',
      icon:
          _isOnDuty
              ? Icons.bedtime_outlined
              : Icons.play_circle_outline_rounded,
      color: _isOnDuty ? AppColors.warning : AppColors.success,
      onTap: () => _showDutyToggleDialog(context),
    );
  }

  // ── 9b. Sign Out button ────────────────────────────────────────────────────
  Widget _buildSignOutButton(BuildContext context) {
    return _ProfileActionButton(
      label: 'Sign Out',
      icon: Icons.logout_rounded,
      color: AppColors.danger,
      onTap: () => _showSignOutDialog(context),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  DIALOGS & SHEETS
  // ════════════════════════════════════════════════════════════════════════════

  // ── Edit profile dialog ────────────────────────────────────────────────────
  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(text: _phone);
    final emailCtrl = TextEditingController(text: _email);
    final locationCtrl = TextEditingController(text: _location);
    final teamNameCtrl = TextEditingController(text: _teamName);
    final specialityCtrl = TextEditingController(text: _speciality);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            title: const Text(
              'Edit Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DialogField(controller: nameCtrl, label: 'Full Name'),
                    const SizedBox(height: 12),
                    _DialogField(controller: phoneCtrl, label: 'Phone'),
                    const SizedBox(height: 12),
                    _DialogField(controller: emailCtrl, label: 'Email'),
                    const SizedBox(height: 12),
                    _DialogField(
                      controller: locationCtrl,
                      label: 'Base Location',
                    ),
                    const SizedBox(height: 12),
                    _DialogField(controller: teamNameCtrl, label: 'Team Name'),
                    const SizedBox(height: 12),
                    _DialogField(
                      controller: specialityCtrl,
                      label: 'Speciality',
                    ),
                  ],
                ),
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
              _DialogSaveButton(
                onTap: () {
                  setState(() {
                    _name =
                        nameCtrl.text.trim().isNotEmpty
                            ? nameCtrl.text.trim()
                            : _name;
                    _phone =
                        phoneCtrl.text.trim().isNotEmpty
                            ? phoneCtrl.text.trim()
                            : _phone;
                    _email =
                        emailCtrl.text.trim().isNotEmpty
                            ? emailCtrl.text.trim()
                            : _email;
                    _location =
                        locationCtrl.text.trim().isNotEmpty
                            ? locationCtrl.text.trim()
                            : _location;
                    _teamName =
                        teamNameCtrl.text.trim().isNotEmpty
                            ? teamNameCtrl.text.trim()
                            : _teamName;
                    _speciality =
                        specialityCtrl.text.trim().isNotEmpty
                            ? specialityCtrl.text.trim()
                            : _speciality;
                    final parts = _name.split(' ');
                    _initials =
                        parts.length >= 2
                            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                            : _name.substring(0, 2).toUpperCase();
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  // ── Current mission detail sheet ───────────────────────────────────────────
  void _showCurrentMissionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => Container(
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _sheetHandle()),
                const SizedBox(height: 20),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder:
                          (_, __) => Opacity(
                            opacity: _pulseAnim.value,
                            child: Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                    ),
                    const Text(
                      'Current Active Mission',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#$_currentMissionId',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentMissionLabel ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _MissionTag(label: 'Flood', color: AppColors.info),
                          const SizedBox(width: 8),
                          _MissionTag(
                            label: 'Severity L5',
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 8),
                          _MissionTag(
                            label: 'Ward 5, Dharan',
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
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
    );
  }

  // ── Duty toggle dialog ─────────────────────────────────────────────────────
  void _showDutyToggleDialog(BuildContext context) {
    final goingOff = _isOnDuty;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            title: Text(
              goingOff ? 'Go Off Duty?' : 'Go On Duty?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            content: Text(
              goingOff
                  ? 'You will no longer receive new task assignments until you return to duty.'
                  : 'You will be set as available and may receive task assignments from the admin.',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.5,
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
              ElevatedButton(
                onPressed: () {
                  setState(() => _isOnDuty = !_isOnDuty);
                  Navigator.pop(context);
                  _showSnack(
                    goingOff
                        ? 'You are now Off Duty.'
                        : 'You are now On Duty. Stay safe!',
                    color: goingOff ? AppColors.warning : AppColors.success,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      goingOff ? AppColors.warning : AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  goingOff ? 'Go Off Duty' : 'Go On Duty',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ── Sign out dialog ────────────────────────────────────────────────────────
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const Text(
              'Are you sure you want to sign out of your rescue account?',
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
              ElevatedButton(
                onPressed:
                    () => context.read<AuthProvider>().logout().then((_) {
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthWrapper()),
                            (route) => false,
                          );
                        }
                      }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showSnack(String msg, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: color.withOpacity(0.92),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _sheetHandle() => Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: Colors.white12,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  ACTION BUTTON — same ScaleTransition + hover architecture as _TaskButton
// ══════════════════════════════════════════════════════════════════════════════

class _ProfileActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ProfileActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<_ProfileActionButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _tapCtrl;
  late Animation<double> _tapAnim;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
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
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color:
                  _hovered
                      ? widget.color.withOpacity(0.22)
                      : widget.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.color.withOpacity(_hovered ? 0.65 : 0.4),
                width: 1,
              ),
              boxShadow:
                  _hovered
                      ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.10),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                      : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _hovered ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(widget.icon, color: widget.color, size: 18),
                ),
                const SizedBox(width: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    color: widget.color,
                    fontSize: _hovered ? 15.2 : 15,
                    fontWeight: FontWeight.w700,
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

// ── Menu tile with hover ───────────────────────────────────────────────────────
class _ProfileMenuTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ProfileMenuTile> createState() => _ProfileMenuTileState();
}

class _ProfileMenuTileState extends State<_ProfileMenuTile> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        color: _h ? Colors.white.withOpacity(0.03) : Colors.transparent,
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
            scale: _h ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 140),
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

// ── Hover text button (Edit) ───────────────────────────────────────────────────
class _ProfileTextButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ProfileTextButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ProfileTextButton> createState() => _ProfileTextButtonState();
}

class _ProfileTextButtonState extends State<_ProfileTextButton> {
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
            color: _h ? widget.color.withOpacity(0.7) : widget.color,
            fontSize: _h ? 15.5 : 15,
            fontWeight: FontWeight.w600,
            decoration: _h ? TextDecoration.underline : TextDecoration.none,
            decorationColor: widget.color.withOpacity(0.5),
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

// ── Dialog save button ─────────────────────────────────────────────────────────
class _DialogSaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DialogSaveButton({required this.onTap});

  @override
  State<_DialogSaveButton> createState() => _DialogSaveButtonState();
}

class _DialogSaveButtonState extends State<_DialogSaveButton> {
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
            color: _h ? AppColors.orange.withOpacity(0.85) : AppColors.orange,
            borderRadius: BorderRadius.circular(10),
            boxShadow:
                _h
                    ? [
                      BoxShadow(
                        color: AppColors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                    : [],
          ),
          child: const Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mission tag chip ───────────────────────────────────────────────────────────
class _MissionTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MissionTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
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

// ── Fade route helper ──────────────────────────────────────────────────────────
PageRouteBuilder _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder:
        (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

class _Stat {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);
}

class _InfoRow {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});
}
