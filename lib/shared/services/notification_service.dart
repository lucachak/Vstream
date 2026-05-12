import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vstream/shared/services/local_notification_service.dart';

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
    this.type = NotificationType.info,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      description: description,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      type: type,
    );
  }
}

enum NotificationType { info, offer, security, release }

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationNotifier() : super([
    NotificationModel(
      id: '1',
      title: 'Welcome to VStream!',
      description: 'Start exploring thousands of movies and TV shows.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: NotificationType.info,
    ),
    NotificationModel(
      id: '2',
      title: 'New: House of the Dragon',
      description: 'Season 2 is now streaming in 4K Ultra HD.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      type: NotificationType.release,
    ),
  ]);

  void addNotification(String title, String description, NotificationType type) {
    final id = DateTime.now().millisecondsSinceEpoch;
    state = [
      NotificationModel(
        id: id.toString(),
        title: title,
        description: description,
        timestamp: DateTime.now(),
        type: type,
      ),
      ...state,
    ];

    // Trigger System Notification (Outside app)
    LocalNotificationService.showNotification(
      id: id % 100000,
      title: title,
      body: description,
    );
  }

  void markAsRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void clearAll() {
    state = [];
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<NotificationModel>>((ref) {
  return NotificationNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).where((n) => !n.isRead).length;
});
