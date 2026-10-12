import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/common.dart';
import '../../state/settings.dart';

class _Page {
  const _Page({
    required this.background,
    required this.before,
    required this.after,
    required this.body,
    required this.art,
  });

  final Color background;

  /// Headline text before and after the inline arrow pill.
  final String before;
  final String after;
  final String body;
  final Widget art;
}

const _ink = inkOnHighlight;

/// Three full-colour welcome pages shown on first launch.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  final _name = TextEditingController();
  int _index = 0;

  late final List<_Page> _pages = [
    const _Page(
      background: Color(0xFFC5F26B),
      before: 'Plan events\nmade for',
      after: '\nevery budget',
      body: 'Budgets, payments, tasks, guests and vendors, all in one calm place.',
      art: _PlanArt(),
    ),
    const _Page(
      background: Color(0xFFB8B5FA),
      before: 'Every birr\n',
      after: ' in its\nright place',
      body: 'Split your budget, log expenses, pay in instalments and never miss a due date.',
      art: _MoneyArt(),
    ),
    const _Page(
      background: Color(0xFFFF9E8F),
      before: 'Bring your\npeople',
      after: '\ntogether',
      body: 'Track RSVPs, plus-ones and vendors, and keep every note in one place.',
      art: _PeopleArt(),
    ),
  ];

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final settings = ref.read(settingsProvider.notifier);
    if (_name.text.trim().isNotEmpty) await settings.setName(_name.text);
    await settings.setOnboarded(true);
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final page =
              _controller.hasClients && _controller.position.haveDimensions
              ? _controller.page ?? 0
              : _index.toDouble();
          final i = page.floor().clamp(0, _pages.length - 1);
          final j = (i + 1).clamp(0, _pages.length - 1);
          final bg = Color.lerp(
            _pages[i].background,
            _pages[j].background,
            page - i,
          )!;
          return Scaffold(backgroundColor: bg, body: child);
        },
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.donut_large_rounded,
                      color: _ink,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Event Budget',
                      style: text.titleMedium?.copyWith(color: _ink),
                    ),
                    const Spacer(),
                    for (var k = 0; k < _pages.length; k++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(left: 5),
                        width: k == _index ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: k == _index
                              ? _ink
                              : _ink.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _index = i);
                  },
                  itemBuilder: (context, i) => _PageBody(
                    page: _pages[i],
                    footer: i == _pages.length - 1
                        ? _NameField(controller: _name)
                        : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  children: [
                    if (!_isLast)
                      TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(foregroundColor: _ink),
                        child: const Text('Skip'),
                      ),
                    const Spacer(),
                    Pressable(
                      onTap: _next,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        height: 64,
                        padding: EdgeInsets.only(
                          left: _isLast ? 24 : 0,
                          right: 0,
                        ),
                        decoration: BoxDecoration(
                          color: _ink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLast)
                              Text(
                                'Let’s start',
                                style: text.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: Icon(
                                _isLast
                                    ? Icons.arrow_forward_rounded
                                    : Icons.north_east_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
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
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.page, this.footer});

  final _Page page;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final headline = context.text.displayMedium?.copyWith(
      color: _ink,
      height: 1.12,
    );
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: page.art,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: page.before),
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: _ArrowPill(),
                            ),
                            TextSpan(text: page.after),
                          ],
                        ),
                        style: headline,
                      )
                      .animate()
                      .fadeIn(duration: 450.ms)
                      .slideY(begin: 0.15, curve: Curves.easeOutCubic),
                  const SizedBox(height: 16),
                  Text(
                    page.body,
                    style: context.text.bodyLarge?.copyWith(
                      color: _ink.withValues(alpha: 0.7),
                    ),
                  ).animate().fadeIn(delay: 120.ms, duration: 450.ms),
                  if (footer != null) ...[const SizedBox(height: 20), footer!],
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowPill extends StatelessWidget {
  const _ArrowPill();

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.only(left: 10, top: 4),
          width: 76,
          height: 40,
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .slideX(
          begin: -0.06,
          end: 0.06,
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      style: context.text.bodyLarge?.copyWith(color: _ink),
      decoration: InputDecoration(
        hintText: 'Your first name (optional)',
        hintStyle: TextStyle(color: _ink.withValues(alpha: 0.5)),
        fillColor: Colors.white.withValues(alpha: 0.55),
        prefixIcon: const Icon(Icons.waving_hand_outlined, color: _ink),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: _ink, width: 1.6),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

/// A line-art bubble with an icon, floating gently.
class _Bubble extends StatelessWidget {
  const _Bubble(
    this.icon, {
    this.size = 52,
    this.filled = false,
    this.delay = 0,
  });

  /// Shows the currency symbol (e.g. "Br") instead of an icon.
  const _Bubble.currency({this.size = 52, this.delay = 0})
    : icon = null,
      filled = false;

  final IconData? icon;
  final double size;
  final bool filled;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: filled ? _ink : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _ink, width: 2),
          ),
          child: icon == null
              ? Center(
                  child: CurrencyIcon(size: size * 0.56, color: _ink),
                )
              : Icon(
                  icon,
                  color: filled ? Colors.white : _ink,
                  size: size * 0.46,
                ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(
          begin: -4,
          end: 4,
          delay: delay.ms,
          duration: 1600.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _ArtFrame extends StatelessWidget {
  const _ArtFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
          ),
          ...children,
        ],
      ),
    ).animate().scale(
      begin: const Offset(0.9, 0.9),
      duration: 600.ms,
      curve: Curves.easeOutBack,
    );
  }
}

