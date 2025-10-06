import 'package:cash_collector/screens/addReceipts.dart';
import 'package:cash_collector/screens/add_order_screen.dart';
import 'package:cash_collector/screens/shoplistscreen.dart';
import 'package:cash_collector/screens/termsandconditions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_spinkit/flutter_spinkit.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
 // final String googleFormUrl =
   //   "https://docs.google.com/forms/d/e/1FAIpQLSfZOSjqEHGOQuRZeCr6XF7JWrqLbFronAMdiHJ28d853Nau8g/viewform?usp=header";
  bool isBalanceLoading = true;
  bool isTodayCollectionLoading = true;
  bool isWeekCollectionLoading = true;
  double totalPaidAcrossRoutes = 0;
  bool isUploading = false;
  double totalPaidTodayAmount = 0;
  double totalPaidThisWeekAmount = 0;
  double targetCollectAmount = 0.0;

  @override
  void initState() {
    super.initState();
    saveDailyPaidShopsBreakdown();
    getLatestPaidShopsCount();
    _fetchTotalPaidAcrossAllRoutes();
    _fetchWeekPaid();
    _fetchTotalPaidToday();
    _fetchTargetCollectAmount();
  }

  // Future<void> copyAndRenameShop({
  //   required String fromRoute,
  //   required String fromShopId,
  //   required String toRoute,
  //   required String newShopId,
  // }) async {
  //   final firestore = FirebaseFirestore.instance;

  //   // Old shop reference
  //   final oldShopRef = firestore
  //       .collection('routes')
  //       .doc(fromRoute)
  //       .collection('shops')
  //       .doc(fromShopId);

  //   // New shop reference (renamed + moved)
  //   final newShopRef = firestore
  //       .collection('routes')
  //       .doc(toRoute)
  //       .collection('shops')
  //       .doc(newShopId);

  //   // Get old shop data
  //   final oldSnapshot = await oldShopRef.get();
  //   if (!oldSnapshot.exists) {
  //     print("❌ Shop $fromShopId not found in $fromRoute.");
  //     return;
  //   }

  //   // Create new doc with same data
  //   await newShopRef.set(oldSnapshot.data()!);

  //   // Copy subcollections
  //   await _copySubcollection(oldShopRef, newShopRef, 'cashAdditions');
  //   await _copySubcollection(oldShopRef, newShopRef, 'feedbacks');
  //   await _copySubcollection(oldShopRef, newShopRef, 'transactions');

  //   print("✅ Shop copied as $newShopId into $toRoute.");
  // }

  // Future<void> _copySubcollection(DocumentReference sourceDoc,
  //     DocumentReference targetDoc, String subName) async {
  //   final subSnap = await sourceDoc.collection(subName).get();
  //   for (var doc in subSnap.docs) {
  //     final newDocRef = targetDoc.collection(subName).doc(doc.id);
  //     await newDocRef.set(doc.data());
  //   }
  // }

  Future<void> saveDailyPaidShopsBreakdown() async {
    final txSnapshot = await FirebaseFirestore.instance
        .collectionGroup('transactions')
        .where('timestamp', isNotEqualTo: null)
        .get();

    // Map<date, Set<shopIds>>
    Map<String, Set<String>> dailyShopTracker = {};

    for (var doc in txSnapshot.docs) {
      final data = doc.data();
      if (data['timestamp'] == null) continue;

      // ✅ Skip "credit" transactions
      if (data['type'] == 'Credit') continue;

      final ts = data['timestamp'] as Timestamp;
      final dateKey =
          "${ts.toDate().year}-${ts.toDate().month.toString().padLeft(2, '0')}-${ts.toDate().day.toString().padLeft(2, '0')}";

      // shopId is the parent doc of "transactions"
      final shopId = doc.reference.parent.parent!.id;

      dailyShopTracker.putIfAbsent(dateKey, () => {});
      dailyShopTracker[dateKey]!.add(shopId);
    }

    // Save each date’s count into Firestore
    final historyRef = FirebaseFirestore.instance
        .collection('admin')
        .doc('summary')
        .collection('dailyPaidShops');

    for (var entry in dailyShopTracker.entries) {
      await historyRef.doc(entry.key).set({
        'date': entry.key,
        'paidShopsCount': entry.value.length,
        'shopIds': entry.value.toList(), // optional: keep shop list
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<int> getLatestPaidShopsCount() async {
    final now = DateTime.now();
    final todayKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final doc = await FirebaseFirestore.instance
        .collection('admin')
        .doc('summary')
        .collection('dailyPaidShops')
        .doc(todayKey)
        .get();

    if (doc.exists && doc.data() != null) {
      return doc.data()!['paidShopsCount'] ?? 0;
    }
    return 0;
  }

  // Future<void> _launchForm() async {
  //   final Uri uri = Uri.parse(googleFormUrl);
  //   try {
  //     if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Could not launch the Google Form')),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e')),
  //     );
  //   }
  // }

  Future<void> _fetchTargetCollectAmount() async {
    final doc =
        await FirebaseFirestore.instance.collection('admin').doc('stats').get();

    if (doc.exists && doc.data()!.containsKey('targetWeek')) {
      setState(() {
        targetCollectAmount = (doc['targetWeek'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _fetchTotalPaidAcrossAllRoutes() async {
    setState(() => isBalanceLoading = true);
    double totalPaid = 0;

    final routesSnapshot =
        await FirebaseFirestore.instance.collection('routes').get();

    for (var routeDoc in routesSnapshot.docs) {
      final shopsSnapshot = await routeDoc.reference.collection('shops').get();

      for (var shopDoc in shopsSnapshot.docs) {
        final shopData = shopDoc.data();
        final shopTotalPaid = (shopData['totalPaid'] ?? 0).toDouble();

        // ✅ Total across all time
        totalPaid += shopTotalPaid;
      }
    }

    // ✅ Save to Firestore
    await FirebaseFirestore.instance.collection('admin').doc('summary').set({
      'latestTotalPaid': totalPaid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ✅ Update local state
    setState(() {
      totalPaidAcrossRoutes = totalPaid;
      isBalanceLoading = false;
    });
  }

  Future<void> _fetchWeekPaid() async {
    setState(() => isWeekCollectionLoading = true);
    final now = DateTime.now();

    // Get Monday and Sunday of the current week
    final int currentWeekday = now.weekday; // Monday = 1, Sunday = 7
    final DateTime mondayThisWeek =
        now.subtract(Duration(days: currentWeekday - 1));
    final DateTime sundayThisWeek = mondayThisWeek.add(const Duration(days: 6));

    final Timestamp startOfWeek = Timestamp.fromDate(DateTime(
      mondayThisWeek.year,
      mondayThisWeek.month,
      mondayThisWeek.day,
      0,
      0,
      0,
    ));

    final Timestamp endOfWeek = Timestamp.fromDate(DateTime(
      sundayThisWeek.year,
      sundayThisWeek.month,
      sundayThisWeek.day,
      23,
      59,
      59,
    ));

    double total = 0;

    // Fetch all deductions in this week range
    final deductionsSnapshot = await FirebaseFirestore.instance
        .collection('deductions')
        .where('sentAt', isGreaterThanOrEqualTo: startOfWeek)
        .where('sentAt', isLessThanOrEqualTo: endOfWeek)
        .get();

    for (var doc in deductionsSnapshot.docs) {
      final data = doc.data();
      final type = data['type'];
      final amount = (data['amount'] ?? 0).toDouble();
// Include if type is not 'Credit'
      if (type == null || type == 'paid' || type != 'Credit') {
        total += amount;
      }
    }

    setState(() {
      totalPaidThisWeekAmount = total;
      isWeekCollectionLoading = false;
    });
    await FirebaseFirestore.instance.collection('admin').doc('summary').set({
      'weekPaid': total,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _fetchTotalPaidToday() async {
    setState(() => isTodayCollectionLoading = true);
    double totalPaidToday = 0;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final routesSnapshot =
        await FirebaseFirestore.instance.collection('routes').get();

    for (var routeDoc in routesSnapshot.docs) {
      final shopsSnapshot = await routeDoc.reference.collection('shops').get();

      for (var shopDoc in shopsSnapshot.docs) {
        final transactionsSnapshot = await shopDoc.reference
            .collection('transactions')
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
            .get();

        for (var txnDoc in transactionsSnapshot.docs) {
          final txnData = txnDoc.data();
          final type = txnData['type'];
          final amount = (txnData['amount'] ?? 0).toDouble();

          if (type == null || type == 'paid' || type != 'Credit') {
            totalPaidToday += amount;
          }
        }
      }
    }

    // ✅ Update local state
    setState(() {
      totalPaidTodayAmount = totalPaidToday;
      isTodayCollectionLoading = false;
    });

    final summaryRef =
        FirebaseFirestore.instance.collection('admin').doc('summary');

    // ✅ Save to summary (latest value)
    await summaryRef.set({
      'todayTotalPaid': totalPaidToday,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ✅ Save as history (daily record)
    final dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    await summaryRef.collection('todayCollectionHistory').doc(dateKey).set({
      'date': dateKey,
      'amount': totalPaidToday,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFAF1),
      appBar: AppBar(
        title: const Text("Choose Area"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade800,
        elevation: 1,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                setState(() {
                  isUploading = true;
                  isTodayCollectionLoading = true;
                  isWeekCollectionLoading = true;
                });
                await _fetchTotalPaidAcrossAllRoutes();
                await _fetchTotalPaidToday();
                setState(() {
                  isUploading = false;
                  isTodayCollectionLoading = false;
                  isWeekCollectionLoading = false;
                });
              },
            )
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(130),
              color: const Color.fromARGB(255, 139, 126, 126),
              boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
              ],
            ),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Material(
              color: Colors.transparent,
              elevation: 9,
              borderRadius: BorderRadius.circular(160),
              child: IconButton(
          icon: Center(
            child: const Text(
              "🚨",
              style: TextStyle(fontSize: 28, color: Colors.green),
            ),
          ),
          tooltip: "Terms & Conditions",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TermsAndConditionsPage()),
            );
          },
              ),
            ),
          ),
        ],
                ),
              

      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchTotalPaidAcrossAllRoutes();
          await _fetchTotalPaidToday();
        },
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('routes').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No routes found"));
                  }

                  final routes = snapshot.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    itemCount: routes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final doc = routes[index];
                      final routeName = doc.id;
                      final emoji = "🛣️";

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 3,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ShopListScreen(routeName: routeName),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 16),
                            child: Row(
                              children: [
                                Text(emoji,
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    routeName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: IconButton(
                    icon: const Icon(Icons.inventory_2_rounded,
                        color: Colors.teal),
                    tooltip: 'View Stock',
                    iconSize: 32,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 227, 245, 236),
                      foregroundColor: const Color.fromARGB(255, 201, 238, 178),
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderPage(),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddReceipts(),
                        ),
                      );
                    },
                    icon: Icon(Icons.upload_file),
                    label: Text("Upload Reciept "),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade100,
                      foregroundColor: Colors.black,
                      padding:
                          EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Card(
                        child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: isBalanceLoading
                          ? const SpinKitThreeBounce(
                              color: Colors.green,
                              size: 24.0,
                            )
                          : Text(
                              "Balance in Hand: Rs.${totalPaidAcrossRoutes.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                    )),
                  ),
                  const SizedBox(height: 8),
                  isTodayCollectionLoading
                      ? const SpinKitThreeBounce(
                          color: Colors.green,
                          size: 20.0,
                        )
                      : Center(
                          child: Text(
                            "Today Collection: Rs.${totalPaidTodayAmount.toStringAsFixed(2)}",
                            style: TextStyle(
                                color: Colors.green[700], fontSize: 16),
                          ),
                        ),
                  const SizedBox(height: 4),
                  isWeekCollectionLoading
                      ? const SpinKitThreeBounce(
                          color: Colors.blue,
                          size: 20.0,
                        )
                      : Center(
                          child: Text(
                            "Paid This Week: Rs.${totalPaidThisWeekAmount.toStringAsFixed(2)}",
                            style: TextStyle(
                                color: Colors.blue[700], fontSize: 16),
                          ),
                        ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: paidShopsSummaryCard(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 32, color: Colors.deepOrangeAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Target of This Week",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Rs. ${targetCollectAmount.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

Widget paidShopsSummaryCard() {
  final now = DateTime.now();

  // Today's key
  final todayKey =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  final todayDocRef = FirebaseFirestore.instance
      .collection('admin')
      .doc('summary')
      .collection('dailyPaidShops')
      .doc(todayKey);

  // ✅ Week range query (Monday → Sunday)
  final int currentWeekday = now.weekday; // Monday=1, Sunday=7
  final DateTime mondayThisWeek =
      now.subtract(Duration(days: currentWeekday - 1));
  final DateTime sundayThisWeek = mondayThisWeek.add(const Duration(days: 6));

  final String weekStartKey =
      "${mondayThisWeek.year}-${mondayThisWeek.month.toString().padLeft(2, '0')}-${mondayThisWeek.day.toString().padLeft(2, '0')}";

  final String weekEndKey =
      "${sundayThisWeek.year}-${sundayThisWeek.month.toString().padLeft(2, '0')}-${sundayThisWeek.day.toString().padLeft(2, '0')}";

  final weekCollectionRef = FirebaseFirestore.instance
      .collection('admin')
      .doc('summary')
      .collection('dailyPaidShops')
      .where('date', isGreaterThanOrEqualTo: weekStartKey)
      .where('date', isLessThanOrEqualTo: weekEndKey);

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      // Today Paid Shops Card
      Expanded(
        child: StreamBuilder<DocumentSnapshot>(
          stream: todayDocRef.snapshots(),
          builder: (context, snapshot) {
            int todayCount = 0;
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              todayCount = data['paidShopsCount'] ?? 0;
            }

            return Card(
              color: Colors.green[50],
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Today's Paid",
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      "$todayCount",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(width: 8),

      // ✅ Week Paid Shops Card
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: weekCollectionRef.snapshots(),
          builder: (context, snapshot) {
            int weekTotal = 0;
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                weekTotal += (data['paidShopsCount'] ?? 0) as int;
              }
            }
            return Card(
              color: Colors.blue[50],
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Week's Paid",
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      "$weekTotal",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
