import 'package:flutter/material.dart';

/// Botón de carga reutilizable.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : child,
    );
  }
}

/// Tarjeta con sombra suave y bordes redondeados.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.color,
    this.border,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      );
    }
    return card;
  }
}

/// Indicador de estado vacío.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pantalla de error genérica.
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Reintentar',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Algo salió mal',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar con iniciales o imagen.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 20,
    this.fontSize,
  });

  final String? photoUrl;
  final String name;
  final double radius;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    // Generar color basado en el nombre (para fallback)
    final hash = name.hashCode;
    final hue = (hash % 360).toDouble();
    final color = HSVColor.fromAHSV(1, hue, 0.6, 0.9).toColor();

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color,
        backgroundImage: NetworkImage(photoUrl!),
        // Fallback a iniciales si la imagen falla (ej. 429 de Google)
        onBackgroundImageError: (_, __) {},
        child: Text(
          _initials(name),
          style: TextStyle(
            fontSize: fontSize ?? radius * 0.7,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        _initials(name),
        style: TextStyle(
          fontSize: fontSize ?? radius * 0.7,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}

/// Chip de estado con color semántico.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.status,
  });

  final String label;
  final StatusType status;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.text,
        ),
      ),
    );
  }

  _StatusColors _statusColors(BuildContext context) {
    switch (status) {
      case StatusType.success:
        return _StatusColors(
          background: Colors.green.withOpacity(0.1),
          border: Colors.green.withOpacity(0.3),
          text: Colors.green.shade700,
        );
      case StatusType.warning:
        return _StatusColors(
          background: Colors.orange.withOpacity(0.1),
          border: Colors.orange.withOpacity(0.3),
          text: Colors.orange.shade700,
        );
      case StatusType.error:
        return _StatusColors(
          background: Colors.red.withOpacity(0.1),
          border: Colors.red.withOpacity(0.3),
          text: Colors.red.shade700,
        );
      case StatusType.info:
        return _StatusColors(
          background: Colors.blue.withOpacity(0.1),
          border: Colors.blue.withOpacity(0.3),
          text: Colors.blue.shade700,
        );
      case StatusType.neutral:
        return _StatusColors(
          background: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Theme.of(context).colorScheme.outline,
          text: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _StatusColors {
  const _StatusColors({
    required this.background,
    required this.border,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color text;
}

enum StatusType { success, warning, error, info, neutral }

/// Separador con texto opcional.
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Divider(
        color: Theme.of(context).dividerColor,
        height: 1,
        thickness: 1,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Expanded(child: Divider(thickness: 1)),
        ],
      ),
    );
  }
}

/// Indicador de progreso circular con porcentaje.
class CircularProgressWithPercent extends StatelessWidget {
  const CircularProgressWithPercent({
    super.key,
    required this.progress,
    this.size = 60,
    this.strokeWidth = 6,
    this.backgroundColor,
    this.progressColor,
    this.showPercent = true,
    this.style,
  });

  final double progress; // 0.0 a 1.0
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final bool showPercent;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(progressColor ?? Theme.of(context).colorScheme.primary),
          ),
          if (showPercent)
            Center(
              child: Text(
                '${(progress * 100).round()}%',
                style: style ?? Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}