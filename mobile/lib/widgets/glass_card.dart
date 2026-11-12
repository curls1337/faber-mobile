import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/tokens.dart';

/// VisionOS Liquid Glass Card with frosted backdrop blur and specular hairline border.
class FaberGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool elevated;
  final bool enableBlur;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const FaberGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = FaberTokens.radiusLg,
    this.elevated = false,
    this.enableBlur = true,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final effectiveBg = backgroundColor ??
        (elevated
            ? FaberTokens.surfaceGlassElevated
            : FaberTokens.surfaceGlass);
    final effectiveBorder = borderColor ??
        (elevated ? FaberTokens.borderGlassStrong : FaberTokens.borderGlass);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? effectiveBg : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: effectiveBorder, width: 1),
      ),
      child: child,
    );

    if (enableBlur) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: FaberTokens.blurSigma,
            sigmaY: FaberTokens.blurSigma,
          ),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: content,
      );
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: FaberTokens.indigoSoft,
          highlightColor: FaberTokens.surfaceGlassLight,
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: elevated ? FaberTokens.glassShadow : null,
      ),
      child: content,
    );
  }
}

/// Interactive Liquid Glass / Gradient Action Button.
class FaberGlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final bool isLoading;
  final bool compact;
  final Color? accentColor;

  const FaberGlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.isLoading = false,
    this.compact = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;
    final Color baseAccent = isDestructive
        ? FaberTokens.accentRose
        : (accentColor ?? FaberTokens.accentIndigo);

    final BorderRadius br = BorderRadius.circular(
      compact ? FaberTokens.radiusSm : FaberTokens.radiusMd,
    );

    return Opacity(
      opacity: disabled ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: br,
          gradient: isPrimary && !isDestructive
              ? FaberTokens.accentGradient
              : null,
          color: isPrimary
              ? (isDestructive ? FaberTokens.accentRose : null)
              : (isDestructive
                  ? FaberTokens.roseSoft
                  : FaberTokens.surfaceGlassLight),
          border: Border.all(
            color: isPrimary
                ? baseAccent.withOpacity(0.6)
                : (isDestructive
                    ? FaberTokens.accentRose.withOpacity(0.4)
                    : FaberTokens.borderGlass),
          ),
          boxShadow: isPrimary ? FaberTokens.glowShadow(baseAccent) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: br,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 18,
                vertical: compact ? 8 : 13,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else if (icon != null) ...[
                    Icon(
                      icon,
                      size: compact ? 15 : 18,
                      color: isPrimary
                          ? Colors.white
                          : (isDestructive
                              ? FaberTokens.accentRose
                              : FaberTokens.textPrimary),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isPrimary
                            ? Colors.white
                            : (isDestructive
                                ? FaberTokens.accentRose
                                : FaberTokens.textPrimary),
                        fontSize: compact ? 12.5 : 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact Status / Filter Pill with optional leading dot or icon.
class FaberPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool showDot;
  final bool selected;
  final VoidCallback? onTap;

  const FaberPill({
    super.key,
    required this.label,
    this.color = FaberTokens.accentIndigo,
    this.icon,
    this.showDot = false,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        selected ? color.withOpacity(0.24) : color.withOpacity(0.12);
    final borderColor =
        selected ? color.withOpacity(0.75) : color.withOpacity(0.32);

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: FaberTokens.brPill,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: FaberTokens.brPill,
        child: pill,
      ),
    );
  }
}
