import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/purchase_decision.dart';
import '../database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DecisionDetailsModal extends StatelessWidget {
  final PurchaseDecision decision;
  final VoidCallback onUpdate;

  const DecisionDetailsModal({
    super.key,
    required this.decision,
    required this.onUpdate,
  });

  String _formatHours(double hours) {
    if (hours < 1) {
      final minutes = (hours * 60).round();
      return '$minutes min';
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

  String _getDecisionDisplayName(String decision) {
    switch (decision) {
      case 'buy':
        return 'Bought';
      case 'dont_buy':
        return 'Didn\'t Buy';
      case 'think_about_it':
        return 'Pending';
      default:
        return decision;
    }
  }

  Color _getDecisionColor(String decision) {
    switch (decision) {
      case 'buy':
        return Colors.blue;
      case 'dont_buy':
        return Colors.green;
      case 'think_about_it':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getDecisionColor(decision.decision);
    
    return Container(
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
          
          // Decision Status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                Text(
                  _getDecisionDisplayName(decision.decision),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMMM d, yyyy • h:mm a').format(decision.timestamp),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Price and Time Info
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Price',
                  '\$${decision.price.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Work Time',
                  _formatHours(decision.workHours),
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          
          // Salary Details at Time of Decision
          Text(
            'Salary Details at Time of Decision',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildDetailRow('Hourly Rate', '\$${decision.hourlyRate.toStringAsFixed(2)}/hr'),
          _buildDetailRow('Monthly Salary', '\$${decision.monthlySalary.toStringAsFixed(2)}/month'),
          _buildDetailRow('Yearly Salary', '\$${decision.yearlySalary.toStringAsFixed(2)}/year'),
          _buildDetailRow('Hours per Week', '${decision.hoursPerWeek.toStringAsFixed(1)} hours'),
          _buildDetailRow('Weeks per Year', '${decision.weeksPerYear.toStringAsFixed(0)} weeks'),
          _buildDetailRow('Total Hours/Year', '${(decision.hoursPerWeek * decision.weeksPerYear).toStringAsFixed(0)} hours'),
          
          const SizedBox(height: 24),
          
          // Close Button
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Modal for pending decisions
class PendingDecisionModal extends StatelessWidget {
  final PurchaseDecision decision;
  final VoidCallback onUpdate;

  const PendingDecisionModal({
    super.key,
    required this.decision,
    required this.onUpdate,
  });

  String _formatHours(double hours) {
    if (hours < 1) {
      final minutes = (hours * 60).round();
      return '$minutes min';
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

  Future<void> _updateDecision(BuildContext context, String newDecision) async {
    // Get current salary and work parameters to recalculate work hours
    final prefs = await SharedPreferences.getInstance();
    final currentHourlyRate = prefs.getDouble('hourly_rate') ?? decision.hourlyRate;
    final currentYearlySalary = prefs.getDouble('yearly_salary') ?? decision.yearlySalary;
    final currentMonthlySalary = prefs.getDouble('monthly_salary') ?? decision.monthlySalary;
    final currentHoursPerWeek = prefs.getDouble('hours_per_week') ?? 40.0;
    final currentWeeksPerYear = prefs.getDouble('weeks_per_year') ?? 52.0;
    
    // Recalculate work hours with current salary
    final newWorkHours = decision.price / currentHourlyRate;
    
    // Delete old decision
    await DatabaseHelper.instance.deleteDecision(decision.id!);
    
    // Create new decision with updated values
    final updatedDecision = PurchaseDecision(
      price: decision.price,
      workHours: newWorkHours,
      decision: newDecision,
      timestamp: DateTime.now(),
      hourlyRate: currentHourlyRate,
      yearlySalary: currentYearlySalary,
      monthlySalary: currentMonthlySalary,
      hoursPerWeek: currentHoursPerWeek,
      weeksPerYear: currentWeeksPerYear,
    );
    
    await DatabaseHelper.instance.insertDecision(updatedDecision);
    
    if (!context.mounted) return;
    
    String message = '';
    Color backgroundColor = Colors.green;
    
    switch (newDecision) {
      case 'buy':
        message = 'Decision updated: Bought';
        backgroundColor = Colors.blue;
        break;
      case 'dont_buy':
        message = 'Decision updated: Didn\'t Buy';
        backgroundColor = Colors.green;
        break;
      case 'think_about_it':
        message = 'Still thinking...';
        backgroundColor = Colors.orange;
        break;
    }
    
    Navigator.pop(context);
    onUpdate();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: SharedPreferences.getInstance().then((prefs) => prefs.getDouble('hourly_rate') ?? decision.hourlyRate),
      builder: (context, snapshot) {
        final currentHourlyRate = snapshot.data ?? decision.hourlyRate;
        final currentWorkHours = decision.price / currentHourlyRate;
        
        return Container(
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
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade300, Colors.orange.shade500],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.schedule, size: 40, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      '\$${decision.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Current work time cost:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatHours(currentWorkHours),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
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
              _buildActionButton(
                context,
                onPressed: () => _updateDecision(context, 'buy'),
                icon: Icons.shopping_bag,
                label: 'Buy',
                color: Colors.blue,
                description: 'I\'m buying this item',
              ),
              const SizedBox(height: 12),
              
              // Don't Buy Button
              _buildActionButton(
                context,
                onPressed: () => _updateDecision(context, 'dont_buy'),
                icon: Icons.savings,
                label: 'Don\'t Buy',
                color: Colors.green,
                description: 'Save money and time!',
              ),
              const SizedBox(height: 12),
              
              // Think About It Button
              _buildActionButton(
                context,
                onPressed: () => _updateDecision(context, 'think_about_it'),
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
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
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
