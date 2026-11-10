import 'package:adm_rider/core/api/api_service.dart';
import 'package:adm_rider/modules/notifications/models/notification_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// ==================== UNREAD COUNT ====================

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final api = ref.read(apiServiceProvider);
  final res = await api.getUnreadCount();
  return res.response.unreadCount;
});

/// Convenience bool for badge visibility
final hasUnreadProvider = Provider.autoDispose<bool>((ref) {
  final async = ref.watch(unreadCountProvider);
  return async.maybeWhen(data: (n) => n > 0, orElse: () => false);
});

// ==================== NOTIFICATION LIST ====================

class NotificationListState {
  final List<NotificationItem> items;
  final int page;
  final int limit;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const NotificationListState({
    this.items = const [],
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  NotificationListState copyWith({
    List<NotificationItem>? items,
    int? page,
    int? limit,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationListState> {
  NotificationNotifier(this._ref) : super(const NotificationListState()) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final api = _ref.read(apiServiceProvider);
      final res = await api.getNotifications(page: 1, limit: state.limit);

      final list = res.response.data;
      final pagination = res.response.pagination;

      state = state.copyWith(
        items: list,
        page: pagination.page,
        total: pagination.total,
        isLoading: false,
        hasMore: list.length < pagination.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final api = _ref.read(apiServiceProvider);
      final nextPage = state.page + 1;
      final res = await api.getNotifications(
        page: nextPage,
        limit: state.limit,
      );

      final merged = [...state.items, ...res.response.data];
      final pagination = res.response.pagination;

      state = state.copyWith(
        items: merged,
        page: pagination.page,
        total: pagination.total,
        isLoadingMore: false,
        hasMore: merged.length < pagination.total,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final api = _ref.read(apiServiceProvider);
      final res = await api.markNotificationAsRead(id);

      // Replace item with fresh server data
      final updated = state.items
          .map((n) => n.id == id ? res.response : n)
          .toList();

      state = state.copyWith(items: updated);
      _ref.invalidate(unreadCountProvider);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final api = _ref.read(apiServiceProvider);
      final res = await api.markAllNotificationsAsRead();

      if (res.response.success) {
        state = state.copyWith(
          items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
        );
        _ref.invalidate(unreadCountProvider);
      }
    } catch (_) {}
  }

  Future<void> delete(int id) async {
    try {
      final api = _ref.read(apiServiceProvider);
      final res = await api.deleteNotification(id);

      if (res.statusCode == 200) {
        state = state.copyWith(
          items: state.items.where((n) => n.id != id).toList(),
          total: state.total - 1,
        );
        _ref.invalidate(unreadCountProvider);
      }
    } catch (_) {}
  }
}

final notificationNotifierProvider =
    StateNotifierProvider.autoDispose<
      NotificationNotifier,
      NotificationListState
    >((ref) => NotificationNotifier(ref));
