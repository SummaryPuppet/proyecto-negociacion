import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../core/utils/utils.dart';

class OfferFormScreen extends StatefulWidget {
  const OfferFormScreen({
    super.key,
    required this.groupId,
    required this.projectId,
    required this.taskId,
  });

  final String groupId;
  final String projectId;
  final String taskId;

  @override
  State<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends State<OfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pointsController = TextEditingController();
  final _hoursController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pointsController.dispose();
    _hoursController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva oferta')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  'Hacer oferta',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Indica los puntos que pides, horas estimadas y tu motivación. El grupo votará tu propuesta.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Puntos
                TextFormField(
                  controller: _pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Puntos que pides',
                    hintText: 'ej. 40',
                    prefixIcon: Icon(Icons.star_outlined),
                    helperText: 'Peso de la tarea en el proyecto',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requerido';
                    final points = int.tryParse(value);
                    if (points == null || points <= 0) return 'Debe ser > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Horas
                TextFormField(
                  controller: _hoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Horas estimadas',
                    hintText: 'ej. 12',
                    prefixIcon: Icon(Icons.access_time_outlined),
                    helperText: 'Tiempo que necesitas para completarla',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requerido';
                    final hours = int.tryParse(value);
                    if (hours == null || hours <= 0) return 'Debe ser > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mensaje
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Motivación / Comentario',
                    hintText: 'Explica por qué eres la mejor persona para esta tarea, tu experiencia, disponibilidad...',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Escribe algo';
                    if (value.trim().length < 10) return 'Mínimo 10 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Aviso de equidad (simulado)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Si tu oferta supera tu cuota justa en +20%, el árbitro deberá justificar la asignación.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                LoadingButton(
                  onPressed: _submit,
                  isLoading: _isLoading,
                  child: const Text('Enviar oferta'),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulación

    if (mounted) {
      setState(() => _isLoading = false);
      context.pop();
      showAppSnackBar(context, 'Oferta enviada (simulado). El grupo votará ahora.');
    }
  }
}