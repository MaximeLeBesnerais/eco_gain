import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/purchase_decision.dart';
import '../utils/currency_helper.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _priceController = TextEditingController();
  double _hourlyRate = 0.0;
  double _yearlySalary = 0.0;
  double _monthlySalary = 0.0;
  double _workHours = 0.0;
  bool _isCalculated = false;
  bool _isLoading = true;
  String _currencySymbol = '\$';

  @override
  void initState() {
    super.initState();
    _loadSalaryData();
  }

  Future<void> _loadSalaryData() async {
    final prefs = await SharedPreferences.getInstance();
    final symbol = await CurrencyHelper.getCurrencySymbol();
    setState(() {
      _hourlyRate = prefs.getDouble('hourly_rate') ?? 0.0;
      _yearlySalary = prefs.getDouble('yearly_salary') ?? 0.0;
      _monthlySalary = prefs.getDouble('monthly_salary') ?? 0.0;
      _currencySymbol = symbol;
      _isLoading = false;
    });
  }

  void _calculateWorkHours() {
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      _showErrorDialog('Please enter a valid price');
      return;
    }

    if (_hourlyRate <= 0) {
      _showErrorDialog('Please set your salary in the Settings tab first');
      return;
    }

    setState(() {
      _workHours = price / _hourlyRate;
      _isCalculated = true;
    });

    // Show modal immediately after calculation
    _showDecisionModal();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDecisionModal() {
    final price = double.tryParse(_priceController.text) ?? 0.0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Price and Time Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Column(
                children: [
                  const Icon(Icons.schedule, size: 40, color: Colors.orange),
                  const SizedBox(height: 12),
                  Text(
                    '$_currencySymbol${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This costs you',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatHours(_workHours),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'of work time',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'What will you do?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Buy Button
            _buildModalButton(
              onPressed: () {
                Navigator.pop(context);
                _saveDecision('buy');
              },
              icon: Icons.shopping_bag,
              label: 'Buy',
              color: Colors.blue,
              description: 'I\'m buying this item',
            ),
            const SizedBox(height: 12),
            
            // Don't Buy Button
            _buildModalButton(
              onPressed: () {
                Navigator.pop(context);
                _saveDecision('dont_buy');
              },
              icon: Icons.savings,
              label: 'Don\'t Buy',
              color: Colors.green,
              description: 'Save money and time!',
            ),
            const SizedBox(height: 12),
            
            // Think About It Button
            _buildModalButton(
              onPressed: () {
                Navigator.pop(context);
                _saveDecision('think_about_it');
              },
              icon: Icons.lightbulb_outline,
              label: 'Think About It',
              color: Colors.orange,
              description: 'Decide later',
            ),
            const SizedBox(height: 12),
            
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDecision(String decision) async {
    final price = double.tryParse(_priceController.text);
    if (price == null || !_isCalculated) return;

    // Get current work parameters
    final prefs = await SharedPreferences.getInstance();
    final hoursPerWeek = prefs.getDouble('hours_per_week') ?? 40.0;
    final weeksPerYear = prefs.getDouble('weeks_per_year') ?? 52.0;

    final purchaseDecision = PurchaseDecision(
      price: price,
      workHours: _workHours,
      decision: decision,
      timestamp: DateTime.now(),
      hourlyRate: _hourlyRate,
      yearlySalary: _yearlySalary,
      monthlySalary: _monthlySalary,
      hoursPerWeek: hoursPerWeek,
      weeksPerYear: weeksPerYear,
    );

    await DatabaseHelper.instance.insertDecision(purchaseDecision);

    if (!mounted) return;

    String message = '';
    Color backgroundColor = Colors.green;

    switch (decision) {
      case 'buy':
        message = 'Purchase recorded!';
        backgroundColor = Colors.blue;
        break;
      case 'dont_buy':
        message = 'Great decision! You saved ${_formatHours(_workHours)} of work!';
        backgroundColor = Colors.green;
        break;
      case 'think_about_it':
        message = 'Taking time to think is wise!';
        backgroundColor = Colors.orange;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );

    // Reset the form
    setState(() {
      _priceController.clear();
      _workHours = 0.0;
      _isCalculated = false;
    });
  }

  String _formatHours(double hours) {
    if (hours < 1) {
      final minutes = (hours * 60).round();
      return '$minutes minutes';
    } else if (hours < 8) {
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    } else {
      final days = (hours / 8).floor();
      final remainingHours = (hours % 8).round();
      return remainingHours > 0 
          ? '$days days ${remainingHours}h' 
          : '$days days';
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Hero Section
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.attach_money, size: 60, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(height: 16),
                    Text(
                      'What are you thinking of buying?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calculate how much work time it costs',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Price Input Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter Price',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: '$_currencySymbol ',
                        prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      ),
                      onChanged: (value) {
                        if (_isCalculated) {
                          setState(() {
                            _isCalculated = false;
                            _workHours = 0.0;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _calculateWorkHours,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calculate & Decide'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info message when salary not set
            if (_hourlyRate <= 0) ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please set your salary in the Settings tab to start calculating',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildModalButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required String description,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 20),
        ],
      ),
    );
  }
}
