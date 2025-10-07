import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_helper.dart';
import '../utils/currency_helper.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final Function(String color, String mode) onThemeChange;

  const OnboardingScreen({
    super.key, 
    required this.onComplete,
    required this.onThemeChange,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Salary settings
  int _selectedTab = 0; // 0: Yearly, 1: Monthly, 2: Hourly
  final TextEditingController _yearlySalaryController = TextEditingController();
  final TextEditingController _monthlySalaryController = TextEditingController();
  final TextEditingController _hourlySalaryController = TextEditingController();

  // Advanced settings
  final TextEditingController _hoursPerWeekController = TextEditingController(text: '40');
  final TextEditingController _weeksPerYearController = TextEditingController(text: '52');

  // Theme settings
  String _themeMode = 'system';
  String _themeColor = 'blue';

  // Currency settings
  bool _useCustomCurrency = false;
  String _selectedCurrency = '\$';
  final TextEditingController _customCurrencyController = TextEditingController();

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
    // Add listeners to update the preview in real-time
    _hoursPerWeekController.addListener(() => setState(() {}));
    _weeksPerYearController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _yearlySalaryController.dispose();
    _monthlySalaryController.dispose();
    _hourlySalaryController.dispose();
    _hoursPerWeekController.dispose();
    _weeksPerYearController.dispose();
    _customCurrencyController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Validate salary input - default to 0 if empty
    double hourlyRate = 0;
    double yearlySalary = 0;
    double monthlySalary = 0;

    if (_selectedTab == 0) {
      // Yearly
      yearlySalary = double.tryParse(_yearlySalaryController.text) ?? 0;
    } else if (_selectedTab == 1) {
      // Monthly
      monthlySalary = double.tryParse(_monthlySalaryController.text) ?? 0;
    } else {
      // Hourly
      hourlyRate = double.tryParse(_hourlySalaryController.text) ?? 0;
    }

    final prefs = await SharedPreferences.getInstance();

    // Calculate and save salary
    final hoursPerWeek = double.tryParse(_hoursPerWeekController.text) ?? 40.0;
    final weeksPerYear = double.tryParse(_weeksPerYearController.text) ?? 52.0;
    final totalHoursPerYear = hoursPerWeek * weeksPerYear;

    if (_selectedTab == 0) {
      // From yearly
      hourlyRate = totalHoursPerYear > 0 ? yearlySalary / totalHoursPerYear : 0;
      monthlySalary = yearlySalary / 12;
    } else if (_selectedTab == 1) {
      // From monthly
      yearlySalary = monthlySalary * 12;
      hourlyRate = totalHoursPerYear > 0 ? yearlySalary / totalHoursPerYear : 0;
    } else {
      // From hourly
      yearlySalary = hourlyRate * totalHoursPerYear;
      monthlySalary = yearlySalary / 12;
    }

    await prefs.setDouble('hourly_rate', hourlyRate);
    await prefs.setDouble('yearly_salary', yearlySalary);
    await prefs.setDouble('monthly_salary', monthlySalary);
    await prefs.setDouble('hours_per_week', hoursPerWeek);
    await prefs.setDouble('weeks_per_year', weeksPerYear);

    // Save theme settings
    ThemeMode themeMode;
    switch (_themeMode) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
        break;
    }
    await ThemeHelper.saveThemeMode(themeMode);
    await ThemeHelper.saveThemeColor(_themeColor);

    // Save currency settings
    final currency = _useCustomCurrency ? _customCurrencyController.text : _selectedCurrency;
    await CurrencyHelper.saveCurrencySymbol(currency, _useCustomCurrency);

    // Mark onboarding as complete
    await prefs.setBool('done_onboarding', true);

    // Complete onboarding
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildSalaryPage(),
                  _buildThemePage(),
                  _buildCurrencyPage(),
                  _buildAdvancedPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 80),
                  
                  ElevatedButton(
                    onPressed: _currentPage == 4 ? _completeOnboarding : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_currentPage == 4 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.savings_outlined,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to Eco Gain',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Make smarter purchasing decisions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildFeatureCard(
            Icons.access_time,
            'Real Work Value',
            'See how many hours you need to work to afford something',
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            Icons.trending_up,
            'Track Your Savings',
            'Monitor how much time and money you save by making smart choices',
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            Icons.lightbulb_outline,
            'Better Decisions',
            'Understand the true cost of purchases in terms of your time',
          ),
          const SizedBox(height: 32),
          Text(
            'Let\'s get started by setting up your profile',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'What\'s your salary?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This helps calculate how many work hours each purchase costs you',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          // Salary type tabs
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              children: [
                _buildTabButton(0, 'Yearly', Icons.calendar_today),
                _buildTabButton(1, 'Monthly', Icons.calendar_month),
                _buildTabButton(2, 'Hourly', Icons.schedule),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Salary input
          if (_selectedTab == 0)
            _buildSalaryInput(
              controller: _yearlySalaryController,
              label: 'Yearly Salary',
              icon: Icons.attach_money,
              hint: 'e.g., 60000',
            )
          else if (_selectedTab == 1)
            _buildSalaryInput(
              controller: _monthlySalaryController,
              label: 'Monthly Salary',
              icon: Icons.attach_money,
              hint: 'e.g., 5000',
            )
          else
            _buildSalaryInput(
              controller: _hourlySalaryController,
              label: 'Hourly Rate',
              icon: Icons.attach_money,
              hint: 'e.g., 30',
            ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalaryInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Choose your theme',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Personalize the app\'s appearance to your liking',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Theme mode
          Text(
            'Theme Mode',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _themeModes.entries.map((entry) {
              final isSelected = _themeMode == entry.key;
              IconData icon;
              if (entry.key == 'system') {
                icon = Icons.brightness_auto;
              } else if (entry.key == 'light') {
                icon = Icons.light_mode;
              } else {
                icon = Icons.dark_mode;
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
                    // Immediately update theme
                    widget.onThemeChange(_themeColor, _themeMode);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Theme color
          Text(
            'Theme Color',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _themeColors.entries.map((entry) {
              final isSelected = _themeColor == entry.key;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _themeColor = entry.key;
                  });
                  // Immediately update theme
                  widget.onThemeChange(_themeColor, _themeMode);
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                      width: 4,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: entry.value.withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 32,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Choose your currency',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select the currency symbol you want to use throughout the app',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Preset currencies
          Text(
            'Common Currencies',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ['\$', '€', '£', '¥', '₹', 'CHF', 'R\$'].map((currency) {
              final isSelected = !_useCustomCurrency && _selectedCurrency == currency;
              return ChoiceChip(
                label: Text(
                  currency,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Custom currency
          Text(
            'Or Use Custom Symbol',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _useCustomCurrency,
                onChanged: (value) {
                  setState(() {
                    _useCustomCurrency = value ?? false;
                  });
                },
              ),
              const SizedBox(width: 8),
              const Text('Use custom currency symbol'),
            ],
          ),
          if (_useCustomCurrency) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customCurrencyController,
              maxLength: 5,
              decoration: InputDecoration(
                labelText: 'Custom Symbol',
                hintText: 'e.g., \$, €, £',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                counterText: '',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Work parameters',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Fine-tune your work schedule for accurate calculations',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'These settings help calculate your hourly rate accurately based on your actual working hours',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Work hours inputs
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hours per Week',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _hoursPerWeekController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.schedule),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weeks per Year',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _weeksPerYearController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Calculation preview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calculate,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Calculation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Total annual work hours: ${(double.tryParse(_hoursPerWeekController.text) ?? 40) * (double.tryParse(_weeksPerYearController.text) ?? 52)} hours',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is used to calculate your hourly rate from yearly/monthly salary',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
