import 'package:disaster360/colors.dart';
import 'package:disaster360/rescue/rescue_motion.dart';
import 'package:disaster360/rescue/rescue_tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  POST-DISASTER REPORT SCREEN — Disaster360 Rescue Module
//
//  Accessible from: RescueTasksScreen → Completed card → "Send Completion Report"
//  OR from a dedicated menu entry (standalone).
//
//  Features:
//    • Dropdown to select any completed task (pre-filled if navigated from a card)
//    • Selecting a task shows its basic info (ID, type, location, date, severity)
//    • Form fields:
//        - Incident Summary         (multi-line)
//        - Response Details         (multi-line)
//        - Infrastructure Damage    (multi-line)
//        - Damage Estimate (NPR)    (numeric)
//        - Casualties               (text)
//    • Info note: "This report feeds into future risk zone analysis..."
//    • On success → snackbar + all fields cleared
//    • On failure → stays on screen with error snackbar
// ═══════════════════════════════════════════════════════════════════════════════

class PostDisasterReportScreen extends StatefulWidget {
  /// If opened from a completed task card, pass the task here to pre-select it.
  final RescueTask? preSelectedTask;

  const PostDisasterReportScreen({super.key, this.preSelectedTask});

  @override
  State<PostDisasterReportScreen> createState() =>
      _PostDisasterReportScreenState();
}

