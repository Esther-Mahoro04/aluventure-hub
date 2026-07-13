import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicantsScreen extends StatelessWidget {
  final String opportunityId;
  final String opportunityTitle;

  const ApplicantsScreen({
    super.key,
    required this.opportunityId,
    required this.opportunityTitle,
  });

  Future<void> _updateStatus(
      BuildContext context, String applicationId, String studentId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .update({'status': newStatus});

      if (studentId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': studentId,
          'message': 'Your application for "$opportunityTitle" was $newStatus',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application $newStatus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applicants')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('opportunityId', isEqualTo: opportunityId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No applicants yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final email = data['studentEmail']?.toString() ?? 'Unknown';
              final status = data['status']?.toString() ?? 'pending';
              final studentId = data['studentId']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(email),
                    Text('Status: $status'),
                    const SizedBox(height: 8),
                    if (status == 'pending')
                      ElevatedButton(
                        onPressed: () =>
                            _updateStatus(context, doc.id, studentId, 'accepted'),
                        child: const Text('Accept'),
                      ),
                    if (status == 'pending')
                      const SizedBox(height: 8),
                    if (status == 'pending')
                      ElevatedButton(
                        onPressed: () =>
                            _updateStatus(context, doc.id, studentId, 'rejected'),
                        child: const Text('Reject'),
                      ),
                    const Divider(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}