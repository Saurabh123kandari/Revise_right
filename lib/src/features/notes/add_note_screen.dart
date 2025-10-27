import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../src/core/theme.dart';
import '../../../src/models/note_model.dart';
import '../../../src/providers/notes_provider.dart';
import '../../../src/providers/subject_provider.dart';
import '../../../src/services/firebase_service.dart';

class AddNoteScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String subjectId;
  final NoteModel? existingNote;
  
  const AddNoteScreen({
    super.key,
    required this.topicId,
    required this.subjectId,
    this.existingNote,
  });

  @override
  ConsumerState<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends ConsumerState<AddNoteScreen> {
  int _selectedMode = 0; // 0 = Plain Text, 1 = Rich Text
  final _plainTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _plainTextController.text = widget.existingNote!.plainTextContent;
      _selectedMode = widget.existingNote!.content.isNotEmpty ? 1 : 0;
    }
  }

  @override
  void dispose() {
    _plainTextController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not authenticated');
      }
      
      final plainText = _plainTextController.text.trim();
      
      // For now, both modes use plain text
      // In full implementation, rich text mode would use Quill Delta
      final richTextContent = _selectedMode == 1 
          ? _convertToQuillDelta(plainText)
          : '';
      
      final now = DateTime.now();
      final note = NoteModel(
        id: widget.existingNote?.id ?? const Uuid().v4(),
        topicId: widget.topicId,
        subjectId: widget.subjectId,
        content: richTextContent,
        plainTextContent: plainText,
        title: _getNoteTitle(plainText),
        createdAt: widget.existingNote?.createdAt ?? now,
        updatedAt: now,
      );
      
      await ref.read(notesControllerProvider).saveNote(note);
      
      if (!mounted) return;
      
      Navigator.pop(context);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingNote == null 
              ? 'Note saved successfully' 
              : 'Note updated successfully'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  String _getNoteTitle(String content) {
    if (content.isEmpty) return 'Untitled Note';
    final lines = content.split('\n');
    final firstLine = lines.first.trim();
    return firstLine.length > 50 
        ? '${firstLine.substring(0, 50)}...' 
        : firstLine;
  }
  
  String _convertToQuillDelta(String plainText) {
    // Simple conversion - in full implementation, use QuillDelta
    return '{"ops":[{"insert":"$plainText\n"}]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingNote == null ? 'Add Note' : 'Edit Note'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeButton('Plain Text', 0),
                _buildModeButton('Rich Text', 1),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: AppTheme.getScaffoldBackgroundColor(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Editor Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => setState(() => _selectedMode = 0),
                            icon: Icon(
                              Icons.text_fields,
                              color: _selectedMode == 0 
                                  ? AppTheme.primaryGreen 
                                  : Colors.grey,
                            ),
                            label: Text(
                              'Plain Text',
                              style: TextStyle(
                                color: _selectedMode == 0 
                                    ? AppTheme.primaryGreen 
                                    : Colors.grey,
                                fontWeight: _selectedMode == 0 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() => _selectedMode = 1),
                            icon: Icon(
                              Icons.format_bold,
                              color: _selectedMode == 1 
                                  ? AppTheme.primaryGreen 
                                  : Colors.grey,
                            ),
                            label: Text(
                              'Rich Text',
                              style: TextStyle(
                                color: _selectedMode == 1 
                                    ? AppTheme.primaryGreen 
                                    : Colors.grey,
                                fontWeight: _selectedMode == 1 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Editor Content
                    Expanded(
                      child: TextFormField(
                        controller: _plainTextController,
                        decoration: InputDecoration(
                          hintText: _selectedMode == 0
                              ? 'Start typing your notes...'
                              : 'Rich text editor (Flutter Quill integration coming soon)',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        expands: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter some content';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Save Note'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildModeButton(String label, int mode) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryGreen 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

