import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/patient_service.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = PatientService(ApiClient.instance);
  late Future<List<NotificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listNotifications();
  }

@override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(title: 'Notifications', showBack: true),
      body: FutureBuilder<List<NotificationItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load notifications.'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet.',
                style: AppTextStyles.bodyLg
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = items[i];
              return ListTile(
                leading: Icon(
                  n.read ? Icons.mark_email_read : Icons.notifications,
                  color: n.read ? scheme.outline : scheme.primary,
                ),
                title: Text(
                  n.title,
                  style: AppTextStyles.labelLg.copyWith(
                    color: n.read ? scheme.onSurfaceVariant : scheme.onSurface,
                    fontWeight: n.read ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  n.message,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
                onTap: () {
                  if (!n.read) _service.markNotificationRead(n.id);
                  setState(() {
                    _future = _service.listNotifications();
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

