import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Case Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Firm Performance', style: AppConstants.headingStyle),
          const SizedBox(height: 24),
          _buildAnalyticsCard('Total Cases', '1,240', Icons.folder, Colors.blue),
          _buildAnalyticsCard('Success Rate', '94%', Icons.trending_up, Colors.green),
          _buildAnalyticsCard('Ongoing Cases', '156', Icons.timelapse, Colors.orange),
          _buildAnalyticsCard('Total Clients', '890', Icons.people, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppConstants.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70)),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
