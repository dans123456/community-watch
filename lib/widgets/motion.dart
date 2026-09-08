// Shared, reusable motion primitives for Community Watch.
//
// Everything here is intentionally subtle: short durations, small scale
// deltas, gentle curves. The goal is an interface that feels alive and
// responsive without ever feeling flashy or bouncy.
import 'dart:math';
import 'package:flutter/material.dart';

/// Centralised timing/curve constants so every animation in the app feels
/// consistent.
class Motion {
  Motion._();
  static const fast = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 340);
  static const page = Duration(milliseconds: 260);
  static const curve = Curves.easeOutCubic;
  static const softBounce = Curves.easeOutBack;
}

// ---------------------------------------------------------------------------
// Page transitions
// ---------------------------------------------------------------------------

/// A gentle fade + slide-up transition used for every screen push in the app.
class SlideFadeRoute<T> extends PageRouteBuilder<T> {
  SlideFadeRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: Motion.page,
        reverseTransitionDuration: Motion.page,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Motion.curve,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}

Future<T?> pushAnimated<T>(BuildContext context, Widget page) {
  return Navigator.push<T>(
    context,
    SlideFadeRoute<T>(builder: (_) => page),
  );
}

Future<T?> pushReplaceAnimated<T>(BuildContext context, Widget page) {
  return Navigator.pushReplacement<T, void>(
    context,
    SlideFadeRoute<T>(builder: (_) => page),
  );
}

Future<T?> pushAndClearAnimated<T>(BuildContext context, Widget page) {
  return Navigator.pushAndRemoveUntil<T>(
    context,
    SlideFadeRoute<T>(builder: (_) => page),
    (route) => false,
  );
}

// ---------------------------------------------------------------------------
// Press helper mixin state (hover + press tracked the same way everywhere)
// ---------------------------------------------------------------------------

/// Wraps any child with a subtle press-down scale. Useful when you want the
/// press feedback but the child already draws its own ripple (e.g. a Card).
class PressableScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: Motion.fast,
        curve: Motion.curve,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cards — hover lift/scale on desktop+web, ripple + press scale on touch
// ---------------------------------------------------------------------------

class MotionCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const MotionCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.color,
    this.margin,
  });

  @override
  State<MotionCard> createState() => _MotionCardState();
}

class _MotionCardState extends State<MotionCard> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canTap = widget.onTap != null;
    final elevation = _pressed ? 0.5 : (_hovering ? 5.0 : 1.0);
    final lift = _hovering && !_pressed ? -3.0 : 0.0;
    final scale = _pressed ? 0.98 : (_hovering ? 1.015 : 1.0);

    return MouseRegion(
      cursor: canTap ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: scale,
        duration: Motion.fast,
        curve: Motion.curve,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.curve,
          margin: widget.margin,
          transform: Matrix4.translationValues(0, lift, 0),
          decoration: BoxDecoration(
            color: widget.color ?? theme.cardColor,
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovering ? 0.13 : 0.05),
                blurRadius: 4 + elevation * 3,
                offset: Offset(0, elevation),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: widget.borderRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: widget.borderRadius,
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons — one flexible widget covers filled / tonal / outlined / text
// ---------------------------------------------------------------------------

enum MotionButtonVariant { filled, tonal, outlined, text }

class MotionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final MotionButtonVariant variant;
  final bool loading;
  final bool expand;
  final Color? color;

  const MotionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = MotionButtonVariant.filled,
    this.loading = false,
    this.expand = true,
    this.color,
  });

  @override
  State<MotionButton> createState() => _MotionButtonState();
}

