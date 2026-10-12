/// Colours offered for events, categories and notes, stored as ARGB ints.
library;

/// Highlight colours for the app accent. All are light enough to carry ink
/// text, which the whole design relies on.
const List<int> highlightPalette = [
  0xFFC5F26B, // lime
  0xFFB8B5FA, // lavender
  0xFFFF8E7F, // coral
  0xFF8FD3FF, // sky
  0xFFFFE07A, // butter
  0xFF8EEBC4, // mint
];

const int defaultHighlight = 0xFFC5F26B;

/// Colours for events and budget categories: the highlight family plus a
/// few calmer tones and ink, so charts and cards read as one set.
const List<int> accentPalette = [
  0xFFC5F26B, // lime
  0xFF1C1C1E, // ink
  0xFFB8B5FA, // lavender
  0xFFFF8E7F, // coral
  0xFF8FD3FF, // sky
  0xFFFFE07A, // butter
  0xFF8EEBC4, // mint
  0xFFFFC29E, // peach
  0xFFF6A8CF, // rose
  0xFF9AA5B8, // slate
];

/// Paper tints for note cards.
const List<int> notePalette = [
  0xFFE9F9C4,
  0xFFE3E2FD,
  0xFFFFDCD6,
  0xFFD6EFFF,
  0xFFFFF3C4,
  0xFFD4F7E8,
];

int paletteColor(int index) => accentPalette[index % accentPalette.length];
