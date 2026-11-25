
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/features/offers/aplication/offer_providers.dart';

class OfferFormScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String projectId;
  final String taskId;
  final String? parentOfferId;

  const OfferFormScreen({
    super.key,
    required this.groupId,
    required this.projectId,
    required this.taskId,
    this.parentOfferId,
  });

  @override
  ConsumerState<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends ConsumerState<OfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pointsController = TextEditingController();
  final _hoursController = TextEditingController();
  final _argumentController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _pointsController.dispose();
    _hoursController.dispose();
    _argumentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateChangesProvider).value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para enviar una oferta.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(offerRepositoryProvider).createOffer(
            groupId: widget.groupId,
            projectId: widget.projectId,
            taskId: widget.taskId,
            authorId: user.uid,
            points: int.parse(_pointsController.text.trim()),
            hours: int.parse(_hoursController.text.trim()),
            argument: _argumentController.text,
            parentOfferId: widget.parentOfferId,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.parentOfferId == null
                ? '¡Tu oferta fue enviada!'
                : '¡Tu contraoferta fue enviada!',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar la oferta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _validatePositiveNumber(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa $field.';
    }

    final number = int.tryParse(value.trim());

    if (number == null || number <= 0) {
      return 'Ingresa un número entero mayor que cero.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isCounterOffer = widget.parentOfferId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCounterOffer ? 'Crear contraoferta' : 'Hacer una oferta'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                isCounterOffer
                    ? 'Propón una nueva distribución como respuesta a otra oferta.'
                    : 'Indica cuántos puntos solicitas y cuántas horas estimas dedicar.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Puntos que solicitas',
                  prefixIcon: Icon(Icons.stars_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    _validatePositiveNumber(value, 'los puntos'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Horas estimadas',
                  prefixIcon: Icon(Icons.schedule),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    _validatePositiveNumber(value, 'las horas'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _argumentController,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Motivación de tu oferta',
                  hintText:
                      'Explica por qué propones esta cantidad de puntos y horas.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Explica tu propuesta en al menos 10 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSaving
                      ? 'Enviando...'
                      : isCounterOffer
                          ? 'Enviar contraoferta'
                          : 'Enviar oferta',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