class _MotionButtonState extends State<MotionButton> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.onPressed != null && !widget.loading;
    final base = widget.color ?? theme.colorScheme.primary;

    Color bg;
    Color fg;
    BoxBorder? border;
    List<BoxShadow> shadow = const [];

    switch (widget.variant) {
      case MotionButtonVariant.filled:
        bg = !enabled
            ? base.withValues(alpha: 0.35)
            : (_hovering ? Color.lerp(base, Colors.black, 0.08)! : base);
        fg = theme.colorScheme.onPrimary;
        if (enabled && _hovering) {
          shadow = [
            BoxShadow(
              color: base.withValues(alpha: 0.32),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ];
        }
        break;
      case MotionButtonVariant.tonal:
        bg = !enabled
            ? base.withValues(alpha: 0.06)
            : (_hovering ? base.withValues(alpha: 0.22) : base.withValues(alpha: 0.12));
        fg = base;
        break;
      case MotionButtonVariant.outlined:
        bg = _hovering && enabled ? base.withValues(alpha: 0.06) : Colors.transparent;
        fg = base;
        border = Border.all(color: base.withValues(alpha: enabled ? 0.55 : 0.25));
        break;
      case MotionButtonVariant.text:
        bg = _hovering && enabled ? base.withValues(alpha: 0.06) : Colors.transparent;
        fg = base;
        break;
    }

    final content = widget.loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 19, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : (_hovering && enabled ? 1.015 : 1.0),
        duration: Motion.fast,
        curve: Motion.curve,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.curve,
          width: widget.expand ? double.infinity : null,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: border,
            boxShadow: shadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              splashColor: fg.withValues(alpha: 0.12),
              highlightColor: fg.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon-only button with a hover halo, gentle grow on hover and shrink on
/// press.
class MotionIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  const MotionIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
  });

  @override
  State<MotionIconButton> createState() => _MotionIconButtonState();
}

class _MotionIconButtonState extends State<MotionIconButton> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final child = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : (_hovering ? 1.1 : 1.0),
        duration: Motion.fast,
        curve: Motion.curve,
        child: Material(
          color: _hovering
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(widget.icon, color: widget.color),
            ),
          ),
        ),
      ),
    );
    return widget.tooltip != null
        ? Tooltip(message: widget.tooltip!, child: child)
        : child;
  }
}

// ---------------------------------------------------------------------------
// Entrance animation for list/grid content
// ---------------------------------------------------------------------------

