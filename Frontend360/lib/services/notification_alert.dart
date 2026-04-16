import 'package:disaster360/colors.dart';
import 'package:flutter/material.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

enum NotificationType {
  proximityAlert,
  reportVerified,
  statusUpdate,
  riskZone,
  reportRejected,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  String get typeLabel {
    switch (type) {
      case NotificationType.proximityAlert:
        return 'PROXIMITY ALERT';
      case NotificationType.reportVerified:
        return 'REPORT VERIFIED';
      case NotificationType.statusUpdate:
        return 'STATUS UPDATE';
      case NotificationType.riskZone:
        return 'RISK ZONE UPDATE';
      case NotificationType.reportRejected:
        return 'REPORT REJECTED';
    }
  }

  Color get accentColor {
    switch (type) {
      case NotificationType.proximityAlert:
        return AppColors.danger;
      case NotificationType.reportVerified:
        return AppColors.success;
      case NotificationType.statusUpdate:
        return AppColors.warning;
      case NotificationType.riskZone:
        return AppColors.info;
      case NotificationType.reportRejected:
        return AppColors.warning;
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.proximityAlert:
        return Icons.warning_amber_rounded;
      case NotificationType.reportVerified:
        return Icons.verified_outlined;
      case NotificationType.statusUpdate:
        return Icons.update_rounded;
      case NotificationType.riskZone:
        return Icons.location_on_outlined;
      case NotificationType.reportRejected:
        return Icons.cancel_outlined;
    }
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'N001',
      type: NotificationType.proximityAlert,
      title: 'Landslide 0.8km from you, Ward 7 Dharan',
      body:
          'A verified landslide has been reported very close to your current location. Move to higher ground immediately and avoid the area.',
      time: '2 hours ago',
      isRead: false,
    ),
    AppNotification(
      id: 'N002',
      type: NotificationType.reportVerified,
      title: '#RPT-00389 Landslide report has been verified by admin',
      body:
          'Your submitted report has passed verification. Response teams have been notified and are being dispatched to the area.',
      time: '5 hours ago',
      isRead: false,
    ),
    AppNotification(
      id: 'N003',
      type: NotificationType.statusUpdate,
      title: 'Flood Team B is now on scene at Itahari',
      body:
          'Emergency response Team B has arrived at Itahari, Ward 3. Rescue operations are underway. Residents in affected areas please cooperate.',
      time: '6 hours ago',
      isRead: false,
    ),
    AppNotification(
      id: 'N004',
      type: NotificationType.riskZone,
      title: 'Ward 7, Dharan elevated to High Risk zone',
      body:
          'Based on recent incident density and verified reports, Ward 7 Dharan has been reclassified as a High Risk zone. Exercise extreme caution.',
      time: 'Yesterday',
      isRead: true,
    ),
    AppNotification(
      id: 'N005',
      type: NotificationType.reportRejected,
      title: '#RPT-00371 was merged with existing report',
      body:
          'Your report was found to be a duplicate of an existing verified report for the same area. No action is needed from you.',
      time: 'Mar 9',
      isRead: true,
    ),
  ];

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _showDetail(AppNotification notification) {
    final captured = notification;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _NotificationDetailSheet(notification: captured),
    ).then((_) {
      if (!captured.isRead && mounted) {
        setState(() => captured.isRead = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(context),
      body:
          _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder:
                    (_, i) => _NotificationCard(
                      notification: _notifications[i],
                      onTap: () => _showDetail(_notifications[i]),
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
      title: Row(
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (_unreadCount > 0)
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: Colors.white24,
            size: 52,
          ),
          SizedBox(height: 14),
          Text(
            'No notifications yet',
            style: TextStyle(color: Colors.white38, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ─── Notification card ────────────────────────────────────────────────────────
//
// ROOT CAUSE OF BLANK CARDS:
// Flutter 3.x cannot render a BoxDecoration that has BOTH:
//   • borderRadius (e.g. BorderRadius.circular(14))
//   • a non-uniform Border (e.g. left: 3.5px, others: 0.8px)
// When this combination is detected, Flutter clips the child paint area
// to zero — the card background color shows (so the border is visible)
// but all child widgets are invisible.
//
// FIX: Split into two layers using a Stack:
//   1. Outer Container — uniform Border.all(0.8px) + borderRadius → no clip issue
//   2. Positioned Container — the colored left accent bar drawn on top
// This is visually identical to the original design.

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    final accent = notification.accentColor;
    final accentDimmed = Color.fromRGBO(
      accent.red,
      accent.green,
      accent.blue,
      0.35,
    );
    final accentCurrent = isRead ? accentDimmed : accent;
    final accentBg = Color.fromRGBO(
      accent.red,
      accent.green,
      accent.blue,
      0.12,
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Layer 1: Card with uniform border (renders children correctly)
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Padding(
              // left: 17 = 3.5px accent bar + 13.5px inner gap ≈ original 14px feel
              padding: const EdgeInsets.only(
                left: 17,
                right: 14,
                top: 14,
                bottom: 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon bubble
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 12, top: 2),
                    decoration: BoxDecoration(
                      color: accentBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      notification.icon,
                      color: accentCurrent,
                      size: 18,
                    ),
                  ),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type label
                        Text(
                          notification.typeLabel,
                          style: TextStyle(
                            color: accentCurrent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 5),

                        // Title
                        Text(
                          notification.title,
                          style: TextStyle(
                            color: isRead ? Colors.white70 : Colors.white,
                            fontSize: 13.5,
                            fontWeight:
                                isRead ? FontWeight.w400 : FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Time row + unread dot
                        Row(
                          children: [
                            Text(
                              notification.time,
                              style: TextStyle(
                                color: isRead ? Colors.white54 : Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            if (!isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chevron
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.white24,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Layer 2: Colored left accent bar (drawn over the card, no border conflicts)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3.5,
              decoration: BoxDecoration(
                color: accentCurrent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail bottom sheet ──────────────────────────────────────────────────────

class _NotificationDetailSheet extends StatelessWidget {
  final AppNotification notification;

  const _NotificationDetailSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    final accent = notification.accentColor;
    final accentBg = Color.fromRGBO(
      accent.red,
      accent.green,
      accent.blue,
      0.12,
    );
    final accentBorder = Color.fromRGBO(
      accent.red,
      accent.green,
      accent.blue,
      0.35,
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 20),

          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentBorder, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(notification.icon, color: accent, size: 13),
                const SizedBox(width: 6),
                Text(
                  notification.typeLabel,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            notification.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Body
          Text(
            notification.body,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),

          // Timestamp
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white24, size: 13),
              const SizedBox(width: 6),
              Text(
                notification.time,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Dismiss button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Dismiss',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
