import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/due_items_notification_provider.dart';
import '../providers/general_notification_provider.dart';
import '../models/notification_model.dart';
import '../providers/main_screen_tab_provider.dart';
import 'main_screen.dart'; // Added import for MainScreen
// import 'home.dart'; // home.dart import seems unused, can be removed if not needed elsewhere

// Helper functions for styling System Notifications (can be moved to a utility file)
Color _getSystemNotificationTypeColor(String type, BuildContext context) {
  final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
  switch (type.toLowerCase()) {
    case 'alert':
      return isDarkMode ? Colors.red.shade300 : Colors.redAccent;
    case 'warning':
      return isDarkMode ? Colors.orange.shade300 : Colors.orangeAccent;
    case 'water_quality_alert': // More specific type example
       return isDarkMode ? Colors.blue.shade300 : Colors.blueAccent;
    case 'info':
      return Theme.of(context).colorScheme.primary;
    default:
      return Colors.grey.shade600;
  }
}

IconData _getSystemNotificationTypeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'alert':
      return Icons.error_outline;
    case 'warning':
      return Icons.warning_amber_rounded;
    case 'info':
      return Icons.info_outline;
    case 'water_quality_alert':
      return Icons.water_drop_outlined; // More specific icon
    case 'temperature_alert':
      return Icons.thermostat_outlined;
    case 'ph_alert':
      return Icons.science_outlined;
    default:
      return Icons.notifications_none;
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  Widget _buildDueCropNotificationCard({
    required BuildContext context,
    required dynamic cropNotification,
    required VoidCallback onTap,
    required bool isRead,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    String titleText = 'Task Due Today';
    String message = 'Unknown task';
    IconData icon = Icons.warning_amber_rounded;
    Color iconColor = isRead ? colorScheme.onSurface.withOpacity(0.6) : colorScheme.primary;
    FontWeight titleFontWeight = isRead ? FontWeight.normal : FontWeight.bold;

    final String status = cropNotification['status'] ?? 'unknown';
    final String batchCode = cropNotification['batchCode'] ?? 'N/A';
    final String plantType = cropNotification['plantType'] ?? 'N/A';
    final String? plantedDate = cropNotification['plantedDate'];
    final int? quantity = cropNotification['quantity'];

    if (status == 'seedling') {
      titleText = 'Transplant Due: $plantType';
      message = 'Batch $batchCode ($plantType) is due for transplant today.';
      if (quantity != null) message += ' Quantity: $quantity.';
      if (plantedDate != null) message += ' Planted: ${DateTime.parse(plantedDate).toLocal().toString().split(' ')[0]}.';
      icon = Icons.move_up;
    } else if (status == 'transplanted') {
      titleText = 'Harvest Due: $plantType';
      message = 'Batch $batchCode ($plantType) is due for harvest today.';
      final String? transplantDate = cropNotification['transplantDetails']?['transplantedDate'];
      if (quantity != null) message += ' Quantity: $quantity.';
      if (transplantDate != null) message += ' Transplanted: ${DateTime.parse(transplantDate).toLocal().toString().split(' ')[0]}.';
      icon = Icons.agriculture;
    }

    return Opacity(
      opacity: isRead ? 0.7 : 1.0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: isRead ? Colors.white.withOpacity(0.8) : Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(isRead ? 0.1 : 0.2),
                spreadRadius: 1,
                blurRadius: isRead ? 3 : 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        titleText,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: titleFontWeight,
                          color: isRead ? Colors.black.withOpacity(0.7) : Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.black.withOpacity(isRead ? 0.6 : 0.8),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 14, color: iconColor),
                      const SizedBox(width: 4),
                      Text(
                        'Today',
                        style: textTheme.bodySmall?.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildDueTaskNotificationCard({
    required BuildContext context,
    required dynamic taskNotification,
    required VoidCallback onTap,
    required bool isRead,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final String title = taskNotification['title'] ?? 'Task Due';
    final String status = taskNotification['status'] ?? 'Pending';
    final String priority = taskNotification['priority'] ?? 'Normal';
    final String? description = taskNotification['description'];

    Color iconColor = isRead ? colorScheme.onSurface.withOpacity(0.6) : colorScheme.primary;
    FontWeight titleFontWeight = isRead ? FontWeight.normal : FontWeight.bold;
    IconData taskIcon = Icons.task_alt;
    if (priority == 'High') taskIcon = Icons.notification_important;
    else if (priority == 'Low') taskIcon = Icons.low_priority;

    String message = 'Status: $status, Priority: $priority.';
    if (description != null && description.isNotEmpty) {
      message += ' Desc: ${description.substring(0, description.length > 50 ? 50 : description.length)}${description.length > 50 ? '...' : ''}';
    }

    return Opacity(
      opacity: isRead ? 0.7 : 1.0,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: isRead ? Colors.white.withOpacity(0.8) : Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(isRead ? 0.1 : 0.2),
                spreadRadius: 1,
                blurRadius: isRead ? 3 : 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: titleFontWeight,
                          color: isRead ? Colors.black.withOpacity(0.7) : Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(taskIcon, color: iconColor, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.black.withOpacity(isRead ? 0.6 : 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 14, color: iconColor),
                      const SizedBox(width: 4),
                      Text(
                        'Due Today',
                        style: textTheme.bodySmall?.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildSystemNotificationItemCard({
    required BuildContext context,
    required NotificationModel notification,
    required bool isRead,
    required VoidCallback onMarkAsRead,
    required VoidCallback onDelete,
    required VoidCallback onViewDetails,
  }) {
    final theme = Theme.of(context);
    final typeColor = _getSystemNotificationTypeColor(notification.type, context);
    final typeIcon = _getSystemNotificationTypeIcon(notification.type);

    return Opacity(
      opacity: isRead ? 0.75 : 1.0,
      child: Card(
        elevation: isRead ? 1.0 : 2.0,
        margin: const EdgeInsets.only(bottom: 12.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        color: isRead ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200) : theme.cardColor,
        child: InkWell(
          onTap: notification.actionUrl != null ? onViewDetails : null,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(typeIcon, color: typeColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              // color: isRead ? theme.textTheme.bodySmall?.color : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              // color: isRead ? theme.textTheme.bodySmall?.color?.withOpacity(0.7) : theme.textTheme.bodyMedium?.color,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      notification.getFormattedTimestamp(),
                      style: theme.textTheme.bodySmall?.copyWith(
                         color: isRead ? Colors.grey.shade500 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isRead)
                      TextButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Mark Read'),
                        onPressed: onMarkAsRead,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    if (notification.actionUrl != null)
                      Padding(
                        padding: EdgeInsets.only(left: !isRead ? 8.0 : 0.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_forward_ios, size: 14),
                          label: const Text('View Details'),
                          onPressed: onViewDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: typeColor.withOpacity(0.15),
                            foregroundColor: typeColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)
                          ),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.grey.shade600, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dueItemsProvider = Provider.of<DueItemsNotificationProvider>(context);
    final generalNotificationProvider = Provider.of<GeneralNotificationProvider>(context);

    List<dynamic> unreadCropNotifications = dueItemsProvider.dueCropNotifications.where((n) => !dueItemsProvider.isCropNotificationRead(n['_id'])).toList();
    List<dynamic> readCropNotifications = dueItemsProvider.dueCropNotifications.where((n) => dueItemsProvider.isCropNotificationRead(n['_id'])).toList();
    List<dynamic> unreadTaskNotifications = dueItemsProvider.dueTaskNotifications.where((n) => !dueItemsProvider.isTaskNotificationRead(n['_id'])).toList();
    List<dynamic> readTaskNotifications = dueItemsProvider.dueTaskNotifications.where((n) => dueItemsProvider.isTaskNotificationRead(n['_id'])).toList();

    List<NotificationModel> unreadSystemNotifications = generalNotificationProvider.unreadNotifications;
    List<NotificationModel> readSystemNotifications = generalNotificationProvider.notifications.where((n) => n.isRead).toList();

    bool hasUnreadItems = unreadCropNotifications.isNotEmpty || unreadTaskNotifications.isNotEmpty || unreadSystemNotifications.isNotEmpty;
    bool hasReadItems = readCropNotifications.isNotEmpty || readTaskNotifications.isNotEmpty || readSystemNotifications.isNotEmpty;
    bool hasAnyItems = hasUnreadItems || hasReadItems;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        centerTitle: true,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: [
                Colors.blue.shade400,
                Theme.of(context).primaryColor,
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (hasUnreadItems)
            TextButton(
                style: TextButton.styleFrom(foregroundColor: colorScheme.onPrimary),
                onPressed: () {
                  print('[NotificationScreen] Mark All Read pressed.');
                  int dueUnreadBefore = dueItemsProvider.unreadCropCount + dueItemsProvider.unreadTaskCount;
                  int generalUnreadBefore = generalNotificationProvider.unreadCount;
                  print('[NotificationScreen] Before - Due Unread: $dueUnreadBefore, General Unread: $generalUnreadBefore');

                  dueItemsProvider.markAllCropNotificationsAsRead();
                  dueItemsProvider.markAllTaskNotificationsAsRead();
                  generalNotificationProvider.markAllAsRead().then((success) {
                     print('[NotificationScreen] generalNotificationProvider.markAllAsRead success: $success');
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Marking all as read...'), duration: Duration(seconds:1)),
                  );
                },
                child: Text('MARK ALL READ'),
            ),

          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
            tooltip: 'Refresh Notifications',
            onPressed: () {
              print('[NotificationScreen] Refresh pressed.');
              dueItemsProvider.loadDueItemsNotifications(forceRefresh: true);
              generalNotificationProvider.fetchNotifications(forceRefresh: true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Refreshing notifications...'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (dueItemsProvider.isLoading && generalNotificationProvider.isLoading && !hasAnyItems) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Widget> notificationWidgets = [];

          if (hasUnreadItems) {
             notificationWidgets.add(
              Padding(
                padding: const EdgeInsets.only(top:16.0, left: 16.0, right: 16.0, bottom: 10.0),
                child: Text(
                  'Unread',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            );
          }

          if (unreadCropNotifications.isNotEmpty) {
            notificationWidgets.add(
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 5.0, top: 5.0),
                child: Text('Crops', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.w600)),
              ),
            );
            for (var notificationData in unreadCropNotifications) {
              final id = notificationData['_id'] as String;
              final status = notificationData['status'] as String? ?? 'unknown';
              notificationWidgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildDueCropNotificationCard(
                    context: context,
                    cropNotification: notificationData,
                    isRead: false, 
                    onTap: () {
                      dueItemsProvider.markCropNotificationAsRead(id);
                      final String batchCode = notificationData['batchCode'] ?? 'N/A';
                      print('Tapped on UNREAD crop notification: $batchCode, status: $status');

                      String targetSubScreen = (status == 'seedling') ? 'seedlings' : 'transplants';
                      String actionType = (status == 'seedling') ? 'transplant' : 'harvest';

                      Provider.of<MainScreenTabProvider>(context, listen: false)
                          .selectTab(1, arguments: {
                              'targetSubScreen': targetSubScreen, 
                              'actionBatchId': id,
                              'actionType': actionType
                            });

                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              );
            }
          }

          if (unreadTaskNotifications.isNotEmpty) {
            notificationWidgets.add(
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 5.0, top: 10.0),
                 child: Text('Tasks', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.w600)),
              ),
            );
            for (var taskData in unreadTaskNotifications) {
              final id = taskData['_id'] as String;
              notificationWidgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildDueTaskNotificationCard(
                    context: context,
                    taskNotification: taskData,
                    isRead: false,
                    onTap: () {
                      final String taskId = taskData['_id'] as String;
                      dueItemsProvider.markTaskNotificationAsRead(taskId);
                      print('Tapped on task notification: ID $taskId');

                      Provider.of<MainScreenTabProvider>(context, listen: false)
                          .selectTab(2, arguments: {'taskId': taskId});

                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              );
            }
          }
          
          if (unreadSystemNotifications.isNotEmpty) {
            notificationWidgets.add(
              Padding(
                padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 5.0, top: (unreadCropNotifications.isNotEmpty || unreadTaskNotifications.isNotEmpty) ? 10.0 : 5.0),
                child: Text('System Alerts', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.w600)),
              ),
            );
            for (var notification in unreadSystemNotifications) {
              notificationWidgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildSystemNotificationItemCard(
                    context: context,
                    notification: notification,
                    isRead: false,
                    onMarkAsRead: () {
                      print('[_buildSystemNotificationItemCard - UNREAD] Mark As Read TAPPED for notification ID: ${notification.id}');
                      generalNotificationProvider.markAsRead(notification.id);
                    },
                    onDelete: () => generalNotificationProvider.deleteNotification(notification.id),
                    onViewDetails: () {
                      print('Tapped system alert: ${notification.title}, Action URL: ${notification.actionUrl}');
                      if (notification.actionUrl == '/water-monitoring') { 
                        Provider.of<MainScreenTabProvider>(context, listen: false).selectTab(0, arguments: {'navigateTo': 'water_status'});
                      } else if (notification.actionUrl == '/nutrient-control') {
                        Provider.of<MainScreenTabProvider>(context, listen: false).selectTab(0, arguments: {'navigateTo': 'ph_status'});
                      }
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                  ),
                ),
              );
            }
          }
          
          if(hasUnreadItems){
             notificationWidgets.add(const SizedBox(height: 10));
             notificationWidgets.add(Padding(padding: const EdgeInsets.symmetric(horizontal:16.0), child: Divider(thickness:1)));
          }

          if (hasReadItems) {
            notificationWidgets.add(
              Padding(
                padding: const EdgeInsets.only(top:16.0, left: 16.0, right: 16.0, bottom: 10.0),
                child: Text(
                  'Read',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            );
          }

          if (readCropNotifications.isNotEmpty) {
            notificationWidgets.add(
              Padding(
                 padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 5.0, top: 5.0),
                 child: Text('Crops', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w600)),
              ),
            );
            for (var notificationData in readCropNotifications) {
              final id = notificationData['_id'] as String;
              final status = notificationData['status'] as String? ?? 'unknown';
              notificationWidgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildDueCropNotificationCard(
                    context: context,
                    cropNotification: notificationData,
                    isRead: true, 
                    onTap: () {
                      final String batchCode = notificationData['batchCode'] ?? 'N/A';
                      print('Tapped on READ crop notification: $batchCode, status: $status');
                      
                      String targetSubScreen = (status == 'seedling') ? 'seedlings' : 'transplants';
                      String actionType = (status == 'seedling') ? 'transplant' : 'harvest';

                      Provider.of<MainScreenTabProvider>(context, listen: false)
                          .selectTab(1, arguments: {
                              'targetSubScreen': targetSubScreen, 
                              'actionBatchId': id,
                              'actionType': actionType
                            });
                            
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              );
            }
          }

          if (readTaskNotifications.isNotEmpty) {
            notificationWidgets.add(
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 5.0, top: 10.0),
                child: Text('Tasks', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w600)),
              ),
            );
            for (var taskData in readTaskNotifications) {
              final id = taskData['_id'] as String;
              notificationWidgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildDueTaskNotificationCard(
                    context: context,
                    taskNotification: taskData,
                    isRead: true,
                    onTap: () {
                      final String taskId = taskData['_id'] as String;
                      print('Tapped on READ task notification: ID $taskId');

                      Provider.of<MainScreenTabProvider>(context, listen: false)
                          .selectTab(2, arguments: {'taskId': taskId});

                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              );
            }
          }

          if (readSystemNotifications.isNotEmpty) {
            notificationWidgets.add(
              Padding(
                 padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 5.0, top: (readCropNotifications.isNotEmpty || readTaskNotifications.isNotEmpty) ? 10.0 : 5.0),
                 child: Text('System Alerts', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w600)),
              ),
            );
            for (var notification in readSystemNotifications) {
              notificationWidgets.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildSystemNotificationItemCard(
                    context: context,
                    notification: notification,
                    isRead: true,
                    onMarkAsRead: () {
                      print('[_buildSystemNotificationItemCard - READ] Mark As Read TAPPED for notification ID: ${notification.id} (already read, no action)');
                    },
                    onDelete: () => generalNotificationProvider.deleteNotification(notification.id),
                    onViewDetails: () {
                       print('Tapped system alert: ${notification.title}, Action URL: ${notification.actionUrl}');
                       if (notification.actionUrl == '/water-monitoring') { 
                         Provider.of<MainScreenTabProvider>(context, listen: false).selectTab(0, arguments: {'navigateTo': 'water_status'});
                       } else if (notification.actionUrl == '/nutrient-control') {
                         Provider.of<MainScreenTabProvider>(context, listen: false).selectTab(0, arguments: {'navigateTo': 'ph_status'});
                       }
                       if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                  ),
                ),
              );
            }
          }

          if (!hasAnyItems && !dueItemsProvider.isLoading && !generalNotificationProvider.isLoading) {
             notificationWidgets.add(
               Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade400),
                       const SizedBox(height:16),
                       Text(
                         'No new notifications for today.',
                         style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                         textAlign: TextAlign.center,
                       ),
                     ],
                   )
                 ),
               )
             );
          }

          return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: notificationWidgets,
              ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required String title,
    required String message,
    required String date,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: colorScheme.primary, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserNotificationCard({
    required BuildContext context,
    required String name,
    required String action,
    required IconData icon,
    required String time,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
