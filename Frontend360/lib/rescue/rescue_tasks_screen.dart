import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:disaster360/colors.dart';
import 'package:disaster360/rescue/rescue_disaster_report.dart';
import 'package:disaster360/rescue/rescue_mark_controlled.dart';
import 'package:disaster360/rescue/rescue_motion.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  RESCUE TASKS SCREEN — Disaster360
//  • Search bar + filter tabs: All / Active / Pending / Completed
//  • Case A — Active:    Severity, Verified by admin, Accept + Details buttons
//  • Case B — Pending:   Severity, Verified by admin, Status Report + Mark as Done + Details buttons
//  • Case C — Completed: Severity, Verified by admin, Send Completion Report + Details buttons
//  • Case D — All:       Active first → Pending → Completed
//  • Emergency-themed Active cards (pulsing red left border)
//  • Basic hover + tap animations, hand cursor
//  • AppColors from existing codebase
//  • Image gallery: two-image grid with +N overlay, full-screen swipe gallery (same as citizen home)
// ═══════════════════════════════════════════════════════════════════════════════

class RescueTasksScreen extends StatefulWidget {
  const RescueTasksScreen({super.key});

  @override
  State<RescueTasksScreen> createState() => _RescueTasksScreenState();
}

class _RescueTasksScreenState extends State<RescueTasksScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final List<String> _filters = ['All', 'Active', 'Pending', 'Completed'];

  // ── Sample task data ───────────────────────────────────────────────────────
  final List<RescueTask> _allTasks = [];

  List<RescueTask> get _filteredTasks {
    List<RescueTask> list;

    if (_selectedFilter == 'All') {
      final active =
          _allTasks.where((t) => t.status == TaskStatus.active).toList();
      final pending =
          _allTasks.where((t) => t.status == TaskStatus.pending).toList();
      final completed =
          _allTasks.where((t) => t.status == TaskStatus.completed).toList();
      list = [...active, ...pending, ...completed];
    } else {
      final statusMap = {
        'Active': TaskStatus.active,
        'Pending': TaskStatus.pending,
        'Completed': TaskStatus.completed,
      };
      list =
          _allTasks
              .where((t) => t.status == statusMap[_selectedFilter])
              .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list =
          list
              .where(
                (t) =>
                    t.taskId.toLowerCase().contains(q) ||
                    t.type.toLowerCase().contains(q) ||
                    t.location.toLowerCase().contains(q),
              )
              .toList();
    }

    return list;
  }

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 14),
                  _buildFilterTabs(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child:
                  _filteredTasks.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _filteredTasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final task = _filteredTasks[i];
                          return _TaskCard(
                            task: task,
                            pulseAnim: _pulseAnim,
                            onAccept: () => _handleAccept(context, task),
                            onDetails: () => _handleDetails(context, task),
                            onStatusReport:
                                () => _handleStatusReport(context, task),
                            onMarkDone: () => _handleMarkDone(context, task),
                            onCompletionReport:
                                () => _handleCompletionReport(context, task),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My Tasks',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
          ),
        ),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder:
              (_, __) => Opacity(
                opacity: _pulseAnim.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.danger.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_allTasks.where((t) => t.status == TaskStatus.active).length} Active',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ],
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.white30, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── Filter tabs ────────────────────────────────────────────────────────────
  Widget _buildFilterTabs() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children:
            _filters.map((filter) {
              final isActive = _selectedFilter == filter;
              Color activeColor;
              switch (filter) {
                case 'Active':
                  activeColor = AppColors.danger;
                  break;
                case 'Pending':
                  activeColor = AppColors.warning;
                  break;
                case 'Completed':
                  activeColor = AppColors.success;
                  break;
                default:
                  activeColor = AppColors.orange;
              }

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? activeColor : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isActive
                                ? activeColor
                                : Colors.white.withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white54,
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, color: Colors.white24, size: 56),
          const SizedBox(height: 14),
          const Text(
            'No tasks found',
            style: TextStyle(color: Colors.white38, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── Button handlers ────────────────────────────────────────────────────────
  void _handleAccept(BuildContext context, RescueTask task) {
    _showActionDialog(
      context: context,
      title: 'Accept Task',
      message:
          'Are you sure you want to accept ${task.taskId}?\nYou will be deployed to ${task.location}.',
      confirmLabel: 'Accept',
      confirmColor: AppColors.success,
      onConfirm: () {
        Navigator.pop(context);
        _showSnack(
          context,
          '✓ Task ${task.taskId} accepted. Head to ${task.location}.',
          color: AppColors.success,
        );
      },
    );
  }

  void _handleDetails(BuildContext context, RescueTask task) {
    _showTaskDetailSheet(context, task);
  }

  void _handleStatusReport(BuildContext context, RescueTask task) {
    _showStatusReportSheet(context, task);
  }

  void _handleMarkDone(BuildContext context, RescueTask task) {
    RescueMotion.push(context, MarkAsControlledScreen(task: task));
  }

  void _handleCompletionReport(BuildContext context, RescueTask task) {
    RescueMotion.push(context, PostDisasterReportScreen(preSelectedTask: task));
  }

  void _showSnack(BuildContext context, String msg, {required Color color}) {
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

  void _showActionDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    RescueMotion.showSweetDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            content: Text(
              message,
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
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  confirmLabel,
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

  void _showTaskDetailSheet(BuildContext context, RescueTask task) {
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
                            '#${task.taskId}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                          _TaskStatusBadge(status: task.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${task.type} — ${task.location}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
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
                              icon: Icons.local_fire_department_outlined,
                              label: 'Severity',
                              widget: _SeverityBadge(level: task.severityLevel),
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              icon: Icons.verified_user_outlined,
                              label: 'Verified by Admin',
                              value: task.verifiedByAdmin,
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              icon: Icons.location_on_outlined,
                              label: 'GPS',
                              value: '${task.lat}, ${task.lng}',
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              icon: Icons.report_outlined,
                              label: 'Report ID',
                              value: '#${task.reportId}',
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              icon: Icons.image_outlined,
                              label: 'Photos',
                              value: '${task.photoCount} attached',
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              icon: Icons.access_time_outlined,
                              label: 'Assigned',
                              value: task.assignedAgo,
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

  void _showStatusReportSheet(BuildContext context, RescueTask task) {
    final noteCtrl = TextEditingController();
    String selectedStatus = 'On Scene';
    final statuses = [
      'En Route',
      'On Scene',
      'Rescue Ongoing',
      'Awaiting Support',
    ];

    RescueMotion.showSweetBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder:
                  (ctx, setLS) => Container(
                    decoration: const BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: _sheetHandle()),
                        const SizedBox(height: 16),
                        const Text(
                          'Submit Status Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${task.taskId} · ${task.location}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Current Status',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              statuses.map((s) {
                                final sel = selectedStatus == s;
                                return GestureDetector(
                                  onTap: () => setLS(() => selectedStatus = s),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          sel
                                              ? AppColors.info.withOpacity(0.2)
                                              : AppColors.bgPrimary,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            sel
                                                ? AppColors.info
                                                : AppColors.border,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      s,
                                      style: TextStyle(
                                        color:
                                            sel
                                                ? AppColors.info
                                                : Colors.white54,
                                        fontSize: 12,
                                        fontWeight:
                                            sel
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Notes / Observations',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: noteCtrl,
                          maxLines: 3,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Describe current situation on the ground...',
                            hintStyle: const TextStyle(
                              color: Colors.white24,
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: AppColors.bgPrimary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.info,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showSnack(
                                context,
                                '✓ Status report submitted: $selectedStatus',
                                color: AppColors.info,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.info,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Submit Report',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
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

  void _showCompletionReportSheet(BuildContext context, RescueTask task) {
    final summaryCtrl = TextEditingController();
    final casualtiesCtrl = TextEditingController();

    RescueMotion.showSweetBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.task_alt_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Completion Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#${task.taskId} · ${task.location}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'MISSION SUMMARY',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: summaryCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Describe what was done and the outcome...',
                      hintStyle: const TextStyle(
                        color: Colors.white24,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.bgPrimary,
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
                        borderSide: const BorderSide(
                          color: AppColors.success,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CASUALTIES / INJURIES',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: casualtiesCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. No casualties. 2 minor injuries treated.',
                      hintStyle: const TextStyle(
                        color: Colors.white24,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.bgPrimary,
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
                        borderSide: const BorderSide(
                          color: AppColors.success,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSnack(
                          context,
                          '✓ Completion report sent to admin.',
                          color: AppColors.success,
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text(
                        'Send Completion Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
}

// ══════════════════════════════════════════════════════════════════════════════
//  FULL-SCREEN IMAGE VIEWER OVERLAY (identical to citizen home)
// ══════════════════════════════════════════════════════════════════════════════

class _ImageViewerOverlay extends StatefulWidget {
  final int photoCount;
  final int initialIndex;
  final String reportId;

  const _ImageViewerOverlay({
    required this.photoCount,
    required this.initialIndex,
    required this.reportId,
  });

  @override
  State<_ImageViewerOverlay> createState() => _ImageViewerOverlayState();
}

class _ImageViewerOverlayState extends State<_ImageViewerOverlay>
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
              if (_currentIndex < widget.photoCount - 1) {
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

          // Full-screen swipeable image pages – edge‑to‑edge
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.photoCount,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) {
              return Container(
                color: AppColors.bgDark,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        color: Colors.white.withOpacity(0.2),
                        size: 72,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Photo ${i + 1}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '#${widget.reportId}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Next/Prev Arrows (Desktop navigation)
          if (widget.photoCount > 1) ...[
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
            if (_currentIndex < widget.photoCount - 1)
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
                      'Photo ${_currentIndex + 1} of ${widget.photoCount}',
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
          if (widget.photoCount > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.photoCount, (i) {
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
//  TASK CARD — with two‑image grid + full‑screen viewer
// ══════════════════════════════════════════════════════════════════════════════

class _TaskCard extends StatefulWidget {
  final RescueTask task;
  final Animation<double> pulseAnim;
  final VoidCallback onAccept;
  final VoidCallback onDetails;
  final VoidCallback onStatusReport;
  final VoidCallback onMarkDone;
  final VoidCallback onCompletionReport;

  const _TaskCard({
    required this.task,
    required this.pulseAnim,
    required this.onAccept,
    required this.onDetails,
    required this.onStatusReport,
    required this.onMarkDone,
    required this.onCompletionReport,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _hovered = false;

  Color get _statusAccent {
    switch (widget.task.status) {
      case TaskStatus.active:
        return AppColors.danger;
      case TaskStatus.pending:
        return AppColors.warning;
      case TaskStatus.completed:
        return AppColors.success;
    }
  }

  void _openImageViewer(int index) {
    final count = widget.task.photoCount.clamp(1, 5);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder:
          (_, __, ___) => _ImageViewerOverlay(
            photoCount: count,
            initialIndex: index,
            reportId: widget.task.reportId,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.task.status == TaskStatus.active;
    final isPending = widget.task.status == TaskStatus.pending;
    final isCompleted = widget.task.status == TaskStatus.completed;
    final photoCount = widget.task.photoCount.clamp(1, 5);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 0),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _hovered
                        ? _statusAccent.withOpacity(0.4)
                        : AppColors.border,
                width: 1,
              ),
              boxShadow:
                  _hovered
                      ? [
                        BoxShadow(
                          color: _statusAccent.withOpacity(0.08),
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
                  // Top row
                  Row(
                    children: [
                      if (isActive) ...[
                        AnimatedBuilder(
                          animation: widget.pulseAnim,
                          builder:
                              (_, __) => Opacity(
                                opacity: widget.pulseAnim.value,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                        ),
                      ],
                      Text(
                        '#${widget.task.taskId}',
                        style: TextStyle(
                          color:
                              isActive
                                  ? AppColors.danger.withOpacity(0.85)
                                  : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TaskStatusBadge(status: widget.task.status),
                      const Spacer(),
                      Text(
                        widget.task.assignedAgo,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Type + location
                  Text(
                    widget.task.type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white38,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.task.location,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    widget.task.description,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Severity + Verified by
                  Row(
                    children: [
                      _SeverityBadge(level: widget.task.severityLevel),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.verified_user_outlined,
                        color: Colors.white38,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Admin: ${widget.task.verifiedByAdmin}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── TWO-IMAGE GRID (same as citizen home) ───────────────
                  if (photoCount > 0) _buildImageGrid(photoCount),
                  if (photoCount > 0) const SizedBox(height: 14),

                  // Action buttons
                  if (isActive)
                    _buildActiveButtons()
                  else if (isPending)
                    _buildPendingButtons()
                  else if (isCompleted)
                    _buildCompletedButtons(),
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
              width: isActive ? 4 : 3,
              decoration: BoxDecoration(
                color: _statusAccent,
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

  // ── TWO-IMAGE GRID (identical to citizen home) ────────────────────────────
  Widget _buildImageGrid(int totalPhotos) {
    final actualCount = totalPhotos.clamp(1, 5);
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
                    // Placeholder image content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          color:
                              isLast
                                  ? Colors.white10
                                  : Colors.white.withOpacity(0.2),
                          size: 32,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Photo ${i + 1}',
                          style: TextStyle(
                            color:
                                isLast
                                    ? Colors.white10
                                    : Colors.white.withOpacity(0.22),
                            fontSize: 11,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
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

  Widget _buildActiveButtons() {
    return Row(
      children: [
        Expanded(
          child: _TaskButton(
            label: 'Accept',
            icon: Icons.check_rounded,
            color: AppColors.success,
            onTap: widget.onAccept,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TaskButton(
            label: 'Details',
            icon: Icons.info_outline_rounded,
            color: Colors.white54,
            outlined: true,
            onTap: widget.onDetails,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TaskButton(
                label: 'Status Report',
                icon: Icons.assessment_outlined,
                color: AppColors.info,
                onTap: widget.onStatusReport,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TaskButton(
                label: 'Mark as Done',
                icon: Icons.task_alt_rounded,
                color: AppColors.success,
                onTap: widget.onMarkDone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _TaskButton(
          label: 'Details',
          icon: Icons.info_outline_rounded,
          color: Colors.white54,
          outlined: true,
          fullWidth: true,
          onTap: widget.onDetails,
        ),
      ],
    );
  }

  Widget _buildCompletedButtons() {
    return Row(
      children: [
        Expanded(
          child: _TaskButton(
            label: 'Completion Report',
            icon: Icons.send_rounded,
            color: AppColors.success,
            onTap: widget.onCompletionReport,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TaskButton(
            label: 'Details',
            icon: Icons.info_outline_rounded,
            color: Colors.white54,
            outlined: true,
            onTap: widget.onDetails,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TASK BUTTON — animated tap + hover (unchanged)
// ══════════════════════════════════════════════════════════════════════════════

class _TaskButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final bool fullWidth;
  final VoidCallback onTap;

  const _TaskButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
    this.fullWidth = false,
  });

  @override
  State<_TaskButton> createState() => _TaskButtonState();
}

class _TaskButtonState extends State<_TaskButton>
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
            width: widget.fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color:
                  widget.outlined
                      ? (_hovered
                          ? Colors.white.withOpacity(0.06)
                          : Colors.transparent)
                      : (_hovered
                          ? widget.color.withOpacity(0.28)
                          : widget.color.withOpacity(0.18)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    widget.outlined
                        ? (_hovered ? Colors.white54 : AppColors.border)
                        : widget.color.withOpacity(_hovered ? 0.7 : 0.45),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color:
                      widget.outlined
                          ? (_hovered ? Colors.white70 : Colors.white54)
                          : widget.color,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          widget.outlined
                              ? (_hovered ? Colors.white70 : Colors.white54)
                              : widget.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

// ══════════════════════════════════════════════════════════════════════════════
//  SUPPORTING WIDGETS (unchanged)
// ══════════════════════════════════════════════════════════════════════════════

class _TaskStatusBadge extends StatelessWidget {
  final TaskStatus status;
  const _TaskStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, text;
    String label;
    switch (status) {
      case TaskStatus.active:
        bg = AppColors.danger.withOpacity(0.18);
        text = AppColors.danger;
        label = 'Active';
        break;
      case TaskStatus.pending:
        bg = AppColors.warning.withOpacity(0.15);
        text = AppColors.warning;
        label = 'Pending';
        break;
      case TaskStatus.completed:
        bg = AppColors.success.withOpacity(0.15);
        text = AppColors.success;
        label = 'Completed';
        break;
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
}

class _SeverityBadge extends StatelessWidget {
  final int level;
  const _SeverityBadge({required this.level});

  static const _labels = ['', 'Low', 'Moderate', 'High', 'Severe', 'Extreme'];

  Color get _color {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, color: _color, size: 11),
          const SizedBox(width: 4),
          Text(
            'L$level · ${_labels[level]}',
            style: TextStyle(
              color: _color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? widget;

  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.widget,
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
          child:
              widget != null
                  ? Align(alignment: Alignment.centerRight, child: widget!)
                  : Text(
                    value ?? '',
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

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS (unchanged)
// ══════════════════════════════════════════════════════════════════════════════

enum TaskStatus { active, pending, completed }

class RescueTask {
  final String taskId;
  final TaskStatus status;
  final String type;
  final String location;
  final String description;
  final String assignedAgo;
  final int severityLevel;
  final String verifiedByAdmin;
  final int photoCount;
  final String lat;
  final String lng;
  final String reportId;

  const RescueTask({
    required this.taskId,
    required this.status,
    required this.type,
    required this.location,
    required this.description,
    required this.assignedAgo,
    required this.severityLevel,
    required this.verifiedByAdmin,
    required this.photoCount,
    required this.lat,
    required this.lng,
    required this.reportId,
  });
}

