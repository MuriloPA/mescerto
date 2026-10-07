import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../finance.dart';
import '../theme.dart';

const kReg = FontWeight.w400;
const kMed = FontWeight.w500;
const kSemi = FontWeight.w600;
const kBold = FontWeight.w700;

TextStyle inter(double size, FontWeight w, Color color,
        {double? height, double? ls}) =>
    GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        color: color,
        height: height,
        letterSpacing: ls);

extension Ctx on BuildContext {
  FinanceProvider get fin => Provider.of<FinanceProvider>(this);
  AppPalette get pal => Provider.of<FinanceProvider>(this).colors;
}

/// Screen
class AppScreen extends StatelessWidget {
  final String? title;
  final Widget? right;
  final Widget child;
  const AppScreen({super.key, this.title, this.right, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.pal;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title!, style: inter(26, kBold, c.foreground)),
                      if (right != null) right!,
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class LogoMark extends StatelessWidget {
  final bool compact;
  const LogoMark({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = context.pal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/icon.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(text: 'Mês', children: [
              TextSpan(text: 'Certo', style: TextStyle(color: c.primary))
            ]),
            style: inter(21, kBold, c.foreground),
          ),
        ],
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool secondary;
  final bool disabled;
  const PrimaryButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon,
      this.secondary = false,
      this.disabled = false});

  @override
  Widget build(BuildContext context) {
    final c = context.pal;
    final fg = secondary ? c.primary : Colors.white;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: Material(
          color: secondary ? c.surface : c.primary,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: c.primary)),
          child: InkWell(
            onTap: disabled ? null : onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 8)
                ],
                Text(label, style: inter(15, kBold, fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Color? borderColor;
  final double? minHeight;
  final VoidCallback? onTap;
  const AppCard(
      {super.key,
      required this.child,
      this.padding,
      this.margin,
      this.color,
      this.borderColor,
      this.minHeight,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.pal;
    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      constraints:
          minHeight != null ? BoxConstraints(minHeight: minHeight!) : null,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? c.border),
      ),
      child: child,
    );
    return onTap == null ? card : GestureDetector(onTap: onTap, child: card);
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onPressed;
  const SectionHeader(
      {super.key, required this.title, this.action, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = context.pal;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: inter(17, kBold, c.foreground)),
          if (action != null)
            GestureDetector(
                onTap: onPressed,
                child: Text(action!, style: inter(13, kSemi, c.primary))),
        ],
      ),
    );
  }
}

class IconCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconCircle(
      {super.key, required this.icon, required this.color, this.size = 42});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(0x22)),
        child: Icon(icon, size: size * 0.48, color: color),
      );
}

class AppField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? error;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  const AppField(
      {super.key,
      required this.label,
      this.hint,
      this.error,
      this.controller,
      this.keyboardType,
      this.obscure = false,
      this.suffix});

  @override
  Widget build(BuildContext context) {
    final c = context.pal;
    OutlineInputBorder border(Color col) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: col));
    final hasError = error != null && error!.isNotEmpty;
    final b = border(hasError ? c.danger : c.border);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: inter(13, kSemi, c.foreground)),
          const SizedBox(height: 7),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            autocorrect: !obscure,
            style: inter(15, kReg, c.foreground),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: inter(15, kReg, c.mutedForeground),
              filled: true,
              fillColor: c.surface,
              suffixIcon: suffix,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              enabledBorder: b,
              focusedBorder: b,
              border: b,
            ),
          ),
          if (hasError)
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(error!,
                    style: TextStyle(fontSize: 12, color: c.danger))),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title, description;
  final IconData icon;
  const EmptyState(
      {super.key,
      required this.title,
      required this.description,
      this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    final c = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(children: [
            IconCircle(icon: icon, color: c.primary, size: 54),
            const SizedBox(height: 10),
            Text(title, style: inter(17, kBold, c.foreground)),
            const SizedBox(height: 10),
            Text(description,
                textAlign: TextAlign.center,
                style: inter(14, kReg, c.mutedForeground, height: 1.5)),
          ]),
        ),
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color, track;
  final double height;
  const ProgressBar(
      {super.key,
      required this.value,
      required this.color,
      required this.track,
      this.height = 6});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0).toDouble(),
          minHeight: height,
          backgroundColor: track,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
}

/// Equivalente ao Alert.alert do React Native
Future<void> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required VoidCallback onConfirm,
  bool destructive = false,
}) {
  final c = context.read<FinanceProvider>().colors;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.surface,
      title: Text(title, style: inter(17, kBold, c.foreground)),
      content:
          Text(message, style: inter(14, kReg, c.mutedForeground, height: 1.4)),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text('Cancelar', style: inter(14, kSemi, c.mutedForeground))),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm();
          },
          child: Text(confirmLabel,
              style: inter(14, kBold, destructive ? c.danger : c.primary)),
        ),
      ],
    ),
  );
}
