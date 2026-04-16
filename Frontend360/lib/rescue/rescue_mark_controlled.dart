import 'package:disaster360/colors.dart';
import 'package:disaster360/rescue/rescue_tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  MARK AS CONTROLLED SCREEN — Disaster360 Rescue Module
//
//  Opened from: RescueTasksScreen → Pending card → "Mark as Done" button.
//  Accepts a [RescueTask] and pre-fills all read-only task info at the top.
//
//  Form fields (all required before submit):
//    • Situation Summary     (multi-line text)
//    • Response Team Notes   (multi-line text)
//    • Damage Estimate (NPR) (numeric)
//    • Casualties            (text)
//    • Operation Duration    (text, e.g. "1h 24min")
//
//  On success  → Navigator.pop() back to RescueTasksScreen + success snackbar
//  On failure  → stays on this screen + error snackbar (simulated via flag)
// ═══════════════════════════════════════════════════════════════════════════════

class MarkAsControlledScreen extends StatefulWidget {
  final RescueTask task;

  const MarkAsControlledScreen({super.key, required this.task});

  @override
  State<MarkAsControlledScreen> createState() => _MarkAsControlledScreenState();
}

class _MarkAsControlledScreenState extends State<MarkAsControlledScreen>
    with SingleTickerProviderStateMixin {
  // ── Form controllers ───────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _situationCtrl = TextEditingController();
  final _teamNotesCtrl = TextEditingController();
  final _damageEstimateCtrl = TextEditingController();
  final _casualtiesCtrl = TextEditingController();
  final _operationDurationCtrl = TextEditingController();

  bool _isSubmitting = false;

  // ── Entrance animation ─────────────────────────────────────────────────────
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
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
    _situationCtrl.dispose();
    _teamNotesCtrl.dispose();
    _damageEstimateCtrl.dispose();
    _casualtiesCtrl.dispose();
    _operationDurationCtrl.dispose();
    super.dispose();
  }

  // ── Severity helpers (reused from tasks screen) ────────────────────────────
  static const _severityLabels = [
    '',
    'Low',
    'Moderate',
    'High',
    'Severe',
    'Extreme',
  ];
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

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    // Validate all fields
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate API call — replace with real service call
    await Future.delayed(const Duration(seconds: 2));

    // Simulate success (set to false to test failure path)
    const bool success = true;

    if (!mounted) return;

    if (success) {
      setState(() => _isSubmitting = false);
      // Navigate back to tasks screen and show success message
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.task_alt_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '#${widget.task.taskId} marked as controlled. Admin notified.',
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
      // Stay on screen — show error
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Submission failed. Please check your connection and try again.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.danger.withOpacity(0.92),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Hero icon ──────────────────────────────────────────────
                  _buildHeroIcon(),
                  const SizedBox(height: 16),

                  // ── Title ─────────────────────────────────────────────────
                  const Text(
                    'Mark as Controlled',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.task.type} — ${widget.task.location}',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // ── Task info card ─────────────────────────────────────────
                  _buildTaskInfoCard(),
                  const SizedBox(height: 28),

                  // ── Form fields ────────────────────────────────────────────
                  _buildSectionLabel('SITUATION SUMMARY'),
                  const SizedBox(height: 10),
                  _buildTextArea(
                    controller: _situationCtrl,
                    hint: 'Describe the current situation and outcome...',
                    maxLines: 4,
                    accentColor: AppColors.success,
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildSectionLabel('RESPONSE TEAM NOTES'),
                  const SizedBox(height: 10),
                  _buildTextArea(
                    controller: _teamNotesCtrl,
                    hint:
                        'Personnel deployed, equipment used, actions taken...',
                    maxLines: 3,
                    accentColor: AppColors.info,
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

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

                  _buildSectionLabel('CASUALTIES'),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _casualtiesCtrl,
                    hint: 'e.g. 0 deaths · 3 minor injuries',
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildSectionLabel('OPERATION DURATION'),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _operationDurationCtrl,
                    hint: 'e.g. 1h 24min',
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
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
        'Update Operation',
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

  // ── Hero icon ──────────────────────────────────────────────────────────────
  Widget _buildHeroIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.success.withOpacity(0.4), width: 2),
      ),
      child: const Icon(
        Icons.task_alt_rounded,
        color: AppColors.success,
        size: 36,
      ),
    );
  }

  // ── Task info card (read-only) ─────────────────────────────────────────────
  Widget _buildTaskInfoCard() {
    final sc = _severityColor(widget.task.severityLevel);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.tag,
            label: 'Task ID',
            value: '#${widget.task.taskId}',
          ),
          const Divider(height: 16, color: AppColors.border),
          _InfoRow(
            icon: Icons.report_outlined,
            label: 'Report ID',
            value: '#${widget.task.reportId}',
          ),
          const Divider(height: 16, color: AppColors.border),
          _InfoRow(
            icon: Icons.warning_amber_rounded,
            label: 'Type',
            value: widget.task.type,
          ),
          const Divider(height: 16, color: AppColors.border),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: widget.task.location,
          ),
          const Divider(height: 16, color: AppColors.border),
          _InfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Verified by',
            value: widget.task.verifiedByAdmin,
          ),
          const Divider(height: 16, color: AppColors.border),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                color: Colors.white38,
                size: 15,
              ),
              const SizedBox(width: 8),
              const Text(
                'Severity  ',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sc.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: sc,
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'L${widget.task.severityLevel} · ${_severityLabels[widget.task.severityLevel]}',
                      style: TextStyle(
                        color: sc,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
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
                      Icon(
                        Icons.task_alt_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Submit & Mark Controlled',
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
//  SHARED WIDGET — Info row used in task info card
// ══════════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
