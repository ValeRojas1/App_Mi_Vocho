import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../screens/owner_profile_screen.dart';
import '../screens/owner_promotions_screen.dart';

class OwnerSideDrawer extends StatelessWidget {
  const OwnerSideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    const cream = AppTheme.creamVintage;
    final user = Supabase.instance.client.auth.currentUser;

    return Drawer(
      backgroundColor: AppTheme.vwBlue,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: cream,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Panel de dueña',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'La Casa del Volkswagen',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cream.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.18), height: 1),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.campaign_outlined,
              label: 'Ofertas y noticias',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OwnerPromotionsScreen(),
                  ),
                );
              },
            ),
            _DrawerItem(
              icon: Icons.person_outline,
              label: 'Perfil',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OwnerProfileScreen()),
                );
              },
            ),
            const Spacer(),
            Divider(color: Colors.white.withValues(alpha: 0.18), height: 1),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Cerrar sesión',
              onTap: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.creamVintage),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}
