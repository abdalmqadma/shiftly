import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppSettingSwitchTile extends StatelessWidget {
  const AppSettingSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: const SizedBox.shrink(),
      title: Row(children: [
        Icon(icon, color: AppColors.primary, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ]),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle),
      ),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
