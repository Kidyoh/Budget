/// Colours offered for events, categories and notes, stored as ARGB ints.
library;

const List<int> accentPalette = [
  0xFF6750A4, // violet
  0xFF0B57D0, // blue
  0xFF00897B, // teal
  0xFF2E7D32, // green
  0xFFF9A825, // amber
  0xFFEF6C00, // orange
  0xFFD81B60, // pink
  0xFFC62828, // red
  0xFF5D4037, // brown
  0xFF455A64, // slate
];

/// Soft pastel tints for note cards (used with alpha over the surface).
const List<int> notePalette = [
  0xFFFFF59D,
  0xFFFFCC80,
  0xFFF8BBD0,
  0xFFB3E5FC,
  0xFFC8E6C9,
  0xFFD1C4E9,
];

int paletteColor(int index) => accentPalette[index % accentPalette.length];
