import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/common_widgets.dart';

class FairnessScreen extends StatelessWidget {
  const FairnessScreen({
    super.key,
    required this.groupId,
    required this.projectId,
  });

  final String groupId;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    // TODO: Conectar con datos reales del proyecto
    final members = <_MemberFairness>[
      _MemberFairness('1', 'Ana López', true, false, 40, 12, 30, 10),
      _MemberFairness('2', 'Carlos Ruiz', false, false, 35, 15, 30, 10),
      _MemberFairness('3', 'María Torres', false, false, 25, 8, 30, 10),
      _MemberFairness('4', 'Juan Pérez', false, false, 20, 5, 30, 10),
      _MemberFairness('5', 'Laura Martín', false, false, 0, 0, 30, 10),
    ];

    final totalPoints = members.fold(0, (sum, m) => sum + m.assignedPoints);
    final fairShare = members.isEmpty ? 0 : totalPoints / members.length;
    final fairShareHours = members.isEmpty ? 0 : members.fold(0, (sum, m) => sum + m.assignedHours) / members.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de equidad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                  'La cuota justa = puntos totales / nº miembros. Se avisa si alguien supera +20%.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Gráfico de barras - Puntos
          SectionDivider(label: 'Puntos asignados por miembro'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 280,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (members.map((m) => m.assignedPoints).reduce((a, b) => a > b ? a : b) * 1.3).toDouble(),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < members.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                members[value.toInt()].name.split(' ').first,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
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
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).dividerColor,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: members.asMap().entries.map((entry) {
                    final index = entry.key;
                    final member = entry.value;
                    final isOverQuota = member.assignedPoints > fairShare * 1.2;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: member.assignedPoints.toDouble(),
                          width: 28,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          color: isOverQuota ? Colors.red : Theme.of(context).colorScheme.primary,
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: fairShare.toDouble(),
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
          SectionDivider(label: 'Horas estimadas por miembro'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 280,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (members.map((m) => m.assignedHours).reduce((a, b) => a > b ? a : b) * 1.3).toDouble(),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < members.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                members[value.toInt()].name.split(' ').first,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
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
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).dividerColor,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: members.asMap().entries.map((entry) {
                    final index = entry.key;
                    final member = entry.value;
                    final isOverQuota = member.assignedHours > fairShareHours * 1.2;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: member.assignedHours.toDouble(),
                          width: 28,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          color: isOverQuota ? Colors.red : context.success,
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: fairShareHours.toDouble(),
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

          // Tabla detallada
          SectionDivider(label: 'Detalle por miembro'),
          const SizedBox(height: 8),
          ...members.map((m) => _MemberFairnessTile(
            member: m,
            fairSharePoints: fairShare.toDouble(),
            fairShareHours: fairShareHours.toDouble(),
          )),
        ],
      ),
    );
  }
}

class _MemberFairness {
  final String id;
  final String name;
  final bool isLeader;
  final bool isTeacher;
  final int assignedPoints;
  final int assignedHours;
  final int fairSharePoints;
  final int fairShareHours;

  _MemberFairness(
    this.id,
    this.name,
    this.isLeader,
    this.isTeacher,
    this.assignedPoints,
    this.assignedHours,
    this.fairSharePoints,
    this.fairShareHours,
  );
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
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
    final pointsOver = member.assignedPoints > fairSharePoints * 1.2;
    final hoursOver = member.assignedHours > fairShareHours * 1.2;
    final hasWarning = pointsOver || hoursOver;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(name: member.name, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (member.isTeacher)
                          StatusChip(label: 'Docente', status: StatusType.info),
                        if (member.isLeader)
                          StatusChip(label: 'Jefe', status: StatusType.success),
                      ],
                    ),
                    if (hasWarning) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
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
            const SizedBox(width: 8),
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