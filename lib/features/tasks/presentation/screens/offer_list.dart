import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OfferList extends StatefulWidget {
  final String projectId;
  final String taskId;
  final bool isGroupLeader;
  final bool isTeacher;

  const OfferList({
    Key? key,
    required this.projectId,
    required this.taskId,
    required this.isGroupLeader,
    required this.isTeacher,
  }) : super(key: key);

  @override
  State<OfferList> createState() => _OfferListState();
}

class _OfferListState extends State<OfferList> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  int _calculateScore(Map<String, dynamic> votes) {
    int score = 0;
    votes.forEach((key, value) {
      int weight = value['weight'] ?? 1;
      if (value['type'] == 'up') {
        score += weight;
      } else {
        score -= weight;
      }
    });
    return score;
  }

  Future<void> _handleVote(String offerId, String voteType, Map<String, dynamic> currentVotes) async {
    if (_user == null) return;

    int weight = widget.isGroupLeader ? 2 : 1;
    Map<String, dynamic> newVotes = Map.from(currentVotes);
    newVotes[_user!.uid] = {'type': voteType, 'weight': weight};

    await _db
        .collection('projects')
        .doc(widget.projectId)
        .collection('tasks')
        .doc(widget.taskId)
        .collection('offers')
        .doc(offerId)
        .update({'votes': newVotes});
  }

  Future<void> _handleApprove(String offerId, String authorId) async {
    await _db
        .collection('projects')
        .doc(widget.projectId)
        .collection('tasks')
        .doc(widget.taskId)
        .update({
      'assigneeId': authorId,
      'status': 'assigned',
      'closedAt': FieldValue.serverTimestamp(),
    });

    await _db
        .collection('projects')
        .doc(widget.projectId)
        .collection('tasks')
        .doc(widget.taskId)
        .collection('offers')
        .doc(offerId)
        .update({'status': 'approved'});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Tarea asignada correctamente')),
    );
  }

  Future<void> _handleForceAssign(String offerId, String authorId) async {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asignación Forzada'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Motivo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              
              await _db
                  .collection('projects')
                  .doc(widget.projectId)
                  .collection('tasks')
                  .doc(widget.taskId)
                  .update({
                'assigneeId': authorId,
                'status': 'forced',
                'forcedReason': reasonController.text,
                'closedAt': FieldValue.serverTimestamp(),
              });

              await _db
                  .collection('projects')
                  .doc(widget.projectId)
                  .collection('tasks')
                  .doc(widget.taskId)
                  .collection('offers')
                  .doc(offerId)
                  .update({'status': 'forced'});

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Forzar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('projects')
          .doc(widget.projectId)
          .collection('tasks')
          .doc(widget.taskId)
          .collection('offers')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Text('Aún no hay ofertas para esta tarea.', style: TextStyle(fontStyle: FontStyle.italic));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Ofertas de la tarea', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...snapshot.data!.docs.map((doc) {
              var offer = doc.data() as Map<String, dynamic>;
              var votes = offer['votes'] as Map<String, dynamic>? ?? {};
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Autor: ${offer['authorId'] ?? "Desconocido"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Puntos: ${offer['points']} | Horas: ${offer['hours']}'),
                      Text('Argumento: ${offer['argument']}'),
                      Text('Puntuación: ${_calculateScore(votes)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _handleVote(doc.id, 'up', votes),
                            child: const Text('👍 A favor'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _handleVote(doc.id, 'down', votes),
                            child: const Text('👎 En contra'),
                          ),
                        ],
                      ),
                      if (widget.isGroupLeader || widget.isTeacher) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _handleApprove(doc.id, offer['authorId']),
                          child: const Text('✅ Aprobar', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                      if (widget.isTeacher) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => _handleForceAssign(doc.id, offer['authorId']),
                          child: const Text('⚡ Forzar', style: TextStyle(color: Colors.white)),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}