import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_helper.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;
  
  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _hourlyController = TextEditingController();
  final TextEditingController _monthlyController = TextEditingController();
  final TextEditingController _hoursPerWeekController = TextEditingController();
  final TextEditingController _weeksPerYearController = TextEditingController();
  final TextEditingController _customCurrencyController = TextEditingController();
  
  bool _isLoading = true;
  bool _showAdvancedSettings = false;
  bool _useCustomCurrency = false;
  String _selectedCurrency = '\$';
  
  // Theme settings
  String _themeMode = 'system';
  String _themeColor = 'green';
  
  // Assumptions for calculations (editable in advanced settings)
  double _hoursPerWeek = 40.0;
  double _weeksPerYear = 52.0;
  double get _hoursPerYear => _hoursPerWeek * _weeksPerYear;
  double get _monthsPerYear => 12.0;
  
  // Common currency symbols
  final List<String> _commonCurrencies = [
    '\$', '€', '£', '¥', '₹', '₽', '₩', '₪', '₱', '฿', 'R\$', 'kr', 'Fr', '₴', '₦'
  ];
  
  // Theme options
  final Map<String, String> _themeModes = {
    'system': 'System',
    'light': 'Light',
    'dark': 'Dark',
  };
  
  final Map<String, Color> _themeColors = {
    'blue': Colors.blue,
    'green': Colors.green,
    'pink': Colors.pink,
    'purple': Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _hoursPerWeekController.text = _hoursPerWeek.toString();
    _weeksPerYearController.text = _weeksPerYear.toString();
    _loadSavedValues();
    
    // Add listeners to tab controller to switch focus
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  Future<void> _loadSavedValues() async {
    final prefs = await SharedPreferences.getInstance();
    final yearlySalary = prefs.getDouble('yearly_salary') ?? 0.0;
    final hourlyRate = prefs.getDouble('hourly_rate') ?? 0.0;
    final monthlySalary = prefs.getDouble('monthly_salary') ?? 0.0;
    final hoursPerWeek = prefs.getDouble('hours_per_week') ?? 40.0;
    final weeksPerYear = prefs.getDouble('weeks_per_year') ?? 52.0;
    final useCustomCurrency = prefs.getBool('use_custom_currency') ?? false;
    final selectedCurrency = prefs.getString('selected_currency') ?? '\$';
    final customCurrency = prefs.getString('custom_currency') ?? '';
    final themeMode = prefs.getString('theme_mode') ?? 'system';
    final themeColor = prefs.getString('theme_color') ?? 'green';
    
    setState(() {
      _hoursPerWeek = hoursPerWeek;
      _weeksPerYear = weeksPerYear;
      _hoursPerWeekController.text = hoursPerWeek.toString();
      _weeksPerYearController.text = weeksPerYear.toString();
      _useCustomCurrency = useCustomCurrency;
      if (useCustomCurrency && customCurrency.isNotEmpty) {
        _selectedCurrency = customCurrency;
      } else {
        _selectedCurrency = selectedCurrency;
      }
      _customCurrencyController.text = customCurrency;
      _themeMode = themeMode;
      _themeColor = themeColor;
      
      if (yearlySalary > 0) {
        _salaryController.text = yearlySalary.toStringAsFixed(2);
      }
      if (hourlyRate > 0) {
        _hourlyController.text = hourlyRate.toStringAsFixed(2);
      }
      if (monthlySalary > 0) {
        _monthlyController.text = monthlySalary.toStringAsFixed(2);
      }
      _isLoading = false;
    });
  }

  Future<void> _saveCurrencySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_custom_currency', _useCustomCurrency);
    await prefs.setString('selected_currency', _selectedCurrency);
    await prefs.setString('custom_currency', _customCurrencyController.text);
    setState(() {}); // Trigger rebuild to update UI with new currency
  }

  Future<void> _saveThemeSettings() async {
    await ThemeHelper.saveThemeMode(_getThemeModeEnum(_themeMode));
    await ThemeHelper.saveThemeColor(_themeColor);
    widget.onThemeChanged();
  }

  ThemeMode _getThemeModeEnum(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _saveValues(double yearlySalary, double hourlyRate, double monthlySalary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('yearly_salary', yearlySalary);
    await prefs.setDouble('hourly_rate', hourlyRate);
    await prefs.setDouble('monthly_salary', monthlySalary);
  }

  Future<void> _saveWorkParameters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('hours_per_week', _hoursPerWeek);
    await prefs.setDouble('weeks_per_year', _weeksPerYear);
  }

  void _onYearlySalaryChanged(String value) {
    if (value.isEmpty) {
      _hourlyController.clear();
      _monthlyController.clear();
      _saveValues(0.0, 0.0, 0.0);
      return;
    }
    
    final yearlySalary = double.tryParse(value);
    if (yearlySalary != null && yearlySalary > 0) {
      final hourlyRate = yearlySalary / _hoursPerYear;
      final monthlySalary = yearlySalary / _monthsPerYear;
      _hourlyController.text = hourlyRate.toStringAsFixed(2);
      _monthlyController.text = monthlySalary.toStringAsFixed(2);
      _saveValues(yearlySalary, hourlyRate, monthlySalary);
    }
  }

  void _onHourlyRateChanged(String value) {
    if (value.isEmpty) {
      _salaryController.clear();
      _monthlyController.clear();
      _saveValues(0.0, 0.0, 0.0);
      return;
    }
    
    final hourlyRate = double.tryParse(value);
    if (hourlyRate != null && hourlyRate > 0) {
      final yearlySalary = hourlyRate * _hoursPerYear;
      final monthlySalary = yearlySalary / _monthsPerYear;
      _salaryController.text = yearlySalary.toStringAsFixed(2);
      _monthlyController.text = monthlySalary.toStringAsFixed(2);
      _saveValues(yearlySalary, hourlyRate, monthlySalary);
    }
  }

  void _onMonthlySalaryChanged(String value) {
    if (value.isEmpty) {
      _salaryController.clear();
      _hourlyController.clear();
      _saveValues(0.0, 0.0, 0.0);
      return;
    }
    
    final monthlySalary = double.tryParse(value);
    if (monthlySalary != null && monthlySalary > 0) {
      final yearlySalary = monthlySalary * _monthsPerYear;
      final hourlyRate = yearlySalary / _hoursPerYear;
      _salaryController.text = yearlySalary.toStringAsFixed(2);
      _hourlyController.text = hourlyRate.toStringAsFixed(2);
      _saveValues(yearlySalary, hourlyRate, monthlySalary);
    }
  }

  void _updateWorkParameters() {
    final hoursPerWeek = double.tryParse(_hoursPerWeekController.text);
    final weeksPerYear = double.tryParse(_weeksPerYearController.text);
    
    if (hoursPerWeek != null && weeksPerYear != null && hoursPerWeek > 0 && weeksPerYear > 0) {
      setState(() {
        _hoursPerWeek = hoursPerWeek;
        _weeksPerYear = weeksPerYear;
      });
      _saveWorkParameters();
      
      // Recalculate values if yearly salary exists
      if (_salaryController.text.isNotEmpty) {
        _onYearlySalaryChanged(_salaryController.text);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work parameters updated!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _salaryController.dispose();
    _hourlyController.dispose();
    _monthlyController.dispose();
    _hoursPerWeekController.dispose();
    _weeksPerYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                            Icon(Icons.calendar_today, size: 16),
                            SizedBox(width: 6),
                            Text('Yearly'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month, size: 16),
                            SizedBox(width: 6),
                            Text('Monthly'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.access_time, size: 16),
                            SizedBox(width: 6),
                            Text('Hourly'),
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
                      // Yearly Salary Tab
                      _buildInputTab(
                  title: 'Yearly Salary',
                  controller: _salaryController,
                  onChanged: _onYearlySalaryChanged,
                  prefix: _selectedCurrency,
                  placeholder: '50,000.00',
                  calculatedItems: [
                    _CalculatedItem(
                      label: 'Monthly',
                      value: _monthlyController.text.isEmpty 
                          ? 'N/A' 
                          : '$_selectedCurrency${_formatNumber(_monthlyController.text)}',
                      icon: Icons.calendar_month,
                      color: Colors.blue,
                    ),
                    _CalculatedItem(
                      label: 'Hourly Rate',
                      value: _hourlyController.text.isEmpty 
                          ? 'N/A' 
                          : '$_selectedCurrency${_hourlyController.text}/hr',
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                  ],
                  icon: Icons.account_balance_wallet,
                  iconColor: Colors.green,
                  showAdvanced: true,
                      ),
                      // Monthly Salary Tab
                      _buildInputTab(
                  title: 'Monthly Salary',
                  controller: _monthlyController,
                  onChanged: _onMonthlySalaryChanged,
                  prefix: _selectedCurrency,
                  placeholder: '4,166.67',
                  calculatedItems: [
                    _CalculatedItem(
                      label: 'Yearly',
                      value: _salaryController.text.isEmpty 
                          ? 'N/A' 
                          : '$_selectedCurrency${_formatNumber(_salaryController.text)}',
                      icon: Icons.calendar_today,
                      color: Colors.green,
                    ),
                    _CalculatedItem(
                      label: 'Hourly Rate',
                      value: _hourlyController.text.isEmpty 
                          ? 'N/A' 
                          : '$_selectedCurrency${_hourlyController.text}/hr',
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                  ],
                  icon: Icons.payment,
                  iconColor: Colors.blue,
                  showAdvanced: false,
                      ),
                      // Hourly Rate Tab
                      _buildInputTab(
                  title: 'Hourly Rate',
                  controller: _hourlyController,
                  onChanged: _onHourlyRateChanged,
                  prefix: _selectedCurrency,
                  placeholder: '25.00',
                  calculatedItems: [
                    _CalculatedItem(
                      label: 'Yearly',
                      value: _salaryController.text.isEmpty 
                          ? 'N/A' 
                          : '$_selectedCurrency${_formatNumber(_salaryController.text)}',
                      icon: Icons.calendar_today,
                      color: Colors.green,
                    ),
                    _CalculatedItem(
                      label: 'Monthly',
                      value: _monthlyController.text.isEmpty 
                          ? 'N/A' 
                          : '$_selectedCurrency${_formatNumber(_monthlyController.text)}',
                      icon: Icons.calendar_month,
                      color: Colors.blue,
                    ),
                  ],
                        icon: Icons.timer,
                        iconColor: Colors.orange,
                        showAdvanced: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _formatNumber(String value) {
    final number = double.tryParse(value);
    if (number == null) return value;
    return number.toStringAsFixed(2);
  }

  Widget _buildInputTab({
    required String title,
    required TextEditingController controller,
    required Function(String) onChanged,
    required String prefix,
    required String placeholder,
    required List<_CalculatedItem> calculatedItems,
    required IconData icon,
    required Color iconColor,
    required bool showAdvanced,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 48, color: iconColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '$prefix ',
                      prefixStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      hintText: placeholder,
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: iconColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    ),
                    onChanged: onChanged,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Calculated Values
          Text(
            'Calculated Values',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          
          ...calculatedItems.map((item) => _buildCalculatedCard(item)),
          
          // Advanced Settings (only on Yearly tab)
          if (showAdvanced) ...[
            const SizedBox(height: 20),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: const Icon(Icons.settings_suggest, color: Colors.deepPurple),
                  title: const Text(
                    'Advanced Settings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Customize work hours and weeks'),
                  initiallyExpanded: _showAdvancedSettings,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _showAdvancedSettings = expanded;
                    });
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'These settings affect hourly rate calculations',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _hoursPerWeekController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Hours per Week',
                                    prefixIcon: const Icon(Icons.schedule),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _weeksPerYearController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Weeks per Year',
                                    prefixIcon: const Icon(Icons.calendar_today),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calculate, size: 16, color: Colors.deepPurple),
                                const SizedBox(width: 8),
                                Text(
                                  'Total: ${_hoursPerYear.toStringAsFixed(0)} hours/year',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _updateWorkParameters,
                            icon: const Icon(Icons.check),
                            label: const Text('Apply Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Currency Customization Section
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: const Icon(Icons.attach_money, color: Colors.teal),
                title: const Text(
                  'Currency Symbol',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Current: $_selectedCurrency'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.teal.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Choose a currency symbol to display throughout the app',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.teal.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Common currencies grid
                        const Text(
                          'Common Currencies',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _commonCurrencies.map((currency) {
                            final isSelected = !_useCustomCurrency && _selectedCurrency == currency;
                            return ChoiceChip(
                              label: Text(
                                currency,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: Colors.teal.shade200,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _useCustomCurrency = false;
                                    _selectedCurrency = currency;
                                  });
                                  _saveCurrencySettings();
                                }
                              },
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),
                        
                        // Custom currency option
                        Row(
                          children: [
                            Checkbox(
                              value: _useCustomCurrency,
                              activeColor: Colors.teal,
                              onChanged: (value) {
                                setState(() {
                                  _useCustomCurrency = value ?? false;
                                  if (_useCustomCurrency && _customCurrencyController.text.isNotEmpty) {
                                    _selectedCurrency = _customCurrencyController.text;
                                  }
                                });
                                _saveCurrencySettings();
                              },
                            ),
                            const Text(
                              'Use custom currency symbol',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        TextField(
                          controller: _customCurrencyController,
                          enabled: _useCustomCurrency,
                          maxLength: 3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Custom Symbol',
                            hintText: 'e.g., \$, €, £',
                            prefixIcon: const Icon(Icons.edit),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: _useCustomCurrency ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surfaceContainer,
                            counterText: '',
                          ),
                          onChanged: (value) {
                            if (_useCustomCurrency && value.isNotEmpty) {
                              setState(() {
                                _selectedCurrency = value;
                              });
                              _saveCurrencySettings();
                            }
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Preview
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Preview: ',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                '${_useCustomCurrency && _customCurrencyController.text.isNotEmpty ? _customCurrencyController.text : _selectedCurrency}100.00',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Theme Settings Section
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Icon(Icons.palette, color: Theme.of(context).colorScheme.primary),
                title: const Text(
                  'Theme Settings',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('$_themeMode • ${_themeColor[0].toUpperCase()}${_themeColor.substring(1)}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Customize the app appearance',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Theme Mode Selection
                        const Text(
                          'Theme Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _themeModes.entries.map((entry) {
                            final isSelected = _themeMode == entry.key;
                            IconData icon;
                            switch (entry.key) {
                              case 'system':
                                icon = Icons.brightness_auto;
                                break;
                              case 'light':
                                icon = Icons.light_mode;
                                break;
                              case 'dark':
                                icon = Icons.dark_mode;
                                break;
                              default:
                                icon = Icons.brightness_auto;
                            }
                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 16),
                                  const SizedBox(width: 6),
                                  Text(entry.value),
                                ],
                              ),
                              selected: isSelected,
                              selectedColor: Theme.of(context).colorScheme.primaryContainer,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _themeMode = entry.key;
                                  });
                                  _saveThemeSettings();
                                }
                              },
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),
                        
                        // Theme Color Selection
                        const Text(
                          'Theme Color',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _themeColors.entries.map((entry) {
                            final isSelected = _themeColor == entry.key;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _themeColor = entry.key;
                                });
                                _saveThemeSettings();
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: entry.value,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? entry.value : Colors.grey.shade300,
                                    width: isSelected ? 4 : 2,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: entry.value.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ] : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 32)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Color labels
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: _themeColors.keys.map((colorName) {
                            return SizedBox(
                              width: 60,
                              child: Text(
                                colorName[0].toUpperCase() + colorName.substring(1),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: _themeColor == colorName ? FontWeight.bold : FontWeight.normal,
                                  color: _themeColor == colorName ? _themeColors[colorName] : Colors.grey.shade600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Auto-save info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.secondaryContainer],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_done, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All changes are saved automatically',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatedCard(_CalculatedItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: item.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalculatedItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _CalculatedItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
