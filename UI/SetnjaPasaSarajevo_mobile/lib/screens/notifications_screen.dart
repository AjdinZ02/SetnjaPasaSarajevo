import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:setnjapasasarajevo_mobile/providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationProvider()..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Obavijesti')),
        body: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            provider.startPolling();
            if (provider.items.isEmpty) {
              return const Center(child: Text('Nemate novih obavijesti.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.items.length,
              itemBuilder: (_, index) {
                final item = provider.items[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      item.isRead
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.message),
                    onTap: () => provider.markAsRead(item),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
