import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'balance_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopListScreen extends StatefulWidget {
  final String routeName;
  const ShopListScreen({super.key, required this.routeName});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool showUnpaid = true;

  List<Map<String, dynamic>> allShops = [
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
      "amount": 300
    },
    {
      "name": "RR Stores",
      "address": "101 Maple St",
      "phone": "0755354026",
      "status": "Paid",
      "amount": 250
    },
  ];

  Map<String, int> countdowns = {};
  Map<String, Timer> timers = {};

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    for (var timer in timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _loadShops() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('routes')
        .doc(widget.routeName)
        .collection('shops')
        .get();

    setState(() {
      allShops = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id, // save doc ID for updating later
          "name": data['name'] ?? '',
          "address": data['address'] ?? '',
          "phone": data['phone'] ?? '',
          "status": data['status'] ?? 'Unpaid',
          "amount": data['amount'] ?? 0,
        };
      }).toList();
    });

    for (var shop in allShops) {
      if (shop['status'] == 'Paid') {
        _startCountdown(shop['name']);
      }
    }
    print("Fetched shops:");
    for (var shop in allShops) {
      debugPrint(shop.toString());
    }
  }

  Future<void> _saveShops() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shops', json.encode(allShops));
  }

  void _startCountdown(String shopName) {
    if (countdowns.containsKey(shopName)) return;

    countdowns[shopName] = 43200; // Set countdown to 12 hours (43200 seconds)

    timers[shopName]?.cancel();
    timers[shopName] = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (countdowns[shopName]! > 0) {
          countdowns[shopName] = countdowns[shopName]! - 1;
        } else {
          timer.cancel();
          final shop = allShops.firstWhere((s) => s['name'] == shopName);
          shop['status'] = 'Unpaid';
          shop['amount'] = 0;
          countdowns.remove(shopName);
          timers.remove(shopName);
          _saveShops();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredShops = allShops.where((shop) {
      final matchStatus =
          showUnpaid ? shop['status'] == 'Unpaid' : shop['status'] == 'Paid';
      final matchSearch = shop['name']
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      final hasValidAmount = showUnpaid || shop['amount'] != null;
      return matchStatus && matchSearch && hasValidAmount;
    }).toList();

    int totalPaidAmount = 0;
    if (!showUnpaid) {
      totalPaidAmount = filteredShops.fold(
          0, 
          (sum, shop) => sum + ((shop['amount'] ?? 0) as num).toInt());
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
                  final name = shop['name'];
                  final countdown = countdowns[name] ?? 0;

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
                              routeName: widget.routeName,
                              shopId:
                                  shop['id'], // must be doc ID from Firestore
                              onBalanceAdjusted:
                                  (shopName, reducedAmount) async {
                                final updatedShops =
                                    List<Map<String, dynamic>>.from(allShops);

                                final shopIndex = updatedShops.indexWhere(
                                    (shop) => shop['name'] == shopName);
                                if (shopIndex != -1) {
                                  final shopId = updatedShops[shopIndex][
                                      'id']; // Make sure you're storing Firestore doc IDs
                                  final currentAmount =
                                      updatedShops[shopIndex]['amount'];
                                  final newAmount =
                                      currentAmount - reducedAmount;

                                  // Update Firestore
                                  await FirebaseFirestore.instance
                                      .collection('routes')
                                      .doc(widget.routeName)
                                      .collection('shops')
                                      .doc(shopId)
                                      .update({
                                    'status': 'Paid',
                                    'amount': newAmount,
                                  });

                                  setState(() {
                                    updatedShops[shopIndex]['status'] = 'Paid';
                                    updatedShops[shopIndex]['amount'] =
                                        newAmount;
                                    allShops = updatedShops;
                                  });

                                  _startCountdown(shopName);
                                }
                              },
                            ),
                          ),
                        );
                      },
                      title: Text(
                        name,
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
                          if (shop['status'] == 'Paid' &&
                              shop['amount'] != null)
                            Text("Amount: Rs.${shop['amount']}",
                                style: const TextStyle(
                                    color: Colors.lightGreenAccent)),
                        ],
                      ),
                      trailing: shop['status'] == 'Paid' &&
                              countdowns.containsKey(name)
                          ? AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                      scale: animation, child: child),
                              child: Text(
                                "Reverting in $countdown s",
                                key: ValueKey<int>(countdown),
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          : const Icon(Icons.location_pin,
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