/// Fades and slides its child upward into place. Pass [index] for a small,
/// staggered cascade across a list.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 45),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.normal,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Motion.curve));

  @override
  void initState() {
    super.initState();
    final delay = widget.baseDelay * widget.index.clamp(0, 10);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading placeholders
// ---------------------------------------------------------------------------

class Skeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const Skeleton({
    super.key,
    this.height = 14,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.6 + 3.2 * t, 0),
              end: Alignment(-0.6 + 3.2 * t, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton placeholder shaped like a report/incident list card.
class ReportCardSkeleton extends StatelessWidget {
  const ReportCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Skeleton(
            height: 44,
            width: 44,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: 14, width: 150),
                SizedBox(height: 8),
                Skeleton(height: 12, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder shaped like the admin stat tiles.
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Skeleton(
            height: 40,
            width: 40,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: 18, width: 40),
                SizedBox(height: 6),
                Skeleton(height: 12, width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chips
// ---------------------------------------------------------------------------

Color statusColor(String status) {
  switch (status) {
    case 'Pending':
      return const Color(0xFFB8860B);
    case 'Under Investigation':
      return const Color(0xFF2D6A8F);
    case 'Resolved':
      return const Color(0xFF2E7D32);
    case 'Rejected':
      return const Color(0xFFC62828);
    default:
      return Colors.grey.shade700;
  }
}

/// A small, color-coded status pill with a soft entrance animation.
class StatusChip extends StatelessWidget {
  final String label;
  const StatusChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(label);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.normal,
      curve: Motion.softBounce,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated "map" marker (used to represent an incident location)
// ---------------------------------------------------------------------------

class MapMarkerPulse extends StatefulWidget {
  final Color color;
  final double size;
  const MapMarkerPulse({super.key, this.color = const Color(0xFF2D6A8F), this.size = 42});

  @override
  State<MapMarkerPulse> createState() => _MapMarkerPulseState();
}

class _MapMarkerPulseState extends State<MapMarkerPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t) * 0.35,
                child: Container(
                  width: widget.size * (0.55 + t * 0.65),
                  height: widget.size * (0.55 + t * 0.65),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                  ),
                ),
              ),
              Container(
                width: widget.size * 0.55,
                height: widget.size * 0.55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification badge
// ---------------------------------------------------------------------------

class AnimatedBadge extends StatelessWidget {
  final Widget child;
  final int count;
  const AnimatedBadge({super.key, required this.child, required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -3,
          top: -3,
          child: AnimatedScale(
            scale: count > 0 ? 1 : 0,
            duration: Motion.normal,
            curve: Motion.softBounce,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shake — subtle error feedback, never aggressive
// ---------------------------------------------------------------------------

class ShakeController {
  _ShakeState? _state;
  void shake() => _state?._run();
}

class Shake extends StatefulWidget {
  final Widget child;
  final ShakeController controller;
  const Shake({super.key, required this.child, required this.controller});

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
  }

  void _run() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // A gently decaying sine wave keeps this feeling like a nudge, not a
        // jolt.
        final dx = sin(t * pi * 3) * (1 - t) * 6;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Success + confirmation dialogs — scale/fade entrance and exit
// ---------------------------------------------------------------------------

Widget _dialogShell(BuildContext context, Animation<double> animation, Widget child) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  return Opacity(
    opacity: curved.value.clamp(0.0, 1.0),
    child: Transform.scale(
      scale: 0.90 + 0.10 * curved.value,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class _SuccessCheck extends StatefulWidget {
  const _SuccessCheck();
  @override
  State<_SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<_SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale = Curves.easeOutBack.transform(_controller.value);
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Transform.scale(
            scale: scale,
            child: const Icon(Icons.check_circle, color: Colors.green, size: 40),
          ),
        );
      },
    );
  }
}

/// Shows a short-lived, animated success confirmation, then dismisses
/// itself automatically.
Future<void> showSuccessOverlay(
  BuildContext context, {
  required String message,
  Duration visibleFor = const Duration(milliseconds: 1100),
}) async {
  final future = showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Success',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: Motion.normal,
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return _dialogShell(
        context,
        animation,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SuccessCheck(),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      );
    },
  );
  Future.delayed(visibleFor, () {
    if (context.mounted) Navigator.of(context, rootNavigator: true).maybePop();
  });
  await future;
}

/// A confirmation dialog with a soft scale/fade entrance, used for
/// destructive or important actions instead of an abrupt native dialog.
Future<bool> showMotionConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool danger = false,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: Motion.normal,
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return _dialogShell(
        context,
        animation,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 10),
            Text(message, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: MotionButton(
                    label: 'Cancel',
                    variant: MotionButtonVariant.outlined,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MotionButton(
                    label: confirmLabel,
                    variant: MotionButtonVariant.filled,
                    color: danger ? const Color(0xFFC62828) : null,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}

// ---------------------------------------------------------------------------
// Bottom navigation with an animated active icon
// ---------------------------------------------------------------------------

class NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
  const NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

class MotionBottomNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<NavItemData> items;

  const MotionBottomNavBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == index;
              final item = items[i];
              final color = selected ? theme.colorScheme.primary : Colors.grey.shade600;
              return Expanded(
                child: _NavTapArea(
                  onTap: () => onChanged(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.15 : 1.0,
                        duration: Motion.fast,
                        curve: Motion.softBounce,
                        child: AnimatedSwitcher(
                          duration: Motion.fast,
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: AnimatedBadge(
                            key: ValueKey('$i-$selected'),
                            count: item.badgeCount,
                            child: Icon(
                              selected ? item.activeIcon : item.icon,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: Motion.fast,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTapArea extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _NavTapArea({required this.onTap, required this.child});

  @override
  State<_NavTapArea> createState() => _NavTapAreaState();
}

class _NavTapAreaState extends State<_NavTapArea> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkResponse(
        onTap: widget.onTap,
        radius: 46,
        highlightShape: BoxShape.rectangle,
        child: AnimatedContainer(
          duration: Motion.fast,
          color: _hovering
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.04)
              : Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}
