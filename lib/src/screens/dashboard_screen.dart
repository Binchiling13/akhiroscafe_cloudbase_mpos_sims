import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../controllers/order_controller.dart';
import '../controllers/product_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderController>(context, listen: false).loadOrders();
      Provider.of<ProductController>(context, listen: false).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrderController, ProductController>(
      builder: (context, orderController, productController, child) {
        final orders = orderController.orders;

        // Calculate metrics
        final todaySales = orders.fold<double>(0, (sum, order) => sum + order.total);
        final totalOrders = orders.length;
        final totalItems = orders.fold<int>(0, (sum, order) => sum + order.totalItems);
        final averageOrderValue = totalOrders > 0 ? todaySales / totalOrders : 0.0;

        // Calculate top selling products from actual orders
        final Map<String, Map<String, dynamic>> productSales = {};
        
        for (final order in orders) {
          for (final item in order.items) {
            if (productSales.containsKey(item.productId)) {
              productSales[item.productId]!['quantity'] += item.quantity;
              productSales[item.productId]!['revenue'] += item.totalPrice;
            } else {
              productSales[item.productId] = {
                'name': item.productName,
                'quantity': item.quantity,
                'revenue': item.totalPrice,
                'price': item.price,
              };
            }
          }
        }

        // Sort products by quantity sold and take top 5
        final topProducts = productSales.entries
            .map((entry) => {
                  'id': entry.key,
                  'name': entry.value['name'],
                  'quantity': entry.value['quantity'],
                  'revenue': entry.value['revenue'],
                  'price': entry.value['price'],
                })
            .toList()
          ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

        final topProductsList = topProducts.take(5).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                onPressed: () {
                  orderController.loadOrders();
                  productController.loadProducts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data refreshed!')),
                  );
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: orderController.isLoading || productController.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome section
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Here\'s what\'s happening in your cafe today',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Metrics cards
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                'Today\'s Sales',
                                'Php ${todaySales.toStringAsFixed(2)}',
                                Icons.attach_money,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                'Total Orders',
                                totalOrders.toString(),
                                Icons.receipt,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                'Items Sold',
                                totalItems.toString(),
                                Icons.shopping_cart,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMetricCard(
                                context,
                                'Average Order',
                                'Php ${averageOrderValue.toStringAsFixed(2)}',
                                Icons.trending_up,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Charts and top products
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            // Sales chart
                            Expanded(
                              flex: 2,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sales Overview',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: LineChart(
                                          _buildSalesChart(orders),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Top products
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Top Products',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: topProductsList.isEmpty
                                            ? const Center(child: Text('No sales data available'))
                                            : ListView.builder(
                                                itemCount: topProductsList.length,
                                                itemBuilder: (context, index) {
                                                  final product = topProductsList[index];
                                                  return ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundColor: Theme.of(context).primaryColor,
                                                      child: Text(
                                                        '${index + 1}',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    title: Text(product['name']),
                                                    subtitle: Text('Sold: ${product['quantity']} units'),
                                                    trailing: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          'Php ${product['price'].toStringAsFixed(2)}',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Revenue: Php ${product['revenue'].toStringAsFixed(0)}',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildSalesChart(List<dynamic> orders) {
    // Group orders by day of the week for the last 7 days
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1)); // Monday
    
    Map<int, double> dailySales = {};
    
    // Initialize all days with 0
    for (int i = 0; i < 7; i++) {
      dailySales[i] = 0.0;
    }
    
    // Calculate sales for each day
    for (final order in orders) {
      final orderDate = order.dateTime;
      final daysDiff = orderDate.difference(weekStart).inDays;
      
      // Only include orders from the current week
      if (daysDiff >= 0 && daysDiff < 7) {
        dailySales[daysDiff] = (dailySales[daysDiff] ?? 0) + order.total;
      }
    }
    
    // Create chart spots from the data
    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), dailySales[i] ?? 0));
    }
    
    // Find max value for better scaling
    final maxValue = dailySales.values.isEmpty ? 100.0 : 
        dailySales.values.reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxValue * 1.2; // Add 20% padding
    
    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              if (value.toInt() >= 0 && value.toInt() < days.length) {
                return Text(
                  days[value.toInt()],
                  style: const TextStyle(fontSize: 12),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const Text('0');
              if (value >= 1000) {
                return Text('${(value / 1000).toStringAsFixed(0)}k');
              }
              return Text('${value.toInt()}');
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      minY: 0,
      maxY: chartMaxY > 0 ? chartMaxY : 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.blue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }
}
