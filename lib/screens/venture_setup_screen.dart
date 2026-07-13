import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_opportunity_screen.dart';

class VentureSetupScreen extends StatefulWidget {
  const VentureSetupScreen({super.key});

  @override
  State<VentureSetupScreen> createState() => _VentureSetupScreenState();
}

class _VentureSetupScreenState extends State<VentureSetupScreen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  String? _errorMessage;
  bool _isSaving = false;

  Future<void> _saveVenture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final name = _nameController.text.trim();
    final about = _aboutController.text.trim();

    if (name.isEmpty || about.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in both fields';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance.collection('startups').add({
        'name': name,
        'description': about,
        'ownerId': user.uid,
        'verified': false,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PostOpportunityScreen()),
        );
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
      appBar: AppBar(title: const Text('Set Up Your Venture')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Before posting, tell us about your venture or startup.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Venture Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _aboutController,
              decoration: const InputDecoration(labelText: 'About your venture'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveVenture,
                    child: const Text('Continue'),
                  ),
          ],
        ),
      ),
    );
  }
}