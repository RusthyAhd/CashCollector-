import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shoplistscreen.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  double totalPaidAcrossRoutes = 0;
  bool isUploading = false;
  String? uploadedFileUrl;

  @override
  void initState() {
    super.initState();
    _fetchTotalPaidAcrossAllRoutes();
  }

  Future<void> _fetchTotalPaidAcrossAllRoutes() async {
    double totalPaid = 0;

    final routesSnapshot =
        await FirebaseFirestore.instance.collection('routes').get();

    for (var routeDoc in routesSnapshot.docs) {
      final shopsSnapshot = await routeDoc.reference.collection('shops').get();

      for (var shopDoc in shopsSnapshot.docs) {
        final shopData = shopDoc.data();
        final shopTotalPaid = shopData['totalPaid'];

        if (shopTotalPaid != null) {
          totalPaid += (shopTotalPaid as num).toDouble();
        }
      }
    }
    // ✅ Save totalPaid to Firestore (admin/summary)
    await FirebaseFirestore.instance.collection('admin').doc('summary').set({
      'latestTotalPaid': totalPaid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ✅ Update local state
    setState(() {
      totalPaidAcrossRoutes = totalPaid;
    });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                isUploading = true;
              });
              await _fetchTotalPaidAcrossAllRoutes();
              setState(() {
                isUploading = false;
              });
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTotalPaidAcrossAllRoutes,
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
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Total Paid: Rs.${totalPaidAcrossRoutes.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (uploadedFileUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("Receipt Uploaded ✅",
                          style: const TextStyle(color: Colors.green)),
                    ),
                  const SizedBox(height: 12),                 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
