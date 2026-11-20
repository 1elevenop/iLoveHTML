import 'package:flutter/material.dart';

import 'theme.dart';

/// Thick-stroked box with a hard offset shadow; tappable when [onTap] is set.
/// Pressing (or Enter/Space on keyboard focus) pushes it into its shadow.
class BrutalCard extends StatefulWidget {
  const BrutalCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.shadow = true,
    this.borderRadius,
    this.semanticLabel,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool shadow;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  @override
  State<BrutalCard> createState() => _BrutalCardState();
}

class _BrutalCardState extends State<BrutalCard> {
  var _pressed = false;
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final e = context.eleven;
    final radius = widget.borderRadius ?? BorderRadius.circular(Eleven.radius);
    final down = _pressed && widget.onTap != null;
    final duration = MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 80);
    final box = AnimatedContainer(
      duration: duration,
      transform: Matrix4.translationValues(down ? Eleven.shadowOffset.dx : 0, down ? Eleven.shadowOffset.dy : 0, 0),
      decoration: BoxDecoration(
        color: widget.color ?? e.panel,
        borderRadius: radius,
        border: Border.all(color: e.ink, width: _focused ? Eleven.stroke + 1.5 : Eleven.stroke),
        boxShadow: widget.shadow && !down ? e.shadow : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          onFocusChange: (v) => setState(() => _focused = v),
          splashFactory: NoSplash.splashFactory,
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
    // Leave room for the shadow so neighbours don't overlap it.
    final padded = Padding(
      padding: EdgeInsets.only(
        right: widget.shadow ? Eleven.shadowOffset.dx : 0,
        bottom: widget.shadow ? Eleven.shadowOffset.dy : 0,
      ),
      child: box,
    );
    return widget.semanticLabel == null
        ? padded
        : Semantics(button: widget.onTap != null, label: widget.semanticLabel, child: padded);
  }
}

/// Main action button: a colour block with a hard shadow that collapses on press.
class BrutalButton extends StatelessWidget {
  const BrutalButton({super.key, required this.label, this.icon, this.onPressed, this.color, this.expand = false});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final e = context.eleven;
    final enabled = onPressed != null;
    final bg = enabled ? (color ?? e.block) : e.line;
    final fg = enabled ? (bg.computeLuminance() > 0.35 ? Colors.black : Colors.white) : e.mute;
    final text = Theme.of(context).textTheme.labelLarge?.copyWith(color: fg);
    return Semantics(
      button: true,
      enabled: enabled,
      child: BrutalCard(
        color: bg,
        shadow: enabled,
        onTap: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(width: 8)],
            Flexible(
              child: Text(label, style: text, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square colour block holding an icon, as on the project cards.
class BrutalIconTile extends StatelessWidget {
  const BrutalIconTile({super.key, required this.icon, required this.color, this.size = 44});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final e = context.eleven;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Eleven.radius - 2),
        border: Border.all(color: e.ink, width: 2),
      ),
      child: Icon(icon, size: size * 0.5, color: color.computeLuminance() > 0.35 ? Colors.black : Colors.white),
    );
  }
}

/// A card with a folder tab on top-left, holding [tab] (e.g. a label or a count).
class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.child,
    this.tab,
    this.tabColor,
    this.color,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final Widget? tab;
  final Color? tabColor;
  final Color? color;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final e = context.eleven;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 12),
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
          constraints: const BoxConstraints(minWidth: 56, minHeight: 22),
          decoration: BoxDecoration(
            color: tabColor ?? e.block,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Eleven.radius - 2)),
            border: Border(top: e.strokeSide, left: e.strokeSide, right: e.strokeSide),
          ),
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black),
            child: tab ?? const SizedBox.shrink(),
          ),
        ),
        Flexible(
          child: BrutalCard(
            color: color,
            onTap: onTap,
            semanticLabel: semanticLabel,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(Eleven.radius),
              bottomLeft: Radius.circular(Eleven.radius),
              bottomRight: Radius.circular(Eleven.radius),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Segmented progress bar with a tappable chip per step. Steps can be visited
/// in any order; [flagged] marks the ones holding a field with an error.
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.labels,
    required this.current,
    required this.onSelect,
    this.flagged = const {},
  });

  final List<String> labels;
  final int current;
  final ValueChanged<int> onSelect;

  /// Steps that hold a field with a validation error.
  final Set<int> flagged;

  @override
  Widget build(BuildContext context) {
    final e = context.eleven;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: e.panel,
            borderRadius: BorderRadius.circular(Eleven.radius),
            border: Border.all(color: e.ink, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Eleven.radius - 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  if (i > 0) Container(width: 2, color: e.ink),
                  Expanded(child: ColoredBox(color: i <= current ? brutalBlocks[i % brutalBlocks.length] : e.panel)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < labels.length; i++)
              Semantics(
                selected: i == current,
                button: true,
                label: '${i + 1}. ${labels[i]}',
                excludeSemantics: true,
                child: BrutalCard(
                  shadow: i == current,
                  color: i == current ? brutalBlocks[i % brutalBlocks.length] : e.panel,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onTap: () => onSelect(i),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${i + 1}',
                        style: monoStyle(
                          context,
                          size: 13,
                        ).copyWith(fontWeight: FontWeight.w700, color: i == current ? Colors.black : e.fg),
                      ),
                      const SizedBox(width: 8),
                      Text(labels[i], style: t.labelMedium?.copyWith(color: i == current ? Colors.black : e.fg)),
                      if (flagged.contains(i)) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.error, size: 16, color: i == current ? Colors.black : e.fg),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The "iLoveHTML" wordmark: "iLove" in ink, "HTML" on a colour block.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    final e = context.eleven;
    final style = TextStyle(
      fontFamily: Eleven.font,
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -size * 0.03,
      height: 1.1,
    );
    return Semantics(
      label: 'iLoveHTML',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(size: size * 1.5),
          SizedBox(width: size * 0.35),
          Text('iLove', style: style.copyWith(color: e.fg)),
          const SizedBox(width: 3),
          Container(
            padding: EdgeInsets.symmetric(horizontal: size * 0.2, vertical: size * 0.04),
            decoration: BoxDecoration(
              color: e.block,
              borderRadius: BorderRadius.circular(size * 0.18),
              border: Border.all(color: e.ink, width: 2),
              boxShadow: [BoxShadow(color: e.ink, offset: const Offset(2, 2))],
            ),
            child: Text('HTML', style: style.copyWith(color: e.onBlock)),
          ),
        ],
      ),
    );
  }
}

/// The iLoveHTML mark (heart with </> on a yellow tile). Dark mode uses the
/// variant with a white outline and shadow so the tile stays visible.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    Theme.of(context).brightness == Brightness.dark ? 'assets/brand/mark-on-dark.png' : 'assets/brand/mark.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    excludeFromSemantics: true,
  );
}
