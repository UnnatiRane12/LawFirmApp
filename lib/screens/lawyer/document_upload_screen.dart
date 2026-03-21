import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../utils/security_utils.dart';
import '../../services/supabase_service.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String caseId;
  const DocumentUploadScreen({super.key, required this.caseId});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _supabase = SupabaseService.client;
  PlatformFile? _selectedFile;
  final _passwordController = TextEditingController();
  bool _isProtected = false;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null) return;
    
    setState(() => _isUploading = true);
    try {
      String? passwordHash;
      if (_isProtected && _passwordController.text.isNotEmpty) {
        passwordHash = DocumentSecuritySync.hashPassword(_passwordController.text);
      }

      // 1. Upload to Supabase Storage
      final fileExtension = _selectedFile!.extension;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final path = 'cases/${widget.caseId}/$fileName';

      await _supabase.storage.from('legal_docs').uploadBinary(
        path,
        _selectedFile!.bytes!,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // 2. Save Metadata to DB
      await _supabase.from('documents').insert({
        'case_id': widget.caseId,
        'file_name': _selectedFile!.name,
        'file_path': path,
        'password_hash': passwordHash,
        'uploader_id': _supabase.auth.currentUser!.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            InkWell(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload, size: 48, color: AppConstants.accentColor),
                    const SizedBox(height: 16),
                    Text(_selectedFile?.name ?? 'Select PDF or Image', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SwitchListTile(
              title: const Text('Password Protect Document'),
              subtitle: const Text('Only accessible with password'),
              value: _isProtected,
              onChanged: (val) => setState(() => _isProtected = val),
            ),
            if (_isProtected)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Document Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_selectedFile != null && !_isUploading) ? _upload : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.secondaryColor),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Start Upload', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
