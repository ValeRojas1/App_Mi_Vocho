import 'package:flutter/material.dart';

import '../../../core/constants/order_constants.dart';
import '../../../core/utils/app_errors.dart';
import '../../../data/models/admin_user_model.dart';
import '../../../data/repositories/admin_user_repository.dart';
import '../../shared/widgets/branded_app_bar_title.dart';
import '../../shared/widgets/list_shimmer.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _repo = AdminUserRepository();
  List<AdminUserModel> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _repo.listUsers();
      if (!mounted) return;
      setState(() => _users = users);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppErrors.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    var role = AppRole.client.value;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuevo usuario'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      if (!v.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: AppRole.values
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.value,
                            child: Text(r.label),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) => setDialogState(() => role = v ?? role),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        await _repo.createUser(
                          email: emailCtrl.text.trim(),
                          password: passwordCtrl.text,
                          fullName: nameCtrl.text.trim(),
                          role: role,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        await refresh();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Usuario creado correctamente'),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(AppErrors.message(e))),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
  }

  Future<void> _confirmDelete(AdminUserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Eliminar a ${user.fullName ?? user.email}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repo.deleteUser(user.id);
      await refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrors.message(e))),
      );
    }
  }

  Future<void> _changeRole(AdminUserModel user, String newRole) async {
    try {
      await _repo.updateUserRole(user.id, newRole);
      await refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rol actualizado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrors.message(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(subtitle: 'Gestión de usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Nuevo usuario'),
      ),
      body: _loading
          ? const ListShimmer(itemCount: 6, itemHeight: 72)
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: refresh,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: refresh,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 700) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(
                          primary.withValues(alpha: 0.06),
                        ),
                        columns: const [
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Correo')),
                          DataColumn(label: Text('Rol')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: _users.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(Text(user.fullName ?? '—')),
                              DataCell(Text(user.email)),
                              DataCell(
                                DropdownButton<String>(
                                  value: user.role,
                                  underline: const SizedBox.shrink(),
                                  items: AppRole.values
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r.value,
                                          child: Text(r.label),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (role) {
                                    if (role == null || role == user.role) {
                                      return;
                                    }
                                    _changeRole(user, role);
                                  },
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  tooltip: 'Eliminar',
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red.shade700,
                                  ),
                                  onPressed: () => _confirmDelete(user),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName ?? user.email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: user.role,
                                      decoration: const InputDecoration(
                                        labelText: 'Rol',
                                        isDense: true,
                                      ),
                                      items: AppRole.values
                                          .map(
                                            (r) => DropdownMenuItem(
                                              value: r.value,
                                              child: Text(r.label),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (role) {
                                        if (role == null ||
                                            role == user.role) {
                                          return;
                                        }
                                        _changeRole(user, role);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    onPressed: () => _confirmDelete(user),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
