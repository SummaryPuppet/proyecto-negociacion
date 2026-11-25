import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:repartojusto/features/offers/aplication/offer_providers.dart';
import 'package:repartojusto/features/offers/domain/offer.dart';
import 'package:repartojusto/features/groups/application/group_providers.dart';
import 'package:repartojusto/features/groups/domain/approval_config.dart';
import 'package:repartojusto/core/widgets/common_widgets.dart';
import 'package:repartojusto/core/utils/utils.dart';
import 'package:repartojusto/features/auth/application/auth_providers.dart';
import 'package:repartojusto/core/errors/app_error.dart';

class OfferList extends ConsumerWidget {
  final String groupId;
  final String projectId;
  final String taskId;

  const OfferList({
    super.key,
    required this.groupId,
    required this.projectId,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersProvider((
      groupId: groupId,
      projectId: projectId,
      taskId: taskId,
    )));

    final isLeader = ref.watch(isGroupLeaderProvider(groupId));
    final isTeacher = ref.watch(isGroupTeacherProvider(groupId));
    final approvalConfig = ref.watch(groupApprovalConfigProvider(groupId));

    return offersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorScreen(
        message: 'Error cargando ofertas: $error',
        onRetry: () => ref.invalidate(offersProvider((
          groupId: groupId,
          projectId: projectId,
          taskId: taskId,
        ))),
      ),
      data: (offers) {
        if (offers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Aún no hay ofertas para esta tarea.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Ofertas de la tarea',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...offers.map((offer) => _OfferCard(
                  offer: offer,
                  groupId: groupId,
                  projectId: projectId,
                  taskId: taskId,
                  isLeader: isLeader,
                  isTeacher: isTeacher,
                  approvalConfig: approvalConfig,
                )),
          ],
        );
      },
    );
  }
}

class _OfferCard extends ConsumerStatefulWidget {
  final Offer offer;
  final String groupId;
  final String projectId;
  final String taskId;
  final bool isLeader;
  final bool isTeacher;
  final ApprovalConfig? approvalConfig;

  const _OfferCard({
    required this.offer,
    required this.groupId,
    required this.projectId,
    required this.taskId,
    required this.isLeader,
    required this.isTeacher,
    this.approvalConfig,
  });

