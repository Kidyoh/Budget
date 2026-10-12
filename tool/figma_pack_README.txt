EVENT BUDGET — FIGMA IMPORT PACK
================================

What's inside
-------------
screens/light/        21 screens in light mode, 1080 x 2340 (phone at 3x)
screens/dark/         The same 21 screens in dark mode
screens/full-length/  Home, Event overview and Budget as full scrolling pages
boards/               Every screen on one image (light and dark) for quick sharing
brand/                App icon, logo mark and the Birr icon (SVG = editable vectors)
style guide/          Colour palette, type scale and shapes (PNG) + design-tokens.json
fonts/                Plus Jakarta Sans (install these before editing text in Figma)

Import into Figma (about 2 minutes)
-----------------------------------
1. Install the fonts in the "fonts" folder on your computer (double-click each
   .ttf -> Install), so Figma can use Plus Jakarta Sans.
2. In Figma, create a new design file (e.g. "Event Budget – App design").
3. Add three pages with the "+" next to Pages: "Light", "Dark", "Brand & styles".
4. On the "Light" page: select every file in screens/light and drag them onto
   the canvas. Figma places each image; select all and press
   Ctrl/Cmd + Alt + G (Frame selection) or use "Tidy up" to line them up.
   Tip: set each image to 360 x 780 so it matches a phone frame at 1x.
5. Repeat for the "Dark" page with screens/dark.
6. On "Brand & styles": drag in the SVG files from brand/ (they import as
   editable vector layers) and the style guide PNG.
7. Share: click "Share" (top right) -> "Copy link", or invite people by email.
   Choose "can view" for feedback, or "can edit" for collaborators.

Notes
-----
- Screens are pixel-exact renders of the real app, imported as images. The
  logo, app icon and Birr icon are true vectors you can edit.
- The colour hex codes and text sizes in the style guide and
  design-tokens.json match the app's code exactly.
- To rebuild this whole pack after app changes, run from the project:
    python3 tool/build_figma_pack.py out/figma
