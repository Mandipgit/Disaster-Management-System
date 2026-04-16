import 'package:disaster360/colors.dart';
import 'package:flutter/material.dart';

class OfflineSupportScreen extends StatefulWidget {
  final bool isInDialog;
  const OfflineSupportScreen({super.key, this.isInDialog = false});

  @override
  State<OfflineSupportScreen> createState() => _OfflineSupportScreenState();
}

class _OfflineSupportScreenState extends State<OfflineSupportScreen>
    with SingleTickerProviderStateMixin {
  bool _isSyncing = false;
  bool _syncDone = false;

  // Simulated pending offline reports
  final List<_OfflineReport> _pendingReports = [
    _OfflineReport(
      title: 'Landslide — Bhedetar (Saved)',
      subtitle: 'Will sync on reconnect',
      status: 'Pending',
    ),
    _OfflineReport(
      title: 'Flood — Ward 5, Dharan (Saved)',
      subtitle: 'Will sync on reconnect',
      status: 'Pending',
    ),
  ];

  Future<void> _handleSync() async {
    setState(() {
      _isSyncing = true;
      _syncDone = false;
    });
    // Simulate a network sync delay
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isSyncing = false;
      _syncDone = true;
    });
    // Reset after 2 s
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _syncDone = false);
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (widget.isInDialog) {
      // Dialog mode: no Scaffold, no AppBar
      return content;
    } else {
      // Full‑screen mode
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: _buildAppBar(context),
        body: content,
      );
    }
  }

  // Extract the main content to reuse in both modes
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNoInternetBanner(),
          const SizedBox(height: 28),
          _buildSectionLabel('SMS REPORTING'),
          const SizedBox(height: 12),
          _buildSmsCard(),
          const SizedBox(height: 28),
          _buildSectionLabel('OFFLINE MAP PREVIEW'),
          const SizedBox(height: 12),
          _buildMapPreviewCard(),
          const SizedBox(height: 28),
          _buildSectionLabel('PENDING OFFLINE REPORTS'),
          const SizedBox(height: 12),
          ..._pendingReports.map((r) => _buildPendingReport(r)),
          const SizedBox(height: 20),
          _buildSyncButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── App bar (only used in full‑screen mode) ────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      titleSpacing: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
      ),
      title: const Text(
        'Offline Support',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  // ── No internet banner (unchanged) ─────────────────────────────────────────
  Widget _buildNoInternetBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt, color: AppColors.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'No Internet Detected',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You can still report disasters via SMS or save offline and sync later.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label (unchanged) ──────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  // ── SMS reporting card (unchanged) ─────────────────────────────────────────
  Widget _buildSmsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.white70, fontSize: 14),
              children: [
                TextSpan(text: 'Send SMS to '),
                TextSpan(
                  text: '10XXXX',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
                TextSpan(text: ' in this format:'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'DISASTER <TYPE> <LOCATION> <DESC>',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Example: DISASTER FLOOD WARD5 DHARAN River overflow near bridge',
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Offline map preview (unchanged) ────────────────────────────────────────
  Widget _buildMapPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: const [
          Text(
            'Cached Map — Sunsari District',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Last synced: Mar 17, 9:00 AM',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Pending offline report tile (unchanged) ────────────────────────────────
  Widget _buildPendingReport(_OfflineReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  report.subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sync Now button (unchanged) ────────────────────────────────────────────
  Widget _buildSyncButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isSyncing ? null : _handleSync,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: _syncDone ? AppColors.success : Colors.white24,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon:
            _isSyncing
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                  ),
                )
                : Icon(
                  _syncDone ? Icons.check_circle_outline : Icons.sync,
                  color: _syncDone ? AppColors.success : Colors.white70,
                  size: 18,
                ),
        label: Text(
          _isSyncing
              ? 'Syncing...'
              : _syncDone
              ? 'Synced!'
              : 'Sync Now',
          style: TextStyle(
            color: _syncDone ? AppColors.success : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Data model (unchanged) ───────────────────────────────────────────────────
class _OfflineReport {
  final String title;
  final String subtitle;
  final String status;

  const _OfflineReport({
    required this.title,
    required this.subtitle,
    required this.status,
  });
}
