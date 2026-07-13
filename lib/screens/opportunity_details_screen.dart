import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_logo_title.dart';

class OpportunityDetailsScreen extends StatefulWidget {
  final String opportunityId;
  final Map<String, dynamic> data;

  const OpportunityDetailsScreen({
    super.key,
    required this.opportunityId,
    required this.data,
  });

  @override
  State<OpportunityDetailsScreen> createState() => _OpportunityDetailsScreenState();
}

class _OpportunityDetailsScreenState extends State<OpportunityDetailsScreen> {
  bool _isOwner = false;
  bool _isSaved = false;
  bool _checkingOwnership = true;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
    _checkIfSaved();
  }

  Future<void> _checkOwnership() async {
    final user = FirebaseAuth.instance.currentUser;
    final startupId = widget.data['startupId'];
    if (user == null || startupId == null) {
      setState(() => _checkingOwnership = false);
      return;
    }

    final startupDoc = await FirebaseFirestore.instance
        .collection('startups')
        .doc(startupId)
        .get();
    final ownerId = startupDoc.data()?['ownerId'];

    setState(() {
      _isOwner = ownerId == user.uid;
      _checkingOwnership = false;
    });
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('bookmarks')
        .doc('${user.uid}_${widget.opportunityId}')
        .get();

    if (mounted) {
      setState(() {
        _isSaved = doc.exists;
      });
    }
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('bookmarks')
        .doc('${user.uid}_${widget.opportunityId}');

    if (_isSaved) {
      await ref.delete();
    } else {
      await ref.set({
        'userId': user.uid,
        'opportunityId': widget.opportunityId,
        'opportunityTitle': widget.data['title'] ?? '',
        'startupName': widget.data['startupName'] ?? '',
        'savedAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      _isSaved = !_isSaved;
    });
  }

  Future<void> _applyToOpportunity(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title = widget.data['title'] ?? '';

    try {
      final existing = await FirebaseFirestore.instance
          .collection('applications')
          .where('studentId', isEqualTo: user.uid)
          .where('opportunityId', isEqualTo: widget.opportunityId)
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

      final startupId = widget.data['startupId'];

      await FirebaseFirestore.instance.collection('applications').add({
        'studentId': user.uid,
        'studentEmail': user.email,
        'opportunityId': widget.opportunityId,
        'opportunityTitle': title,
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      if (startupId != null) {
        final startupDoc = await FirebaseFirestore.instance
            .collection('startups')
            .doc(startupId)
            .get();
        final ownerId = startupDoc.data()?['ownerId'];

        if (ownerId != null) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': ownerId,
            'message': 'New application for "$title" from ${user.email}',
            'type': 'application',
            'opportunityId': widget.opportunityId,
            'opportunityTitle': title,
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

  Widget _detailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title'] ?? '';
    final startupName = widget.data['startupName'] ?? 'Unknown';
    final description = widget.data['description'] ?? '';
    final location = widget.data['location'] ?? '';
    final timeCommitment = widget.data['timeCommitment'] ?? '';
    final skills = widget.data['skills'] ?? '';

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const AppLogoTitle(pageName: 'Opportunity'),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleSave,
            tooltip: _isSaved ? 'Remove from saved' : 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'By $startupName',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _detailRow(Icons.location_on_outlined, 'Location', location),
            _detailRow(Icons.schedule_outlined, 'Time Commitment', timeCommitment),
            _detailRow(Icons.star_outline, 'Skills Needed', skills),
            const SizedBox(height: 12),
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 32),
            if (!_checkingOwnership && !_isOwner)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _applyToOpportunity(context),
                  child: const Text('Apply'),
                ),
              ),
            if (!_checkingOwnership && _isOwner)
              const Text(
                'This is your own posting.',
                style: TextStyle(color: Colors.black45, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }
}