import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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

  List<Map<String, dynamic>> allShops = [];
  double totalPaidAcrossRoutes = 0.0;
  double routeTotalPaid = 0.0;
  bool isLoading = true;

  Map<String, int> countdowns = {};
  Map<String, Timer> timers = {};
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadShops();
    _startUiUpdater();
  }

  void _startUiUpdater() {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadShops() async {
    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('routes')
        .doc(widget.routeName)
        .collection('shops')
        .get();

    final now = DateTime.now();

    final updatedShops = <Map<String, dynamic>>[];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final paidAt = (data['paidAt'] as Timestamp?)?.toDate();
      String status = data['status'] ?? 'Unpaid';

      // Automatically revert if time has passed
      if (status == 'Paid' && paidAt != null) {
        final difference = now.difference(paidAt).inSeconds;
        if (difference >= 43200) {
          // Use 43200 for 12 hours
          // Update Firestore
          await FirebaseFirestore.instance
              .collection('routes')
              .doc(widget.routeName)
              .collection('shops')
              .doc(doc.id)
              .update({'status': 'Unpaid', 'paidAt': null});

          status = 'Unpaid';
        }
      }

      updatedShops.add({
        "id": doc.id,
        "name": data['name'] ?? '',
        "address": data['address'] ?? '',
        "phone": data['phone'] ?? '',
        "status": status,
        "amount": (data['amount'] ?? 0) as num,
        "totalPaid": (data['totalPaid'] ?? 0) as num,
        "paidAt": paidAt,
        "latitude": (data['latitude'] as num?)?.toDouble(), // 👈 Add this
        "longitude": (data['longitude'] as num?)?.toDouble(), // 👈 And this
      });
    }

    setState(() {
      allShops = updatedShops;
      isLoading = false;
    });
    for (var shop in allShops) {
      if (shop['status'] == 'Paid') {
        _startCountdown(shop['name']);
      }
    }
  }


  Future<void> _startCountdown(String shopName, {DateTime? paidAt}) async {
    if (countdowns.containsKey(shopName)) return;

    // Use paidAt to calculate remaining seconds
    final startTime = paidAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    final totalSeconds = 43200; // For testing: 2 minutes
    final remaining = totalSeconds - elapsed;

    if (remaining <= 0) return; // Already expired

    countdowns[shopName] = remaining;

    timers[shopName]?.cancel();
    timers[shopName] = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (countdowns[shopName]! > 0) {
          countdowns[shopName] = countdowns[shopName]! - 1;
        } else {
          timer.cancel();
          countdowns.remove(shopName);
          timers.remove(shopName);

          final shopIndex = allShops.indexWhere((s) => s['name'] == shopName);
          if (shopIndex != -1) {
            final shopId = allShops[shopIndex]['id'];
            allShops[shopIndex]['status'] = 'Unpaid';

            FirebaseFirestore.instance
                .collection('routes')
                .doc(widget.routeName)
                .collection('shops')
                .doc(shopId)
                .update({
              'status': 'Unpaid',
              'paidAt': null,
            });

            setState(() {});
          }
        }
      });
    });
  }


  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Maps")),
      );
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
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
        (sum, shop) => sum + ((shop['totalPaid'] ?? 0) as num).toInt(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shops"),
        leading: const BackButton(),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShops,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadShops,
              child: Padding(
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
                              backgroundColor: showUnpaid
                                  ? Colors.blue
                                  : Colors.grey.shade200,
                              foregroundColor:
                                  showUnpaid ? Colors.white : Colors.black,
                            ),
                            child: const Text("Unpaid"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => showUnpaid = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "🔴Refresh the page to see the time remaining🔴"),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            },
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
                      child: RefreshIndicator(
                        onRefresh: _loadShops,
                        child: ListView.builder(
                          itemCount: filteredShops.length,
                          itemBuilder: (context, index) {
                            final shop = filteredShops[index];
                            final name = shop['name'];
                            final status = shop['status'];
                            final paidAt = shop['paidAt'] as DateTime?;
                            int remainingSeconds = 0;

                            if (shop['status'] == 'Paid' && paidAt != null) {
                              final diff =
                                  DateTime.now().difference(paidAt).inSeconds;
                              remainingSeconds =
                                  43200 - diff; // or 43200 for 12 hours
                              if (remainingSeconds < 0) remainingSeconds = 0;
                            }

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
                                        shopId: shop[
                                            'id'], // must be doc ID from Firestore
                                        onBalanceAdjusted:
                                            (shopName, reducedAmount) async {
                                          final updatedShops =
                                              List<Map<String, dynamic>>.from(
                                                  allShops);
                                          final shopIndex =
                                              updatedShops.indexWhere((shop) =>
                                                  shop['name'] == shopName);
                                          if (shopIndex != -1) {
                                            final shopId = updatedShops[
                                                    shopIndex][
                                                'id']; // Make sure you're storing Firestore doc IDs
                                            final currentAmount =
                                                updatedShops[shopIndex]
                                                    ['amount'];
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
                                              'paidAt':
                                                  FieldValue.serverTimestamp(),
                                              'paidAmount':
                                                  reducedAmount, // just the last payment
                                              'totalPaid': FieldValue.increment(
                                                  reducedAmount), // running total
                                            });

                                            setState(() {
                                              updatedShops[shopIndex]
                                                  ['status'] = 'Paid';
                                              updatedShops[shopIndex]
                                                  ['amount'] = newAmount;
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
                                      color: Colors.yellow,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(shop['address'],
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    Text(shop['phone'],
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    if (shop['status'] == 'Paid' &&
                                        shop['totalPaid'] != null)
                                      Text("Paid: Rs.${shop['totalPaid']}",
                                          style: const TextStyle(
                                              color: Colors.lightGreenAccent))
                                    else if (shop['status'] == 'Unpaid' &&
                                        shop['amount'] != null)
                                      Text("Balance: Rs.${shop['amount']}",
                                          style: const TextStyle(
                                              color: Colors.orangeAccent)),
                                  ],
                                ),
                                trailing: shop['status'] == 'Paid' &&
                                        remainingSeconds > 0
                                    ? Text(
                                        "Reverting in ${formatDuration(Duration(seconds: remainingSeconds))}",
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.location_pin,
                                            color: Colors.pinkAccent),
                                        onPressed: () {
                                          final lat = shop['latitude'];
                                          final lng = shop['longitude'];

                                          if (lat == null || lng == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Location not available for this shop")),
                                            );
                                          } else {
                                            final googleMapsUrl = Uri.parse(
                                                "https://www.google.com/maps/search/?api=1&query=$lat,$lng");
                                            launchUrl(googleMapsUrl,
                                                mode: LaunchMode
                                                    .externalApplication);
                                          }
                                        },
                                      ),
                              ),
                            );
                          },
                        ),
                      ), // Change from 12 hours
                    ),
                 
                     
                  ],
                ),
              ),
            ),
    );
  }
}
