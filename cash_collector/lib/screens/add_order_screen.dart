import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({Key? key}) : super(key: key);

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final TextEditingController remainingShopController = TextEditingController();
  final TextEditingController newShopNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  Future<void> _placeRemainingShopOrder() async {
    if (remainingShopController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter shop name")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("orders").add({
      "type": "remainingShop",
      "shopName": remainingShopController.text.trim(),
      "submittedAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Order placed for remaining shop")),
    );

    remainingShopController.clear();
  }

  Future<void> _placeNewShopOrder() async {
    if (newShopNameController.text.isEmpty ||
        addressController.text.isEmpty ||
        areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Please fill required fields")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("orders").add({
      "type": "newShop",
      "shopName": newShopNameController.text.trim(),
      "address": addressController.text.trim(),
      "phone": phoneController.text.trim(),
      "landmark": landmarkController.text.trim(),
      "area": areaController.text.trim(),
      "description": descriptionController.text.trim(),
      "submittedAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ New shop order placed successfully")),
    );

    newShopNameController.clear();
    addressController.clear();
    phoneController.clear();
    landmarkController.clear();
    areaController.clear();
    descriptionController.clear();
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      IconData? icon,
      int maxLines = 1,
      TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: inputType,
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon) : null,
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Place Order"),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Section 1: Remaining Shop Order
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.shopping_cart, color: Colors.blueGrey),
                        SizedBox(width: 8),
                        Text(
                          "Order for Remaining Shop",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: remainingShopController,
                        label: "Shop Name",
                        icon: Icons.store),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: _placeRemainingShopOrder,
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Place Order"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Section 2: New Shop Order
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.store_mall_directory, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          "Order for New Shop",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: newShopNameController,
                        label: "Shop Name *",
                        icon: Icons.store),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: addressController,
                        label: "Address *",
                        icon: Icons.location_on),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: phoneController,
                        label: "Phone (optional)",
                        icon: Icons.phone,
                        inputType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: landmarkController,
                        label: "Landmark (optional)",
                        icon: Icons.place),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: areaController,
                        label: "Area *",
                        icon: Icons.map),
                    const SizedBox(height: 12),
                    _buildTextField(
                        controller: descriptionController,
                        label: "Description (other details)",
                        icon: Icons.notes,
                        maxLines: 3),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: _placeNewShopOrder,
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Place Order"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