class _PostDisasterReportScreenState extends State<PostDisasterReportScreen>
    with SingleTickerProviderStateMixin {
  // ── Completed tasks (same data as rescue_tasks_screen, filtered) ───────────
  final List<RescueTask> _completedTasks = [];

  // ── State ──────────────────────────────────────────────────────────────────
  RescueTask? _selectedTask;
  bool _isSubmitting = false;
  bool _dropdownOpen = false;

  // ── Form controllers ───────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _incidentSummaryCtrl = TextEditingController();
  final _responseDetailsCtrl = TextEditingController();
  final _infrastructureCtrl = TextEditingController();
  final _damageEstimateCtrl = TextEditingController();
  final _casualtiesCtrl = TextEditingController();

  // ── Entrance animation ─────────────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Pre-select task if navigated from a card
    if (widget.preSelectedTask != null) {
      _selectedTask = widget.preSelectedTask;
    }

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _incidentSummaryCtrl.dispose();
    _responseDetailsCtrl.dispose();
    _infrastructureCtrl.dispose();
    _damageEstimateCtrl.dispose();
    _casualtiesCtrl.dispose();
    super.dispose();
  }

  // ── Severity color helper ──────────────────────────────────────────────────
  Color _severityColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFF4CAF50);
      case 2:
        return const Color(0xFF8BC34A);
      case 3:
        return AppColors.warning;
      case 4:
        return AppColors.orange;
      case 5:
        return AppColors.danger;
      default:
        return Colors.white38;
    }
  }

  static const _severityLabels = [
    '',
    'Low',
    'Moderate',
    'High',
    'Severe',
    'Extreme',
  ];

  // ── Clear all form fields ──────────────────────────────────────────────────
  void _clearForm() {
    setState(() => _selectedTask = null);
    _incidentSummaryCtrl.clear();
    _responseDetailsCtrl.clear();
    _infrastructureCtrl.clear();
    _damageEstimateCtrl.clear();
    _casualtiesCtrl.clear();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_selectedTask == null) {
      _showSnack(
        'Please select a completed task first.',
        color: AppColors.warning,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate API call — replace with real service call
    await Future.delayed(const Duration(seconds: 2));

    // Simulate success (set to false to test failure path)
    const bool success = true;

    if (!mounted) return;

    if (success) {
      final taskId = _selectedTask!.taskId;
      _clearForm();
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Post-disaster report for #$taskId submitted successfully.',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success.withOpacity(0.92),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      setState(() => _isSubmitting = false);
      _showSnack(
        'Submission failed. Check your connection and try again.',
        color: AppColors.danger,
      );
    }
  }

  void _showSnack(String msg, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: color.withOpacity(0.92),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Select task dropdown ───────────────────────────────────
                  _buildSectionLabel('SELECT COMPLETED OPERATION'),
                  const SizedBox(height: 10),
                  _buildTaskDropdown(),

                  // ── Selected task preview card ─────────────────────────────
                  if (_selectedTask != null) ...[
                    const SizedBox(height: 14),
                    _buildTaskPreviewCard(_selectedTask!),
                  ],
                  const SizedBox(height: 28),

                  // ── Incident Summary ───────────────────────────────────────
                  _buildSectionLabel('INCIDENT SUMMARY'),
                  const SizedBox(height: 10),
                  _buildTextArea(
                    controller: _incidentSummaryCtrl,
                    hint: 'Describe the incident, cause, and initial impact...',
                    maxLines: 4,
                    accentColor: AppColors.info,
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Response Details ───────────────────────────────────────
                  _buildSectionLabel('RESPONSE DETAILS'),
                  const SizedBox(height: 10),
                  _buildTextArea(
                    controller: _responseDetailsCtrl,
                    hint:
                        'Personnel deployed, equipment used, civilians evacuated...',
                    maxLines: 4,
                    accentColor: AppColors.info,
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Infrastructure Damage ──────────────────────────────────
                  _buildSectionLabel('INFRASTRUCTURE DAMAGE'),
                  const SizedBox(height: 10),
                  _buildTextArea(
                    controller: _infrastructureCtrl,
                    hint: 'Roads, bridges, buildings, utilities affected...',
                    maxLines: 3,
                    accentColor: AppColors.warning,
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Damage Estimate ────────────────────────────────────────
                  _buildSectionLabel('DAMAGE ESTIMATE (NPR)'),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _damageEstimateCtrl,
                    hint: 'e.g. 150,000',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                    ],
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Casualties ─────────────────────────────────────────────
                  _buildSectionLabel('CASUALTIES'),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _casualtiesCtrl,
                    hint: 'e.g. 0 deaths · 3 minor injuries',
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  // ── Info note ──────────────────────────────────────────────
                  _buildInfoNote(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),

      // ── Sticky submit button ─────────────────────────────────────────────
      bottomNavigationBar: _buildSubmitBar(),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgSurface,
      elevation: 0,
      titleSpacing: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
      ),
      title: const Text(
        'Post-Disaster Report',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  // ── Task dropdown ──────────────────────────────────────────────────────────
  Widget _buildTaskDropdown() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showTaskPicker(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  _dropdownOpen
                      ? AppColors.info
                      : (_selectedTask != null
                          ? AppColors.success.withOpacity(0.6)
                          : AppColors.border),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _selectedTask != null
                    ? Icons.task_alt_rounded
                    : Icons.assignment_outlined,
                color:
                    _selectedTask != null ? AppColors.success : Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    _selectedTask == null
                        ? const Text(
                          'Select a completed operation...',
                          style: TextStyle(color: Colors.white30, fontSize: 14),
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${_selectedTask!.taskId} · ${_selectedTask!.type}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedTask!.location,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white38,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Task picker bottom sheet ───────────────────────────────────────────────
  void _showTaskPicker(BuildContext context) {
    setState(() => _dropdownOpen = true);
    RescueMotion.showSweetBottomSheet(
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Completed Operation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Only controlled / completed tasks are listed below',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ..._completedTasks.map((task) {
                  final sc = _severityColor(task.severityLevel);
                  final isSelected = _selectedTask?.taskId == task.taskId;
                  return _TaskPickerTile(
                    task: task,
                    severityColor: sc,
                    severityLabel: _severityLabels[task.severityLevel],
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedTask = task;
                        _dropdownOpen = false;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
    ).whenComplete(() => setState(() => _dropdownOpen = false));
  }

  // ── Selected task preview card ─────────────────────────────────────────────
  Widget _buildTaskPreviewCard(RescueTask task) {
    final sc = _severityColor(task.severityLevel);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Operation #${task.taskId} — Controlled',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${task.type}, ${task.location} · Completed ${task.assignedAgo}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Report ID
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Text(
                  '#${task.reportId}',
                  style: const TextStyle(
                    color: AppColors.info,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Severity
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: sc.withOpacity(0.3)),
                ),
                child: Text(
                  'L${task.severityLevel} · ${_severityLabels[task.severityLevel]}',
                  style: TextStyle(
                    color: sc,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Verified by
              Expanded(
                child: Text(
                  'Verified: ${task.verifiedByAdmin}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Info note ──────────────────────────────────────────────────────────────
  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This report feeds into future risk zone analysis and community preparedness planning. Accurate data helps save lives.',
              style: TextStyle(
                color: AppColors.info,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }

  // ── Multi-line text area ───────────────────────────────────────────────────
  Widget _buildTextArea({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required Color accentColor,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        height: 1.5,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: AppColors.bgSurface,
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
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  // ── Single-line text field ─────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: AppColors.bgSurface,
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
          borderSide: const BorderSide(color: AppColors.success, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  // ── Sticky submit button ───────────────────────────────────────────────────
  Widget _buildSubmitBar() {
    return Container(
      color: AppColors.bgPrimary,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            disabledBackgroundColor: AppColors.success.withOpacity(0.45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Submit Post-Disaster Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
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
//  TASK PICKER TILE — inside the bottom-sheet picker
// ══════════════════════════════════════════════════════════════════════════════

class _TaskPickerTile extends StatefulWidget {
  final RescueTask task;
  final Color severityColor;
  final String severityLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaskPickerTile({
    required this.task,
    required this.severityColor,
    required this.severityLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TaskPickerTile> createState() => _TaskPickerTileState();
}

class _TaskPickerTileState extends State<_TaskPickerTile> {
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
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                widget.isSelected
                    ? AppColors.success.withOpacity(0.12)
                    : (_hovered ? AppColors.bgDark : AppColors.bgPrimary),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  widget.isSelected
                      ? AppColors.success.withOpacity(0.5)
                      : (_hovered
                          ? AppColors.border
                          : AppColors.border.withOpacity(0.5)),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${widget.task.taskId} · ${widget.task.type}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.task.location,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Tags
                    Row(
                      children: [
                        _MiniTag(
                          label: '#${widget.task.reportId}',
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 6),
                        _MiniTag(
                          label:
                              'L${widget.task.severityLevel} ${widget.severityLabel}',
                          color: widget.severityColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

