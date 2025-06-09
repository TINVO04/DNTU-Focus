import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationPressed;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    this.onNotificationPressed,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        )
            : null,
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.primary,
            ],
          ).createShader(bounds),
          child: Text(
            'DNTU Focus',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
            ),
            onPressed: onNotificationPressed ?? () {},
          ),
          if (!showBackButton)
            _SettingsIconButton(),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SettingsIconButton extends StatefulWidget {
  @override
  _SettingsIconButtonState createState() => _SettingsIconButtonState();
}

class _SettingsIconButtonState extends State<_SettingsIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.settings,
        color: _isPressed
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).iconTheme.color?.withOpacity(0.6),
      ),
      onPressed: () {
        setState(() {
          _isPressed = true;
        });
        Navigator.pushNamed(context, AppRoutes.settings);
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {
            _isPressed = false;
          });
        });
      },
    );
  }
}