import 'package:flutter/material.dart';

/// Dashboard screen - Main analytics and overview
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'لوحة التحكم',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'نظرة عامة على أداء النظام',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Stats cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard(
                    title: 'إجمالي المبيعات',
                    value: '0 ر.س',
                    icon: Icons.trending_up,
                    color: const Color(0xFF10B981),
                  ),
                  _buildStatCard(
                    title: 'إجمالي المشتريات',
                    value: '0 ر.س',
                    icon: Icons.trending_down,
                    color: const Color(0xFFF59E0B),
                  ),
                  _buildStatCard(
                    title: 'صافي الربح',
                    value: '0 ر.س',
                    icon: Icons.attach_money,
                    color: const Color(0xFF3B82F6),
                  ),
                  _buildStatCard(
                    title: 'عدد العملاء',
                    value: '0',
                    icon: Icons.people,
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
