import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({Key? key}) : super(key: key);

  @override
  _PosScreenState createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<Map<String, dynamic>> _cart = [];
  double _total = 0.0;

  void _addToCart(String itemName, double price) {
    setState(() {
      _cart.add({'name': itemName, 'price': price});
      _total += price;
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _total = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LaundryPro POS Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Manual Sync',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings & Peripherals',
            onPressed: () {},
          )
        ],
      ),
      body: Row(
        children: [
          // Left: Services Catalog
          Expanded(
            flex: 2,
            child: Container(
              color: AppTheme.background,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Services',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildServiceCard('Wash & Fold', 15.0, Icons.local_laundry_service),
                        _buildServiceCard('Dry Cleaning', 25.0, Icons.checkroom),
                        _buildServiceCard('Ironing', 10.0, Icons.iron),
                        _buildServiceCard('Carpet Cleaning', 50.0, Icons.layers),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right: Cart / Checkout
          Expanded(
            flex: 1,
            child: Container(
              color: AppTheme.cardColor,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.grey.shade100,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Icon(Icons.shopping_cart_outlined),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final item = _cart[index];
                        return ListTile(
                          title: Text(item['name']),
                          trailing: Text('AED ${item['price'].toStringAsFixed(2)}'),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('AED ${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _clearCart,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(24),
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('VOID', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _cart.isEmpty ? null : () {},
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(24),
                            backgroundColor: AppTheme.primaryBlue,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: const Text('PAY & PRINT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, double price, IconData icon) {
    return InkWell(
      onTap: () => _addToCart(title, price),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.primaryBlue),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('AED ${price.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}
