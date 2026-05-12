import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vstream/core/theme/app_theme.dart';
import 'package:vstream/shared/services/notification_service.dart';

class NotificationCenterSheet extends ConsumerWidget {
  const NotificationCenterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border(context), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notifications', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
                if (notifications.isNotEmpty)
                  TextButton(
                    onPressed: () => notifier.clearAll(),
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),
          const Divider(),
          if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return _NotificationTile(
                    notification: n,
                    onTap: () => notifier.markAsRead(n.id),
                  );
                },
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.offer: return Icons.local_offer_rounded;
      case NotificationType.security: return Icons.security_rounded;
      case NotificationType.release: return Icons.movie_filter_rounded;
      case NotificationType.info: return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat.jm().format(notification.timestamp);
    final dayStr = DateFormat.MMMd().format(notification.timestamp);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.bgSurface(context) : AppColors.red.withAlpha(20),
          shape: BoxShape.circle
        ),
        child: Icon(_getIcon(), size: 20, color: notification.isRead ? AppColors.textMuted : AppColors.red),
      ),
      title: Row(
        children: [
          Expanded(child: Text(notification.title, style: TextStyle(fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700, fontSize: 14))),
          if (!notification.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle)),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(notification.description, style: TextStyle(color: AppColors.textSecondary(context), fontSize: 12)),
          const SizedBox(height: 4),
          Text('$dayStr, $timeStr', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
      onTap: onTap,
    );
  }
}
