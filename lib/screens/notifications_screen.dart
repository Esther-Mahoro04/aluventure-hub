import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_logo_title.dart';
import 'applicants_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const AppLogoTitle(pageName: 'Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final read = data['read'] ?? false;
              final type = data['type'] ?? '';
              final opportunityId = data['opportunityId'];
              final opportunityTitle = data['opportunityTitle'] ?? '';

              return ListTile(
                leading: Icon(
                  read ? Icons.notifications_none : Icons.notifications,
                  color: read ? Colors.grey : Colors.blue,
                ),
                title: Text(data['message'] ?? ''),
                trailing: (type == 'application' && opportunityId != null)
                    ? const Icon(Icons.chevron_right)
                    : null,
                tileColor: read ? null : Colors.blue.withOpacity(0.05),
                onTap: () {
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(doc.id)
                      .update({'read': true});

                  if (type == 'application' && opportunityId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ApplicantsScreen(
                          opportunityId: opportunityId,
                          opportunityTitle: opportunityTitle,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}