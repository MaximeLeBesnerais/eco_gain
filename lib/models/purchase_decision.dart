class PurchaseDecision {
  final int? id;
  final double price;
  final double workHours;
  final String decision; // 'buy', 'dont_buy', 'think_about_it'
  final DateTime timestamp;
  final double hourlyRate;
  final double yearlySalary;
  final double monthlySalary;
  final double hoursPerWeek;
  final double weeksPerYear;

  PurchaseDecision({
    this.id,
    required this.price,
    required this.workHours,
    required this.decision,
    required this.timestamp,
    required this.hourlyRate,
    required this.yearlySalary,
    required this.monthlySalary,
    this.hoursPerWeek = 40.0,
    this.weeksPerYear = 52.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'price': price,
      'work_hours': workHours,
      'decision': decision,
      'timestamp': timestamp.toIso8601String(),
      'hourly_rate': hourlyRate,
      'yearly_salary': yearlySalary,
      'monthly_salary': monthlySalary,
      'hours_per_week': hoursPerWeek,
      'weeks_per_year': weeksPerYear,
    };
  }

  factory PurchaseDecision.fromMap(Map<String, dynamic> map) {
    return PurchaseDecision(
      id: map['id'],
      price: map['price'],
      workHours: map['work_hours'],
      decision: map['decision'],
      timestamp: DateTime.parse(map['timestamp']),
      hourlyRate: map['hourly_rate'],
      yearlySalary: map['yearly_salary'],
      monthlySalary: map['monthly_salary'],
      hoursPerWeek: map['hours_per_week'] ?? 40.0,
      weeksPerYear: map['weeks_per_year'] ?? 52.0,
    );
  }
}
