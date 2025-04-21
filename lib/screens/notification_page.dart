import 'package:flutter/material.dart';
import 'home.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/home.png', width: 24, height: 24),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
              const SizedBox(height: 10),
              ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildNotificationCard(
                        title: "Today's Task",
                        message: 'Garden Facilitator added the task list today',
                        date: 'Feb. 9, 2025'),
                    _buildNotificationCard(
                        title: 'Calendar Update',
                        message:
                            'The next batch of basil seedlings will be moved to the main system tomorrow.',
                        date: ''),
                  ]),
              const SizedBox(height: 20),
              const Text('Later',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildUserNotification(
                        'Solána Imani Rowe',
                        'Added "Daily Seedlings Check" task on her task table',
                        'assets/solana.png',
                        '2hrs ago'),
                    _buildUserNotification(
                        'Kendrick Lamar',
                        'Added the "Prepare Seedling Trays" task on his task table',
                        'assets/kendrick.png',
                        '2hrs ago'),
                    _buildUserNotification(
                        'Ed Sheeran',
                        'Marked the "Check Root Development" finished on her task table',
                        'assets/ed.png',
                        '2hrs ago'),
                  ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String date,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 8),
            Text(
              date,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserNotification(
      String name, String action, String imagePath, String time) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: AssetImage(imagePath), radius: 24),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(action,
          style: const TextStyle(fontSize: 14, color: Colors.black54)),
      trailing:
          Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}
