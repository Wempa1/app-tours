import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avanti/di/providers.dart';
import 'package:avanti/features/payments/data/payment_models.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Métodos de Pago')),
      body: methodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorView(
          message: 'No pudimos cargar tus métodos de pago.',
          onRetry: () => ref.invalidate(paymentMethodsProvider),
        ),
        data: (list) => _ListView(
          items: list,
          onSetDefault: (id) => _setDefault(context, id),
          onDelete: (id) => _delete(context, id),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _working ? null : () => _showAddDialog(context),
            icon: const Icon(Icons.add_card),
            label: const Text('Agregar método (demo)'),
          ),
        ),
      ),
    );
  }

  Future<void> _setDefault(BuildContext context, String id) async {
    final repo = ref.read(paymentRepoProvider);
    setState(() => _working = true);
    try {
      await repo.setDefault(id);
      if (!mounted) return;
      ref.invalidate(paymentMethodsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Método establecido como predeterminado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el método')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _delete(BuildContext context, String id) async {
    final repo = ref.read(paymentRepoProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar método'),
        content: const Text('¿Seguro que quieres eliminar este método de pago?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _working = true);
    try {
      await repo.delete(id);
      if (!mounted) return;
      ref.invalidate(paymentMethodsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Método eliminado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el método')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final brandCtrl = TextEditingController(text: 'Visa');
    final last4Ctrl = TextEditingController(text: '4242');
    final monthCtrl = TextEditingController(text: '12');
    final yearCtrl = TextEditingController(text: '2030');
    final labelCtrl = TextEditingController(text: 'Personal');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar método (demo)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: brandCtrl,
              decoration: const InputDecoration(
                labelText: 'Marca (ej: Visa, MasterCard)',
              ),
            ),
            TextField(
              controller: last4Ctrl,
              decoration:
                  const InputDecoration(labelText: 'Últimos 4 dígitos'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: monthCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Mes (MM)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: yearCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Año (YYYY)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            TextField(
              controller: labelCtrl,
              decoration:
                  const InputDecoration(labelText: 'Alias (opcional)'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Solo DEMO. En producción integra un PSP (Stripe/MercadoPago) y tokeniza.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Agregar')),
        ],
      ),
    );
    if (ok != true) return;

    final brand =
        brandCtrl.text.trim().isEmpty ? 'Card' : brandCtrl.text.trim();
    final last4 = last4Ctrl.text.trim();
    final m = int.tryParse(monthCtrl.text.trim()) ?? 1;
    final y = int.tryParse(yearCtrl.text.trim()) ?? 2030;

    if (last4.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Los últimos 4 dígitos deben tener longitud 4.')),
      );
      return;
    }
    if (m < 1 || m > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mes inválido.')),
      );
      return;
    }

    final repo = ref.read(paymentRepoProvider);
    setState(() => _working = true);
    try {
      await repo.addTestMethod(
        brand: brand,
        last4: last4,
        expMonth: m,
        expYear: y,
        label: labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
      );
      if (!mounted) return;
      ref.invalidate(paymentMethodsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Método agregado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo agregar el método')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}

class _ListView extends StatelessWidget {
  final List<PaymentMethod> items;
  final ValueChanged<String> onSetDefault;
  final ValueChanged<String> onDelete;

  const _ListView({
    required this.items,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Aún no tienes métodos de pago.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final pm = items[i];
        final title =
            '${pm.brand} •••• ${pm.last4}${pm.label != null && pm.label!.isNotEmpty ? ' — ${pm.label}' : ''}';
        final subtitle =
            'Expira ${pm.expMonth.toString().padLeft(2, '0')}/${pm.expYear % 100}';

        return ListTile(
          leading: Icon(_brandIcon(pm.brand)),
          title: Row(
            children: [
              Flexible(child: Text(title)),
              if (pm.isDefault) ...[
                const SizedBox(width: 8),
                const Chip(label: Text('Predeterminado'), visualDensity: VisualDensity.compact),
              ],
            ],
          ),
          subtitle: Text(subtitle),
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'default') onSetDefault(pm.id);
              if (v == 'delete') onDelete(pm.id);
            },
            itemBuilder: (_) => [
              if (!pm.isDefault)
                const PopupMenuItem(
                    value: 'default',
                    child: Text('Establecer como predeterminado')),
              const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          onTap: () {},
        );
      },
    );
  }

  static IconData _brandIcon(String brand) {
    final b = brand.toLowerCase();
    if (b.contains('visa')) return Icons.credit_card;
    if (b.contains('master')) return Icons.credit_card;
    if (b.contains('amex')) return Icons.credit_card;
    if (b.contains('mercado')) return Icons.account_balance_wallet_outlined;
    return Icons.payment;
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
