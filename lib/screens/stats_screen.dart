import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/purchase_decision.dart';
import '../widgets/decision_modals.dart';
import '../utils/currency_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  List<PurchaseDecision> _allDecisions = [];
  bool _isLoading = true;
  String _currencySymbol = '\$';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDecisions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDecisions() async {
    final decisions = await DatabaseHelper.instance.getAllDecisions();
    final symbol = await CurrencyHelper.getCurrencySymbol();
    setState(() {
      _allDecisions = decisions;
      _currencySymbol = symbol;
      _isLoading = false;
    });
  }

  double get _totalMoneySaved {
    return _allDecisions
        .where((d) => d.decision == 'dont_buy')
        .fold(0.0, (sum, d) => sum + d.price);
  }

  Future<double> get _totalWorkTimeSavedCurrent async {
    // Calculate total work time saved from "don't buy" decisions
    double total = 0.0;
    for (var decision in _allDecisions.where((d) => d.decision == 'dont_buy')) {
      total += decision.workHours;
    }
    return total;
  }

  int get _totalBuyCount {
    return _allDecisions.where((d) => d.decision == 'buy').length;
  }

  int get _totalDontBuyCount {
    return _allDecisions.where((d) => d.decision == 'dont_buy').length;
  }

  int get _totalThinkCount {
    return _allDecisions.where((d) => d.decision == 'think_about_it').length;
  }

  List<PurchaseDecision> get _completedDecisions {
    return _allDecisions.where((d) => d.decision == 'buy' || d.decision == 'dont_buy').toList();
  }

  List<PurchaseDecision> get _pendingDecisions {
    return _allDecisions.where((d) => d.decision == 'think_about_it').toList();
  }

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

  Future<double> _getCurrentWorkHours(PurchaseDecision decision) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHourlyRate = prefs.getDouble('hourly_rate') ?? decision.hourlyRate;
    return decision.price / currentHourlyRate;
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

  IconData _getDecisionIcon(String decision) {
    switch (decision) {
      case 'buy':
        return Icons.shopping_bag;
      case 'dont_buy':
        return Icons.savings;
      case 'think_about_it':
        return Icons.lightbulb_outline;
      default:
        return Icons.help_outline;
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

  void _showDecisionModal(PurchaseDecision decision) {
    if (decision.decision == 'think_about_it') {
      // Show pending decision modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PendingDecisionModal(
          decision: decision,
          onUpdate: _loadDecisions,
        ),
      );
    } else {
      // Show decision details modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DecisionDetailsModal(
          decision: decision,
          onUpdate: _loadDecisions,
        ),
      );
    }
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
      body: _allDecisions.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Floating TabBar at the top
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    labelColor: Theme.of(context).colorScheme.onPrimary,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dashboard, size: 16),
                            SizedBox(width: 6),
                            Text('Summary'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 16),
                            SizedBox(width: 6),
                            Text('Completed'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pending_actions, size: 16),
                            SizedBox(width: 6),
                            Text('Pending'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // TabBarView
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Summary Tab
                      _buildSummaryTab(),
                      // Completed Decisions Tab
                      _buildDecisionList(_completedDecisions, false),
                      // Pending Decisions Tab
                      _buildDecisionList(_pendingDecisions, true),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'No Decisions Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Start making purchase decisions on the Main screen to see your statistics here!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return RefreshIndicator(
      onRefresh: _loadDecisions,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Savings Summary Card
            FutureBuilder<double>(
              future: _totalWorkTimeSavedCurrent,
              builder: (context, snapshot) {
                final workTimeSaved = snapshot.data ?? 0.0;
                return Card(
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
                        Icon(Icons.savings, size: 50, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        const SizedBox(height: 16),
                        Text(
                          'Total Saved',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_currencySymbol${_totalMoneySaved.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.schedule, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${_formatHours(workTimeSaved)} of work saved',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
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
            ),

            const SizedBox(height: 20),

            // Decision Count Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Bought',
                    _totalBuyCount.toString(),
                    Icons.shopping_bag,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Saved',
                    _totalDontBuyCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    _totalThinkCount.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Stats
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.insights, color: Colors.purple.shade600, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Quick Stats',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildQuickStatRow(
                      'Total Decisions',
                      _allDecisions.length.toString(),
                      Icons.list_alt,
                      Colors.purple,
                    ),
                    const Divider(height: 24),
                    _buildQuickStatRow(
                      'Completed',
                      _completedDecisions.length.toString(),
                      Icons.check_circle_outline,
                      Colors.teal,
                    ),
                    const Divider(height: 24),
                    _buildQuickStatRow(
                      'Pending Review',
                      _pendingDecisions.length.toString(),
                      Icons.pending_outlined,
                      Colors.amber,
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

  Widget _buildQuickStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionList(List<PurchaseDecision> decisions, bool isPending) {
    if (decisions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadDecisions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPending ? Icons.pending_actions : Icons.check_circle_outline,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isPending ? 'No Pending Decisions' : 'No Completed Decisions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPending
                          ? 'Items you\'re thinking about will appear here'
                          : 'Your buy/don\'t buy decisions will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDecisions,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: decisions.length,
        itemBuilder: (context, index) {
          final decision = decisions[index];
          return _buildDecisionCard(decision, isPending);
        },
      ),
    );
  }

  Widget _buildDecisionCard(PurchaseDecision decision, bool isPending) {
    final color = _getDecisionColor(decision.decision);
    final icon = _getDecisionIcon(decision.decision);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Dismissible(
        key: Key(decision.id.toString()),
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white, size: 28),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Decision'),
              content: const Text('Are you sure you want to delete this decision?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) async {
          await DatabaseHelper.instance.deleteDecision(decision.id!);
          _loadDecisions();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Decision deleted'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: Card(
          elevation: isPending ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPending 
                ? BorderSide(color: Colors.orange.shade300, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => _showDecisionModal(decision),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: isPending
                  ? FutureBuilder<double>(
                      future: _getCurrentWorkHours(decision),
                      builder: (context, snapshot) {
                        final currentWorkHours = snapshot.data ?? decision.workHours;
                        return _buildDecisionContent(decision, icon, color, currentWorkHours, isPending);
                      },
                    )
                  : _buildDecisionContent(decision, icon, color, decision.workHours, isPending),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecisionContent(
    PurchaseDecision decision,
    IconData icon,
    Color color,
    double workHours,
    bool isPending,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _getDecisionDisplayName(decision.decision),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (isPending) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.touch_app, size: 16, color: Colors.grey.shade600),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$_currencySymbol${decision.price.toStringAsFixed(2)} • ${_formatHours(workHours)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d, yyyy • h:mm a').format(decision.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              if (isPending) ...[
                const SizedBox(height: 4),
                Text(
                  'Updated with current salary',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
      ],
    );
  }
}
