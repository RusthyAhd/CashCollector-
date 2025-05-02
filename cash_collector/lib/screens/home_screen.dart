import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Area Shops',
      debugShowCheckedModeBanner: false,
      home: AreaPage(),
    );
  }
}

class AreaPage extends StatelessWidget {
  final List<Map<String, dynamic>> routes = [
    {
      "route": "Kinniya Route",
      "shops": ["Shop 1", "Shop 2", "Shop 3"],
    },
    {
      "route": "Periyathu Route",
      "shops": [],
    },
    {
      "route": "Kurinchaker Route",
      "shops": [],
    },
  ];

  void _onShopTap(BuildContext context, String shopName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Tapped on $shopName")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AREAS"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Card(
              color: Colors.blue.shade900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  collapsedIconColor: Colors.white,
                  iconColor: Colors.white,
                  title: Text(
                    route['route'],
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  children: route['shops'].isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              "No shops available.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        ]
                      : route['shops'].map<Widget>((shopName) {
                          return InkWell(
                            onTap: () => _onShopTap(context, shopName),
                            child: ListTile(
                              leading: Icon(Icons.store, color: Colors.yellow),
                              title: Text(
                                shopName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                            ),
                          );
                        }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
