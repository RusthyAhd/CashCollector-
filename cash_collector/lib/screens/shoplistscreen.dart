import 'package:flutter/material.dart';
import 'balance_screen.dart';

class ShopListScreen extends StatefulWidget {
  final String routeName;
  const ShopListScreen({super.key, required this.routeName});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool showUnpaid = true;

  final List<Map<String, dynamic>> allShops = [
    {
      "name": "ABC Store",
      "address": "123 Main St",
      "phone": "0755354023",
      "status": "Unpaid",
      "amount": 0
    },
    {
      "name": "XYZ Store",
      "address": "456 Elm St",
      "phone": "0755354024",
      "status": "Unpaid",
      "amount": 0
    },
    {
      "name": "RH Stores",
      "address": "789 Oak St",
      "phone": "0755354025",
      "status": "Paid",
      "amount": null // Set to null initially
    },
    {
      "name": "RR Stores",
      "address": "101 Maple St",
      "phone": "0755354026",
      "status": "Paid",
      "amount": null // Set to null initially
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredShops = allShops.where((shop) {
      final matchStatus =
          showUnpaid ? shop['status'] == 'Unpaid' : shop['status'] == 'Paid';
      final matchSearch = shop['name']
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      return matchStatus && matchSearch;
    }).toList();

    // Calculate total paid amount if showUnpaid is false
    int totalPaidAmount = 0;
    if (!showUnpaid) {
      totalPaidAmount = filteredShops.fold(
          0, (sum, shop) => sum + ((shop['amount'] ?? 0) as int));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shops"),
        leading: const BackButton(),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => showUnpaid = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          showUnpaid ? Colors.blue : Colors.grey.shade200,
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
                      backgroundColor: !showUnpaid
                          ? Colors.green.shade600
                          : Colors.grey.shade200,
                      foregroundColor:
                          !showUnpaid ? Colors.white : Colors.black,
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BalanceScreen(
                              shopName: shop['name'],
                              onBalanceAdjusted: (shopName, reducedAmount) {
                                setState(() {
                                  // Find the shop and update its status and amount
                                  final shopToUpdate = allShops
                                      .firstWhere((s) => s['name'] == shopName);
                                  shopToUpdate['status'] = 'Paid';
                                  shopToUpdate['amount'] =
                                      reducedAmount.toInt(); // Set the reduced amount
                                });
                              },
                            ),
                          ),
                        );
                      },
                      title: Text(
                        shop['name'],
                        style: const TextStyle(
                            color: Colors.yellow, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop['address'],
                              style: const TextStyle(color: Colors.white)),
                          Text(shop['phone'],
                              style: const TextStyle(color: Colors.white)),
                          if (shop['status'] == 'Paid' && shop['amount'] != null)
                            Text("Amount: Rs.${shop['amount']}",
                                style: const TextStyle(
                                    color: Colors.lightGreenAccent)),
                        ],
                      ),
                      trailing: const Icon(Icons.location_pin,
                          color: Colors.pinkAccent),
                    ),
                  );
                },
              ),
            ),
            if (!showUnpaid)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Total Paid Amount: ",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Rs.$totalPaidAmount",
                        style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 156, 5, 5))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
