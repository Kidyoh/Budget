import '../core/id.dart';
import '../core/palette.dart';
import 'models/models.dart';

/// One suggested line of a starting budget, as a share of the total.
class TemplateLine {
  const TemplateLine(this.name, this.iconKey, this.share);

  final String name;
  final String iconKey;

  /// Fraction of the total budget, between 0 and 1.
  final double share;
}

/// Suggested starting splits per event type. Each list sums to 1.
const Map<EventType, List<TemplateLine>> budgetTemplates = {
  EventType.wedding: [
    TemplateLine('Venue', 'venue', 0.25),
    TemplateLine('Catering', 'catering', 0.25),
    TemplateLine('Photography & video', 'photo', 0.10),
    TemplateLine('Attire & beauty', 'attire', 0.09),
    TemplateLine('Decor & flowers', 'decor', 0.09),
    TemplateLine('Music & entertainment', 'music', 0.07),
    TemplateLine('Cake & drinks', 'drinks', 0.05),
    TemplateLine('Stationery', 'stationery', 0.02),
    TemplateLine('Transport', 'transport', 0.03),
    TemplateLine('Contingency', 'misc', 0.05),
  ],
  EventType.birthday: [
    TemplateLine('Venue', 'venue', 0.25),
    TemplateLine('Food', 'catering', 0.30),
    TemplateLine('Cake & drinks', 'cake', 0.15),
    TemplateLine('Decorations', 'decor', 0.10),
    TemplateLine('Entertainment', 'entertainment', 0.10),
    TemplateLine('Party favours', 'gifts', 0.05),
    TemplateLine('Contingency', 'misc', 0.05),
  ],
  EventType.conference: [
    TemplateLine('Venue', 'venue', 0.30),
    TemplateLine('Catering', 'catering', 0.20),
    TemplateLine('Audio & visual', 'av', 0.12),
    TemplateLine('Speakers', 'staff', 0.10),
    TemplateLine('Marketing', 'marketing', 0.10),
    TemplateLine('Printing & badges', 'stationery', 0.05),
    TemplateLine('Travel & lodging', 'lodging', 0.08),
    TemplateLine('Contingency', 'misc', 0.05),
  ],
  EventType.corporate: [
    TemplateLine('Venue', 'venue', 0.30),
    TemplateLine('Catering', 'catering', 0.30),
    TemplateLine('Audio & visual', 'av', 0.10),
    TemplateLine('Entertainment', 'entertainment', 0.10),
    TemplateLine('Decor & branding', 'decor', 0.10),
    TemplateLine('Transport', 'transport', 0.05),
    TemplateLine('Contingency', 'misc', 0.05),
  ],
  EventType.party: [
    TemplateLine('Venue', 'venue', 0.25),
    TemplateLine('Food', 'catering', 0.30),
    TemplateLine('Drinks', 'drinks', 0.20),
    TemplateLine('Music & DJ', 'music', 0.10),
    TemplateLine('Decorations', 'decor', 0.10),
    TemplateLine('Contingency', 'misc', 0.05),
  ],
  EventType.festival: [
    TemplateLine('Site & rentals', 'rentals', 0.25),
    TemplateLine('Artists & performers', 'entertainment', 0.25),
    TemplateLine('Stage, sound & light', 'av', 0.15),
    TemplateLine('Security & staff', 'security', 0.10),
    TemplateLine('Marketing', 'marketing', 0.10),
    TemplateLine('Permits & insurance', 'stationery', 0.05),
    TemplateLine('Contingency', 'misc', 0.10),
  ],
  EventType.other: [
    TemplateLine('Venue', 'venue', 0.35),
    TemplateLine('Food & drinks', 'catering', 0.35),
    TemplateLine('Decor', 'decor', 0.10),
    TemplateLine('Entertainment', 'entertainment', 0.10),
    TemplateLine('Contingency', 'misc', 0.10),
  ],
};

/// Builds categories for [eventId] from the template for [type], splitting
/// [totalBudget] by each line's share and rounding to whole units. Any
/// rounding difference goes to the last line so the allocations add up.
List<BudgetCategory> categoriesFromTemplate({
  required String eventId,
  required EventType type,
  required double totalBudget,
  int startSortOrder = 0,
}) {
  final lines = budgetTemplates[type] ?? budgetTemplates[EventType.other]!;
  final amounts = [
    for (final l in lines) (totalBudget * l.share).roundToDouble(),
  ];
  if (amounts.isNotEmpty) {
    final diff = totalBudget - amounts.fold<double>(0, (a, b) => a + b);
    amounts[amounts.length - 1] += diff;
  }
  return [
    for (var i = 0; i < lines.length; i++)
      BudgetCategory(
        id: newId(),
        eventId: eventId,
        name: lines[i].name,
        iconKey: lines[i].iconKey,
        colorValue: paletteColor(i),
        allocated: amounts[i],
        sortOrder: startSortOrder + i,
      ),
  ];
}
