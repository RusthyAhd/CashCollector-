import 'package:flutter/material.dart';

class ShopListScreen extends StatefulWidget {
  final String routeName;
  const ShopListScreen({super.key, required this.routeName});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool showUnpaid = true;

  final List<Map<String, String>> allShops = [
    {"name": "ABC Store", "address": "123 Main St", "phone": "0755354023", "status": "Unpaid"},
    {"name": "XYZ Store", "address": "123 Main St", "phone": "0755354023", "status": "Unpaid"},
    {"name": "RH Stores", "address": "123 Main St", "phone": "0755354023", "status": "Paid"},
    {"name": "RR Stores", "address": "123 Main St", "phone": "0755354023", "status": "Paid"},
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredShops = allShops.where((shop) {
      final matchStatus = showUnpaid ? shop['status'] == 'Unpaid' : shop['status'] == 'Paid';
      final matchSearch = shop['name']!.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchStatus && matchSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Shops"),
        leading: BackButton(),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search by area",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => showUnpaid = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: showUnpaid ? Colors.blue : Colors.grey.shade200,
                      foregroundColor: showUnpaid ? Colors.white : Colors.black,
                    ),
                    child: const Text("Unpaid"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => showUnpaid = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !showUnpaid ? Colors.green.shade600 : Colors.grey.shade200,
                      foregroundColor: !showUnpaid ? Colors.white : Colors.black,
                    ),
                    child: const Text("Paid"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredShops.length,
                itemBuilder: (context, index) {
                  final shop = filteredShops[index];
                  return Card(
                    color: Colors.blueGrey.shade900,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(shop['name']!, style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop['address']!, style: const TextStyle(color: Colors.white)),
                          Text(shop['phone']!, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      trailing: const Icon(Icons.location_pin, color: Colors.pinkAccent),
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
