import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:repartojusto/core/widgets/common_widgets.dart';
import 'package:repartojusto/core/utils/utils.dart';
import 'package:repartojusto/core/errors/app_error.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/features/auth/domain/app_user.dart';

class SkillsAvailabilityScreen extends ConsumerStatefulWidget {
  const SkillsAvailabilityScreen({super.key});

  @override
  ConsumerState<SkillsAvailabilityScreen> createState() => _SkillsAvailabilityScreenState();
}

class _SkillsAvailabilityScreenState extends ConsumerState<SkillsAvailabilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skillController = TextEditingController();
  late List<String> _skills;
  late AvailabilityMap _availability;
  bool _isLoading = false;
  bool _isInitialized = false;

  static const _daysOfWeek = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _skills = [];
    _availability = {};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final profile = ref.read(currentProfileSyncProvider);
      if (profile != null) {
        _skills = List<String>.from(profile.skills);
        _availability = Map<String, List<String>>.from(profile.availability);
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  void _addTimeRange(String day) {
    showTimeRangePickerDialog(context).then((range) {
      if (range != null) {
        setState(() {
          _availability.putIfAbsent(day, () => []).add(range);
          // Ordenar por hora de inicio
          _availability[day]!.sort((a, b) => a.split('-')[0].compareTo(b.split('-')[0]));
        });
      }
    });
  }

  void _removeTimeRange(String day, int index) {
    setState(() {
      _availability[day]!.removeAt(index);
      if (_availability[day]!.isEmpty) {
        _availability.remove(day);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userRepository = ref.read(userRepositoryProvider);
    final currentUser = ref.read(currentProfileSyncProvider);

    if (currentUser == null) {
      if (mounted) {
        showAppSnackBar(context, 'Error: No hay usuario logueado');
        setState(() => _isLoading = false);
      }
      return;
    }

    final result = await userRepository.updateProfile(
      uid: currentUser.uid,
      skills: _skills,
      availability: _availability,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        onError: (error) => showAppSnackBar(context, 'Error: ${error.message}'),
        onSuccess: (_) {
          showAppSnackBar(context, 'Perfil actualizado correctamente');
          Navigator.pop(context);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills y disponibilidad'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Guardar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sección Skills
            SectionDivider(label: 'Skills / Tecnologías'),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Añade las tecnologías que dominas (ej: Flutter, Firebase, Python, React, SQL...)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _skillController,
                          decoration: const InputDecoration(
                            labelText: 'Nueva skill',
                            hintText: 'Ej: Flutter',
                            prefixIcon: Icon(Icons.code),
                          ),
                          onSubmitted: (_) => _addSkill(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _addSkill,
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_skills.isEmpty)
                    Text(
                      'Sin skills añadidos',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _skills.map((skill) => _SkillChip(
                        label: skill,
                        onDelete: () => _removeSkill(skill),
                      )).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Sección Disponibilidad
            SectionDivider(label: 'Disponibilidad horaria'),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona tus horarios disponibles por día de la semana',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._daysOfWeek.map((day) => _DayAvailabilitySection(
                    day: day,
                    timeRanges: _availability[day] ?? [],
                    onAdd: () => _addTimeRange(day),
                    onRemove: (index) => _removeTimeRange(day, index),
                  )),
                  if (_availability.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Sin horarios configurados',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botón guardar grande al final
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Guardando...' : 'Guardar cambios'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({
    required this.label,
    required this.onDelete,
  });

  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputChip(
      label: Text(label),
      onDeleted: onDelete,
      deleteIconColor: theme.colorScheme.onSurfaceVariant,
      backgroundColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: theme.colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _DayAvailabilitySection extends StatelessWidget {
  const _DayAvailabilitySection({
    required this.day,
    required this.timeRanges,
    required this.onAdd,
    required this.onRemove,
  });

  final String day;
  final List<String> timeRanges;
  final VoidCallback onAdd;
  final Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(
        day,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: timeRanges.isEmpty
          ? Text(
              'Sin horarios',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Text(
              '${timeRanges.length} rango${timeRanges.length > 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
      leading: Icon(
        timeRanges.isEmpty ? Icons.schedule_outlined : Icons.schedule,
        color: timeRanges.isEmpty ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
      ),
      trailing: IconButton(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        tooltip: 'Añadir horario',
      ),
      children: [
        if (timeRanges.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'No hay horarios para este día',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...timeRanges.asMap().entries.map((entry) {
            final index = entry.key;
            final range = entry.value;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(range, style: theme.textTheme.bodyMedium),
                      ),
                      IconButton(
                        onPressed: () => onRemove(index),
                        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Añadir otro rango'),
          ),
        ),
      ],
    );
  }
}

/// Diálogo para seleccionar un rango horario
Future<String?> showTimeRangePickerDialog(BuildContext context) async {
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Añadir rango horario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Hora de inicio'),
              subtitle: Text(startTime?.format(context) ?? 'Seleccionar'),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: startTime ?? TimeOfDay.now(),
                );
                if (picked != null) setState(() => startTime = picked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Hora de fin'),
              subtitle: Text(endTime?.format(context) ?? 'Seleccionar'),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: endTime ?? TimeOfDay.now(),
                );
                if (picked != null) setState(() => endTime = picked);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: (startTime != null && endTime != null)
                ? () {
                    final start = startTime!.format(context);
                    final end = endTime!.format(context);
                    // Validar que inicio < fin
                    final startMinutes = startTime!.hour * 60 + startTime!.minute;
                    final endMinutes = endTime!.hour * 60 + endTime!.minute;
                    if (startMinutes >= endMinutes) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('La hora de fin debe ser posterior a la de inicio')),
                      );
                      return;
                    }
                    Navigator.pop(context, '$start-$end');
                  }
                : null,
            child: const Text('Añadir'),
          ),
        ],
      ),
    ),
  );
}