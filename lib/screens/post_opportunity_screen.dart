import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_logo_title.dart';

class PostOpportunityScreen extends StatefulWidget {
  const PostOpportunityScreen({super.key});

  @override
  State<PostOpportunityScreen> createState() => _PostOpportunityScreenState();
}

class _PostOpportunityScreenState extends State<PostOpportunityScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _timeCommitmentController = TextEditingController();
  final _skillsController = TextEditingController();
  String? _errorMessage;
  bool _isSaving = false;

  Future<void> _postOpportunity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    final timeCommitment = _timeCommitmentController.text.trim();
    final skills = _skillsController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in the title and description';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final startupQuery = await FirebaseFirestore.instance
          .collection('startups')
          .where('ownerId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (startupQuery.docs.isEmpty) {
        setState(() {
          _errorMessage = 'Venture profile not found';
          _isSaving = false;
        });
        return;
      }

      final startupDoc = startupQuery.docs.first;

      await FirebaseFirestore.instance.collection('opportunities').add({
        'title': title,
        'description': description,
        'location': location,
        'timeCommitment': timeCommitment,
        'skills': skills,
        'startupId': startupDoc.id,
        'startupName': startupDoc.data()['name'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const AppLogoTitle(pageName: 'Post Opportunity'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Opportunity Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (e.g. On campus, Remote)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeCommitmentController,
              decoration: const InputDecoration(
                labelText: 'Time Commitment (e.g. 6 hours/week)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _skillsController,
              decoration: const InputDecoration(
                labelText: 'Skills Needed (e.g. Canva, communication)',
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            _isSaving
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _postOpportunity,
                      child: const Text('Post Opportunity'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}