class _PlanArt extends StatelessWidget {
  const _PlanArt();

  @override
  Widget build(BuildContext context) {
    return const _ArtFrame(
      children: [
        _Bubble(Icons.celebration_rounded, size: 112, filled: true),
        Positioned(
          left: 10,
          top: 18,
          child: _Bubble(Icons.event_rounded, delay: 200),
        ),
        Positioned(
          right: 14,
          top: 4,
          child: _Bubble(Icons.account_balance_wallet_outlined, delay: 500),
        ),
        Positioned(
          left: 30,
          bottom: 12,
          child: _Bubble(Icons.checklist_rounded, size: 46, delay: 800),
        ),
        Positioned(
          right: 26,
          bottom: 24,
          child: _Bubble.currency(size: 44, delay: 300),
        ),
      ],
    );
  }
}

class _MoneyArt extends ConsumerWidget {
  const _MoneyArt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ArtFrame(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const DonutChart(
            size: 124,
            strokeWidth: 20,
            slices: [
              DonutSlice(value: 40, color: _ink),
              DonutSlice(value: 25, color: Color(0xFFC5F26B)),
              DonutSlice(value: 20, color: Color(0xFFFF9E8F)),
              DonutSlice(value: 15, color: Color(0xFF8FD3FF)),
            ],
          ),
        ),
        Positioned(
          right: 0,
          top: 26,
          child:
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      ref.watch(moneyProvider).short(25000),
                      style: context.text.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                    begin: -4,
                    end: 4,
                    duration: 1500.ms,
                    curve: Curves.easeInOut,
                  ),
        ),
        const Positioned(
          left: 8,
          bottom: 26,
          child: _Bubble(Icons.receipt_long_rounded, delay: 400),
        ),
      ],
    );
  }
}

class _PeopleArt extends StatelessWidget {
  const _PeopleArt();

  @override
  Widget build(BuildContext context) {
    const names = ['Hanna', 'Michael', 'Ruth', 'Emma'];
    return _ArtFrame(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < names.length; i++)
              Align(
                widthFactor: 0.72,
                child:
                    InitialsAvatar(
                      name: names[i],
                      size: 70,
                      ring: Colors.white,
                    ).animate().scale(
                      delay: (120 * i).ms,
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
              ),
          ],
        ),
        Positioned(
          right: 6,
          top: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: _ink),
                const SizedBox(width: 6),
                Text(
                  '42 attending',
                  style: context.text.labelMedium?.copyWith(color: _ink),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          left: 14,
          bottom: 22,
          child: _Bubble(Icons.storefront_outlined, delay: 300),
        ),
      ],
    );
  }
}
