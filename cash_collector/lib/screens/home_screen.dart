import 'package:flutter/material.dart';
import 'package:cash_collector/screens/shoplistscreen.dart';

class AreaPage extends StatelessWidget {
  const AreaPage({super.key});

  final List<Map<String, String>> routes = const [
    {"name": "Kinniya Route", "emoji": "🛣️"},
    {"name": "Periyathu Route", "emoji": "🛍️"},
    {"name": "Kurinchaker Route", "emoji": "🏪"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFAF1), // Soft green background
      appBar: AppBar(
        title: const Text("Choose Area"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade800,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select a route to view shops:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: routes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final route = routes[index];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 3,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShopListScreen(routeName: route['name']!),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              route['emoji']!,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                route['name']!,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
