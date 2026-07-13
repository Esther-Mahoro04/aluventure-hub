import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'applicants_screen.dart';
import '../widgets/app_logo_title.dart';

class MyOpportunitiesScreen extends StatelessWidget {
  const MyOpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const AppLogoTitle(pageName: 'My Opportunities'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('startups')
            .where('ownerId', isEqualTo: user?.uid)
            .limit(1)
            .get(),
        builder: (context, startupSnapshot) {
          if (startupSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (startupSnapshot.hasError) {
            return Center(child: Text('Error: ${startupSnapshot.error}'));
          }

          if (!startupSnapshot.hasData || startupSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'You have not set up a venture yet. Tap the + button on Home to create one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final startupId = startupSnapshot.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('opportunities')
                .where('startupId', isEqualTo: startupId)
                .snapshots(),
            builder: (context, oppSnapshot) {
              if (oppSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (oppSnapshot.hasError) {
                return Center(child: Text('Error: ${oppSnapshot.error}'));
              }

              if (!oppSnapshot.hasData || oppSnapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('You have not posted any opportunities yet.'));
              }

              final opportunities = oppSnapshot.data!.docs;

              return ListView.builder(
                itemCount: opportunities.length,
                itemBuilder: (context, index) {
                  final doc = opportunities[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] ?? '';

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(title),
                      subtitle: Text(data['description'] ?? ''),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ApplicantsScreen(
                                opportunityId: doc.id,
                                opportunityTitle: title,
                              ),
                            ),
                          );
                        },
                        child: const Text('View Applicants'),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}