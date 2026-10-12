class BudgetCategory {
  const BudgetCategory({
    required this.id,
    required this.eventId,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.allocated,
    this.sortOrder = 0,
  });

  final String id;
  final String eventId;
  final String name;
  final String iconKey;
  final int colorValue;
  final double allocated;
  final int sortOrder;

  Map<String, Object?> toMap() => {
    'id': id,
    'event_id': eventId,
    'name': name,
    'icon': iconKey,
    'color': colorValue,
    'allocated': allocated,
    'sort_order': sortOrder,
  };

  factory BudgetCategory.fromMap(Map<String, Object?> map) => BudgetCategory(
    id: map['id'] as String,
    eventId: map['event_id'] as String,
    name: map['name'] as String,
    iconKey: map['icon'] as String? ?? 'misc',
    colorValue: map['color'] as int,
    allocated: (map['allocated'] as num).toDouble(),
    sortOrder: map['sort_order'] as int? ?? 0,
  );
}

/// A category with the sums of the expenses filed under it.
class CategoryWithSpend {
  const CategoryWithSpend({
    required this.category,
    required this.committed,
    required this.paid,
    required this.expenseCount,
  });

  final BudgetCategory category;
  final double committed;
  final double paid;
  final int expenseCount;

  double get remaining => category.allocated - committed;
  bool get isOverBudget => committed > category.allocated + 0.005;

  double get usedFraction => category.allocated <= 0
      ? (committed > 0 ? 1 : 0)
      : committed / category.allocated;
}
