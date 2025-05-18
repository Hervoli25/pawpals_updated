import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_theme.dart'; // Ensure this path is correct
// import '../utils/constants.dart'; // Constants might be used for padding/borderRadius

// Custom app bar
class PawPalsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const PawPalsAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: Theme.of(context).appBarTheme.titleTextStyle),
      actions: actions,
      automaticallyImplyLeading: showBackButton,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      elevation: Theme.of(context).appBarTheme.elevation,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Custom button - Enhanced
class PawPalsButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isFullWidth;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PawPalsButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.primary,
            backgroundColor: backgroundColor,
            side: BorderSide(color: foregroundColor ?? Theme.of(context).colorScheme.primary, width: 1.5),
            padding: Theme.of(context).outlinedButtonTheme.style?.padding?.resolve({}),
            textStyle: Theme.of(context).outlinedButtonTheme.style?.textStyle?.resolve({}),
            shape: Theme.of(context).outlinedButtonTheme.style?.shape?.resolve({}),
            minimumSize: isFullWidth ? const Size(double.infinity, 48) : null, // Ensure consistent height
          ).copyWith(
            elevation: MaterialStateProperty.resolveWith<double?>((Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered)) return 2.0;
              if (states.contains(MaterialState.pressed)) return 0.0;
              return 0.0; // Default elevation
            }),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
            foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
            padding: Theme.of(context).elevatedButtonTheme.style?.padding?.resolve({}),
            textStyle: Theme.of(context).elevatedButtonTheme.style?.textStyle?.resolve({}),
            shape: Theme.of(context).elevatedButtonTheme.style?.shape?.resolve({}),
            elevation: Theme.of(context).elevatedButtonTheme.style?.elevation?.resolve({}),
            minimumSize: isFullWidth ? const Size(double.infinity, 48) : null, // Ensure consistent height
          ).copyWith(
            elevation: MaterialStateProperty.resolveWith<double?>((Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered)) return 4.0;
              if (states.contains(MaterialState.pressed)) return 0.0;
              return 2.0; // Default elevation from theme or specific value
            }),
          );

    final buttonContent = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: Theme.of(context).textTheme.labelLarge?.fontSize),
              const SizedBox(width: 8),
              Text(text),
            ],
          )
        : Text(text);

    final Widget buttonWidget = isOutlined
        ? OutlinedButton(onPressed: onPressed, style: style, child: buttonContent)
        : ElevatedButton(onPressed: onPressed, style: style, child: buttonContent);

    return isFullWidth && !isOutlined // For ElevatedButton, SizedBox is often redundant if minSize is set
        ? SizedBox(width: double.infinity, child: buttonWidget)
        : buttonWidget;
  }
}

// Custom text field - Enhanced
class PawPalsTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final Function(String)? onChanged;
  final bool isRequired;

  const PawPalsTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.isRequired = false, // Added for visual indication
  });

  @override
  State<PawPalsTextField> createState() => _PawPalsTextFieldState();
}

class _PawPalsTextFieldState extends State<PawPalsTextField> {
  bool _isFocused = false;
  String? _currentError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecorationTheme = theme.inputDecorationTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: _isFocused ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
              ),
            ),
            if (widget.isRequired)
              Text(
                widget.label.isNotEmpty ? 
                widget.label.endsWith("*") ? "" : " *" 
                : "*", 
                style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)
              ),
          ],
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _isFocused = hasFocus;
            });
          },
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: (value) {
              final error = widget.validator?.call(value);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _currentError = error;
                  });
                }
              });
              return error;
            },
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: inputDecorationTheme.hintStyle,
              prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, color: _isFocused ? theme.colorScheme.primary : theme.iconTheme.color) : null,
              suffixIcon: widget.suffixIcon,
              filled: inputDecorationTheme.filled,
              fillColor: inputDecorationTheme.fillColor,
              contentPadding: inputDecorationTheme.contentPadding,
              border: inputDecorationTheme.border,
              enabledBorder: inputDecorationTheme.enabledBorder,
              focusedBorder: inputDecorationTheme.focusedBorder,
              errorBorder: inputDecorationTheme.errorBorder,
              focusedErrorBorder: inputDecorationTheme.focusedErrorBorder,
              errorText: _currentError, // Display error text below the field
              errorStyle: TextStyle(color: theme.colorScheme.error, fontSize: 12), // Consistent error style
            ),
          ),
        ),
      ],
    );
  }
}

// Profile avatar
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.size = 60,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.person, size: size * 0.6, color: Theme.of(context).colorScheme.primary),
                )
              : Icon(
                  Icons.person,
                  size: size * 0.6,
                  color: Theme.of(context).colorScheme.primary,
                ),
        ),
      ),
    );
  }
}

// Dog avatar
class DogAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;

  const DogAvatar({
    super.key,
    this.imageUrl,
    this.size = 60,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.pets, size: size * 0.6, color: Theme.of(context).colorScheme.secondary),
                )
              : Icon(
                  Icons.pets,
                  size: size * 0.6,
                  color: Theme.of(context).colorScheme.secondary,
                ),
        ),
      ),
    );
  }
}

// Loading indicator
class PawPalsLoadingIndicator extends StatelessWidget {
  final String? message;

  const PawPalsLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

// Error message
class PawPalsErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const PawPalsErrorMessage({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              PawPalsButton(
                text: 'Retry',
                onPressed: onRetry!,
                isOutlined: false, // Or true, depending on desired style
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Custom Card Widget - Enhanced
class PawPalsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  final VoidCallback? onTap;

  const PawPalsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0), // Consistent default padding
    this.margin,
    this.color,
    this.elevation,
    this.shape,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;
    return Card(
      color: color ?? cardTheme.color,
      elevation: elevation ?? cardTheme.elevation,
      margin: margin ?? cardTheme.margin,
      shape: shape ?? cardTheme.shape,
      child: InkWell(
        onTap: onTap,
        borderRadius: (shape is RoundedRectangleBorder && (shape as RoundedRectangleBorder).borderRadius is BorderRadius)
            ? (shape as RoundedRectangleBorder).borderRadius as BorderRadius
            : BorderRadius.circular(12), // Default if shape is not RoundedRectangleBorder
        child: Padding(
          padding: padding!,
          child: child,
        ),
      ),
    );
  }
}

// Custom List Item Widget - Example
class PawPalsListItem extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;

  const PawPalsListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Consistent padding
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: contentPadding!,
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.bodyLarge,
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.bodyMedium,
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 16),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// Empty State Widget
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? details;
  final IconData icon;
  final Widget? actionButton;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.details,
    this.icon = Icons.info_outline, // Default icon
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionButton != null) ...[
              const SizedBox(height: 24),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}