  @override
  ConsumerState<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends ConsumerState<_OfferCard> {
  bool _voting = false;

  Future<void> _handleVote(String vote) async {
    if (_voting) return;

    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    setState(() => _voting = true);

    try {
      final result = await ref.read(offerRepositoryProvider).voteOffer(
            groupId: widget.groupId,
            projectId: widget.projectId,
            taskId: widget.taskId,
            offerId: widget.offer.id,
            voterId: user.uid,
            vote: vote,
            isLeader: widget.isLeader,
            isTeacher: widget.isTeacher,
          );

      if (!mounted) return;

      result.fold(
        onSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voto registrado: ${vote == 'approve' ? 'A favor' : 'En contra'}')),
          );
        },
        onError: (error) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        ),
      );
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Future<void> _handleApprove() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Aprobar oferta',
      message: '¿Confirmas aprobar esta oferta? Se asignará la tarea y se rechazarán las demás.',
      confirmText: 'Aprobar',
    );

    if (!confirmed) return;

    try {
      final result = await ref.read(offerRepositoryProvider).approveOffer(
            groupId: widget.groupId,
            projectId: widget.projectId,
            taskId: widget.taskId,
            offerId: widget.offer.id,
            approverId: user.uid,
            isLeader: widget.isLeader,
            isTeacher: widget.isTeacher,
          );

      if (!mounted) return;

      result.fold(
        onSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Oferta aprobada y tarea asignada')),
          );
        },
        onError: (error) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleForceAssign() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asignación Forzada'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Motivo (obligatorio)',
            hintText: 'Explica por qué fuerzas esta asignación',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Forzar'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    try {
      final result = await ref.read(offerRepositoryProvider).forceAssignOffer(
            groupId: widget.groupId,
            projectId: widget.projectId,
            taskId: widget.taskId,
            offerId: widget.offer.id,
            teacherId: user.uid,
            reason: reasonController.text.trim(),
          );

      if (!mounted) return;

      result.fold(
        onSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚡ Asignación forzada registrada')),
          );
        },
        onError: (error) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleAcceptCounterOffer() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Aceptar contraoferta',
      message: '¿Aceptas esta contraoferta? Se asignará la tarea al autor de la contraoferta.',
      confirmText: 'Aceptar',
    );

    if (!confirmed) return;

    try {
      final result = await ref.read(offerRepositoryProvider).acceptCounterOffer(
            groupId: widget.groupId,
            projectId: widget.projectId,
            taskId: widget.taskId,
            counterOfferId: widget.offer.id,
            studentId: user.uid,
          );

      if (!mounted) return;

      result.fold(
        onSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Contraoferta aceptada')),
          );
        },
        onError: (error) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleRejectCounterOffer() async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Rechazar contraoferta',
      message: '¿Rechazas esta contraoferta? La oferta original seguirá en votación.',
      confirmText: 'Rechazar',
      isDestructive: true,
    );

    if (!confirmed) return;

    try {
      final result = await ref.read(offerRepositoryProvider).rejectCounterOffer(
            groupId: widget.groupId,
            projectId: widget.projectId,
            taskId: widget.taskId,
            counterOfferId: widget.offer.id,
            studentId: user.uid,
          );

      if (!mounted) return;

      result.fold(
        onSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraoferta rechazada')),
          );
        },
        onError: (error) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleMakeCounterOffer() async {
    context.pushNamed(
      'newOffer',
      extra: {
        'groupId': widget.groupId,
        'projectId': widget.projectId,
        'taskId': widget.taskId,
        'parentOfferId': widget.offer.id,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final isCounterOffer = offer.isCounterOffer;
    final canVote = offer.isPending && !offer.isCounterOffer;
    final canMakeCounterOffer = offer.isPending && (widget.isLeader || widget.isTeacher);

    // Calcular puntuación ponderada
    int score = 0;
    offer.votes.forEach((uid, vote) {
      int weight = 1;
      // Aquí se podría verificar si el uid es líder/docente para dar peso doble
      if (vote == 'approve') {
        score += weight;
      } else {
        score -= weight;
      }
    });

    final statusColor = switch (offer.status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      'forced' => Colors.orange,
      'countered' => Colors.blue,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con autor y estado
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _AuthorName(uid: offer.authorId),
                          if (isCounterOffer) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: const Text('Contraoferta'),
                              backgroundColor: Colors.blue.shade50,
                              labelStyle: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      if (offer.parentOfferId != null)
                        Text(
                          'Responde a: ${offer.parentOfferId!.substring(0, 8)}...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    _statusLabel(offer.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Detalles de la oferta
            Text('Puntos: ${offer.points} | Horas: ${offer.hours}'),
            Text('Argumento: ${offer.argument}'),
            const SizedBox(height: 8),

            // Votos y puntuación
            if (offer.votes.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.how_to_vote, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'A favor: ${offer.approveCount} | En contra: ${offer.rejectCount}',
                    style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Puntuación: $score',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // Acciones
            Row(
              children: [
                // Votar
                if (canVote) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _voting ? null : () => _handleVote('approve'),
                      icon: const Icon(Icons.thumb_up, size: 18),
                      label: const Text('A favor'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _voting ? null : () => _handleVote('reject'),
                      icon: const Icon(Icons.thumb_down, size: 18),
                      label: const Text('En contra'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],

                // Aprobar (líder/docente)
                if ((widget.isLeader || widget.isTeacher) && offer.isPending && !isCounterOffer) ...[
                  if (canVote) const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _handleApprove,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Aprobar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],

                // Forzar (docente)
                if (widget.isTeacher && offer.isPending && !isCounterOffer) ...[
                  if (canVote || (widget.isLeader || widget.isTeacher)) const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _handleForceAssign,
                      icon: const Icon(Icons.flash_on, size: 18),
                      label: const Text('Forzar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],

                // Acciones contraoferta
                if (isCounterOffer && offer.isPending) ...[
                  if (canVote || (widget.isLeader || widget.isTeacher) || widget.isTeacher) const SizedBox(width: 8),
                  // Solo el autor de la oferta original puede aceptar/rechazar contraoferta
                  // Esto se verifica en el repositorio
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleAcceptCounterOffer,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aceptar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleRejectCounterOffer,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],

                // Crear contraoferta (líder/docente)
                if (canMakeCounterOffer) ...[
                  if (canVote || (widget.isLeader || widget.isTeacher) || widget.isTeacher) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleMakeCounterOffer,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Contraoferta'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      case 'forced':
        return 'Forzada';
      case 'countered':
        return 'Contraofertada';
      case 'pending':
        return 'Pendiente';
      default:
        return status;
    }
  }
}

/// Widget que muestra el nombre del usuario resolviendo el UID
class _AuthorName extends ConsumerWidget {
  final String uid;

  const _AuthorName({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameAsync = ref.watch(userNameProvider(uid));

    return nameAsync.when(
      data: (name) => Text(
        'Autor: ${name ?? _shortUid(uid)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      loading: () => Text(
        'Autor: ...',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      error: (_, __) => Text(
        'Autor: ${_shortUid(uid)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  String _shortUid(String uid) {
    if (uid.length <= 8) return uid;
    return '${uid.substring(0, 8)}...';
  }
}