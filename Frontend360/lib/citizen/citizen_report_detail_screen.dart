import 'package:disaster360/colors.dart';
import 'package:flutter/material.dart';
import 'citizen_home_screen.dart';

import 'package:disaster360/providers/report_provider.dart';

class CitizenReportDetailScreen extends StatelessWidget {
  final ReportModel report;

  const CitizenReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Submitted',
      'Pending',
      'Verified',
      'In Progress',
      'Controlled',
    ];
    final currentIndex = _currentStepIndex(report.status, steps);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportCard(),
            const SizedBox(height: 14),
            _buildLocationCard(),
            const SizedBox(height: 14),
            _buildReporterCard(),
            const SizedBox(height: 14),
            _buildVoteRow(),
            const SizedBox(height: 14),
            _buildStatusTimeline(steps, currentIndex),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      titleSpacing: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
      ),
      title: Text(
        'Report #${report.id}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.disasterType,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _StatusBadge(status: report.status),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            report.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            report.description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white38, size: 14),
              const SizedBox(width: 5),
              Text(
                _relativeDate(report.createdAt),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.location_on_outlined,
                color: Colors.white38,
                size: 14,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                '${report.latitude}, ${report.longitude}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
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
          if (report.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Attached Media',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: report.mediaUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      report.mediaUrls[index],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        height: 120,
                        color: Colors.white12,
                        child: const Icon(Icons.broken_image, color: Colors.white38),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.image_outlined, color: Colors.white38, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'No photos attached',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReporterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.submissions.isNotEmpty ? report.submissions.first['user_name'] ?? 'Citizen Reporter' : 'Citizen Reporter',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.thumb_up_outlined,
                  color: AppColors.successGreen,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  '${report.likes}  Upvotes',
                  style: const TextStyle(
                    color: AppColors.successGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.thumb_down_outlined,
                  color: AppColors.danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  '${report.dislikes}  Downvotes',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTimeline(List<String> steps, int currentIndex) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS TIMELINE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(steps.length, (i) {
            final isDone = i <= currentIndex;
            final isCurrent = i == currentIndex;
            final isLast = i == steps.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: dot + line
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isDone ? AppColors.success : Colors.transparent,
                            border: Border.all(
                              color:
                                  isDone ? AppColors.success : Colors.white24,
                              width: 2,
                            ),
                          ),
                          child:
                              isDone
                                  ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 8,
                                  )
                                  : null,
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color:
                                  isDone && i < currentIndex
                                      ? AppColors.success
                                      : Colors.white12,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Label
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      isCurrent ? '${steps[i]} (Current)' : steps[i],
                      style: TextStyle(
                        color:
                            isDone
                                ? (isCurrent ? AppColors.success : Colors.white)
                                : Colors.white30,
                        fontSize: 14,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
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
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return dateStr.split("T").first;
    }
  }

  int _currentStepIndex(String status, List<String> steps) {
    switch (status) {
      case 'Pending':
        return 1;
      case 'Verified':
        return 2;
      case 'In Progress':
        return 3;
      case 'Controlled':
        return 4;
      default:
        return 0; // Submitted
    }
  }
}

// ─── Reused badge widget ──────────────────────────────────────────────────────

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
        bg = AppColors.success.withOpacity(0.15);
        text = AppColors.success;
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
