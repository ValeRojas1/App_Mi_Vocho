import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/app_errors.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/notification_service.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _repo = ProfileRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _notificationsEnabled = false;
  bool _requestingNotifications = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _regionCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await _repo.getMyProfile();
      final user = Supabase.instance.client.auth.currentUser;
      if (profile != null) {
        _nameCtrl.text = profile.fullName ?? '';
        _phoneCtrl.text = profile.phone ?? '';
        _regionCtrl.text = profile.region ?? '';
        _addressCtrl.text = profile.deliveryAddress ?? '';
      }
      _email = user?.email;
      _notificationsEnabled = await NotificationService.instance
          .areNotificationsEnabled();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (!enabled) {
      setState(() => _notificationsEnabled = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Desactiva las notificaciones de Mi Vocho en Ajustes del sistema si ya no las deseas.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _requestingNotifications = true);
    final granted = await NotificationService.instance
        .requestPermissionAndSubscribe();
    if (!mounted) return;
    setState(() {
      _requestingNotifications = false;
      _notificationsEnabled = granted;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Recibirás avisos cuando cambie el estado de tus pedidos.'
              : 'Permiso de notificaciones denegado. Actívalo en Ajustes del teléfono.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await _repo.updateMyProfile(
        ProfileModel(
          id: user.id,
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          region: _regionCtrl.text.trim(),
          deliveryAddress: _addressCtrl.text.trim(),
          role: 'client',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrors.message(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.email_outlined, color: primary),
                        title: const Text('Correo'),
                        subtitle: Text(_email ?? '—'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono / WhatsApp',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _regionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Región / Ciudad',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dirección de entrega (encomienda)',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('GUARDAR PERFIL'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Notificaciones',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: SwitchListTile(
                        secondary: Icon(
                          Icons.notifications_active_outlined,
                          color: primary,
                        ),
                        title: const Text('Estado de mis pedidos'),
                        subtitle: Text(
                          _notificationsEnabled
                              ? 'Avisos en tiempo real aunque salgas de la app (con internet).'
                              : 'Activa para recibir cambios de estado de tus pedidos.',
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: _notificationsEnabled,
                        onChanged: _requestingNotifications
                            ? null
                            : _toggleNotifications,
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
