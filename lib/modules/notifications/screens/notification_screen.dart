import 'package:adm_rider/core/config/app_router.dart';
import 'package:adm_rider/modules/notifications/models/notification_models.dart';
import 'package:adm_rider/modules/notifications/provider/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Trigger load-more 300px before hitting the bottom.
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(notificationNotifierProvider.notifier).loadMore();
    }
  }

  // ==================== ACTIONS ====================

  Future<void> _confirmAndDelete(NotificationItem item) async {
    final confirmed = await _confirmDelete(item);
    if (confirmed != true) return;

    await ref.read(notificationNotifierProvider.notifier).delete(item.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted: ${item.title}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<bool> _confirmDelete(NotificationItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete notification?'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onNotificationTap(NotificationItem notification) async {
    // Mark as read optimistically via provider
    if (notification.data?.type.toLowerCase() == 'order') {
      // context.push(
      //   AppRoutes.orderDetailsPath(
      //     int.parse(notification.data?.entityId ?? '0'),
      //   ),
      // );
    } else {}
    // else if (notification.data?.type.toLowerCase() == 'event') {
    //   context.push(
    //     AppRoutes.eventDetailPath(
    //       int.parse(notification.data?.entityId ?? '0'),
    //     ),
    //   );
    // } else if (notification.data?.type.toLowerCase() == 'store') {
    //   context.push(
    //     AppRoutes.storeDetailPath(
    //       int.parse(notification.data?.entityId ?? '0'),
    //     ),
    //   );
    // }
    if (!notification.isRead) {
      await ref
          .read(notificationNotifierProvider.notifier)
          .markAsRead(notification.id);
    }

    // TODO: navigate using notification.data?.webUrl / deepLink
    if (!mounted) return;
  }

  Future<void> _markAllAsRead() async {
    await ref.read(notificationNotifierProvider.notifier).markAllAsRead();
  }

  Future<void> _refresh() async {
    await ref.read(notificationNotifierProvider.notifier).refresh();
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);

    // Derive unread count locally from the loaded items — cheap and instant.
    final localUnread = state.items.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            if (localUnread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$localUnread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (localUnread > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationListState state) {
    // ─── Initial load ───
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // ─── Error with no items ───
    if (state.error != null && state.items.isEmpty) {
      return _buildErrorState(state.error!);
    }

    // ─── Empty ───
    if (state.items.isEmpty) {
      return RefreshIndicator(onRefresh: _refresh, child: _buildEmptyState());
    }

    // ─── List ───
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Load-more spinner at the bottom
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            );
          }

          final item = state.items[index];

          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: _buildSwipeBackground(),
            confirmDismiss: (_) async {
              final confirmed = await _confirmDelete(item);
              if (confirmed == true) {
                // Delete through provider; Dismissible handles UI removal.
                await ref
                    .read(notificationNotifierProvider.notifier)
                    .delete(item.id);
                if (mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('Deleted: ${item.title}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                }
              }
              // Always return false so the provider's state drives removal,
              // not the Dismissible widget. This avoids double-removal bugs.
              return false;
            },
            child: _NotificationTile(
              notification: item,
              onTap: () => _onNotificationTap(item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'Delete',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      // ListView so RefreshIndicator works on an empty list
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are all caught up!',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 72, color: Colors.red.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TILE ====================

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  IconData _getIcon() {
    switch (notification.data?.type) {
      case 'PRODUCT':
        return Icons.inventory_2_outlined;
      case 'SELLER':
        return Icons.storefront_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor() {
    switch (notification.data?.type) {
      case 'PRODUCT':
        return Colors.deepPurple;
      case 'SELLER':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final iconColor = _getIconColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: unread ? const Color(0xFFEEF3FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: unread ? Border.all(color: Colors.blue.shade100) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIcon(), color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 13,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _timeAgo(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const Spacer(),
                          if ((notification.data?.actionLabel ?? '').isNotEmpty)
                            Text(
                              notification.data!.actionLabel,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: iconColor,
                              ),
                            ),
                        ],
                      ),
                    ],
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
