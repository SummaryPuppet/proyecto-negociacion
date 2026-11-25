import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:repartojusto/core/theme/app_theme.dart';
import 'package:repartojusto/core/widgets/common_widgets.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/features/groups/application/group_providers.dart';
import 'package:repartojusto/features/groups/domain/app_group.dart';
import 'package:repartojusto/features/tasks/application/task_providers.dart';

/// Carga los datos reales de equidad combinando grupo, tareas y perfiles.
final _projectFairnessProvider = FutureProvider.family<
    ({List<_MemberFairness> members, int totalPoints, int totalHours}),
    ({String groupId, String projectId})>((ref, params) async {
  final group = await ref.watch(groupProvider(params.groupId).future);
  final tasks = await ref.watch(tasksProvider(params).future);

  if (group == null) {
    return (members: <_MemberFairness>[], totalPoints: 0, totalHours: 0);
  }

  final userRepo = ref.read(userRepositoryProvider);

  // Solo estudiantes participan en el reparto de carga (excluimos al docente)
  final studentIds =
  group.memberIds.where((uid) => !group.isTeacher(uid)).toList();

  final totalPoints = tasks.fold<int>(0, (sum, t) => sum + t.weight);
  final totalHours = tasks.fold<int>(0, (sum, t) => sum + t.estHours);

  final members = <_MemberFairness>[];
  for (final uid in studentIds) {
    final profile = await userRepo.getProfile(uid);
    final studentTasks = tasks.where((t) => t.assigneeId == uid);

    final assignedPoints =
    studentTasks.fold<int>(0, (sum, t) => sum + t.weight);
    final assignedHours =
    studentTasks.fold<int>(0, (sum, t) => sum + t.estHours);

    members.add(
      _MemberFairness(
        id: uid,
        name: profile?.name ?? 'Estudiante (${uid.substring(0, 5)})',
        isLeader: group.isLeader(uid),
        assignedPoints: assignedPoints,
        assignedHours: assignedHours,
      ),
    );
  }

  return (
  members: members,
  totalPoints: totalPoints,
  totalHours: totalHours,
  );
});

class FairnessScreen extends ConsumerWidget {
  const FairnessScreen({
    super.key,
    required this.groupId,
    required this.projectId,
  });

