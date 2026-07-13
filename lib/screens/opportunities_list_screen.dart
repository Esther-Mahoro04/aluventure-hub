import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OpportunitiesListScreen extends StatelessWidget {
  const OpportunitiesListScreen({super.key});

  Future<void> _applyToOpportunity(
      BuildContext context, String opportunityId, String opportunityTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final existing = await FirebaseFirestore.instance
          .collection('applications')
          .where('studentId', isEqualTo: user.uid)
          .where('opportunityId', isEqualTo: opportunityId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You already applied to this opportunity.')),
          );
        }
        return;
      }

      // Get the opportunity to find the startup owner
      final oppDoc = await FirebaseFirestore.instance
          .collection('opportunities')
          .doc(opportunityId)
          .get();
      final oppData = oppDoc.data();
      final startupId = oppData?['startupId'];

      await FirebaseFirestore.instance.collection('applications').add({
        'studentId': user.uid,
        'studentEmail': user.email,
        'opportunityId': opportunityId,
        'opportunityTitle': opportunityTitle,
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      // Notify the startup owner
      if (startupId != null) {
        final startupDoc = await FirebaseFirestore.instance
            .collection('startups')
            .doc(startupId)
            .get();
        final ownerId = startupDoc.data()?['ownerId'];

        if (ownerId != null) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': ownerId,
            'message': 'New application for "$opportunityTitle" from ${user.email}',
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opportunities')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('opportunities')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No opportunities posted yet.'));
          }

          final opportunities = snapshot.data!.docs;

          return ListView.builder(
            itemCount: opportunities.length,
            itemBuilder: (context, index) {
              final doc = opportunities[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? '';

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text('By ${data['startupName'] ?? 'Unknown'}'),
                      const SizedBox(height: 4),
                      Text(data['description'] ?? ''),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => _applyToOpportunity(context, doc.id, title),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}