  final String groupId;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (groupId: groupId, projectId: projectId);
    final fairnessAsync = ref.watch(_projectFairnessProvider(params));

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de equidad')),
      body: fairnessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorScreen(
          message: 'Error al calcular equidad: $error',
          onRetry: () => ref.invalidate(_projectFairnessProvider(params)),
        ),
        data: (data) {
          final members = data.members;
          if (members.isEmpty) {
            return const EmptyState(
              icon: Icons.balance_rounded,
              title: 'Sin estudiantes en el grupo',
              message:
              'Aún no hay estudiantes unidos al grupo para calcular la cuota justa.',
            );
          }

          final totalPoints = data.totalPoints;
          final fairShare = totalPoints / members.length;
          final fairShareHours = data.totalHours / members.length;

          final overloadedMembers = members
              .where((m) =>
          (fairShare > 0 && m.assignedPoints > fairShare * 1.2) ||
              (fairShareHours > 0 &&
                  m.assignedHours > fairShareHours * 1.2))
              .toList();

          final maxPoints = members
              .map((m) => m.assignedPoints)
              .fold<int>(0, (prev, el) => el > prev ? el : prev);
          final maxHours = members
              .map((m) => m.assignedHours)
              .fold<int>(0, (prev, el) => el > prev ? el : prev);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Alerta global si alguien supera +20%
              if (overloadedMembers.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Desbalance detectado: ${overloadedMembers.map((m) => m.name).join(', ')} '
                              'supera en más de +20% la cuota justa. El árbitro debe justificar esta carga.',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Resumen general
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen del proyecto',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'Puntos totales',
                            value: '$totalPoints',
                            icon: Icons.star_rounded,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Cuota justa (pts)',
                            value: fairShare.toStringAsFixed(1),
                            icon: Icons.balance_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Cuota justa (h)',
                            value: fairShareHours.toStringAsFixed(1),
                            icon: Icons.access_time_rounded,
                            color: context.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cuota justa = puntos totales / ${members.length} estudiantes. '
                          'Se alerta si alguien supera +20% (${(fairShare * 1.2).toStringAsFixed(1)} pts).',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Gráfico de barras - Puntos
              SectionDivider(label: 'Puntos asignados por estudiante'),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 260,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: math.max(10.0, maxPoints * 1.3),
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < members.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    members[idx].name.split(' ').first,
                                    style:
                                    Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Theme.of(context).dividerColor,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: members.asMap().entries.map((entry) {
                        final index = entry.key;
                        final member = entry.value;
                        final isOverQuota = fairShare > 0 &&
                            member.assignedPoints > fairShare * 1.2;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: member.assignedPoints.toDouble(),
                              width: 28,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8)),
                              color: isOverQuota
                                  ? Colors.red
                                  : Theme.of(context).colorScheme.primary,
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: fairShare,
                                color: context.primary.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Gráfico de barras - Horas
              SectionDivider(label: 'Horas estimadas por estudiante'),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 260,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: math.max(5.0, maxHours * 1.3),
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < members.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    members[idx].name.split(' ').first,
                                    style:
                                    Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Theme.of(context).dividerColor,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: members.asMap().entries.map((entry) {
                        final index = entry.key;
                        final member = entry.value;
                        final isOverQuota = fairShareHours > 0 &&
                            member.assignedHours > fairShareHours * 1.2;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: member.assignedHours.toDouble(),
                              width: 28,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8)),
                              color:
                              isOverQuota ? Colors.red : context.success,
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: fairShareHours,
                                color: context.success.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Detalle por estudiante
              SectionDivider(label: 'Detalle por estudiante'),
              const SizedBox(height: 8),
              ...members.map((m) => _MemberFairnessTile(
                member: m,
                fairSharePoints: fairShare,
                fairShareHours: fairShareHours,
              )),
            ],
          );
        },
      ),
    );
  }
}

class _MemberFairness {
  final String id;
  final String name;
  final bool isLeader;
  final int assignedPoints;
  final int assignedHours;

  _MemberFairness({
    required this.id,
    required this.name,
    required this.isLeader,
    required this.assignedPoints,
    required this.assignedHours,
  });
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MemberFairnessTile extends StatelessWidget {
  const _MemberFairnessTile({
    required this.member,
    required this.fairSharePoints,
    required this.fairShareHours,
  });

  final _MemberFairness member;
  final double fairSharePoints;
  final double fairShareHours;

  @override
  Widget build(BuildContext context) {
    final pointsOver =
        fairSharePoints > 0 && member.assignedPoints > fairSharePoints * 1.2;
    final hoursOver =
        fairShareHours > 0 && member.assignedHours > fairShareHours * 1.2;
    final hasWarning = pointsOver || hoursOver;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          UserAvatar(name: member.name, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.isLeader) ...[
                      const SizedBox(width: 8),
                      StatusChip(label: 'Jefe', status: StatusType.success),
                    ],
                  ],
                ),
                if (hasWarning) ...[
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'Supera cuota justa +20%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Metric(
                label: 'Puntos',
                value: '${member.assignedPoints}',
                target: fairSharePoints.toStringAsFixed(1),
                isOver: pointsOver,
                color: Colors.amber.shade700,
              ),
              const SizedBox(height: 8),
              _Metric(
                label: 'Horas',
                value: '${member.assignedHours}',
                target: fairShareHours.toStringAsFixed(1),
                isOver: hoursOver,
                color: context.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.target,
    required this.isOver,
    required this.color,
  });

  final String label;
  final String value;
  final String target;
  final bool isOver;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isOver ? Colors.red : color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '/ $target',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}