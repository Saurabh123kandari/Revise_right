import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../src/core/theme.dart';
import '../../../src/models/note_model.dart';
import '../../../src/providers/notes_provider.dart';
import '../../../src/providers/subject_provider.dart';
import 'add_note_screen.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  final String? subjectId;
  final String? topicId;
  
  const NotesListScreen({
    super.key,
    this.subjectId,
    this.topicId,
  });

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine which provider to use based on filters
    final notesAsync = widget.topicId != null
        ? ref.watch(notesByTopicProvider(widget.topicId!))
        : widget.subjectId != null
            ? ref.watch(notesBySubjectProvider(widget.subjectId!))
            : ref.watch(allNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              if (widget.topicId != null && widget.subjectId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddNoteScreen(
                      topicId: widget.topicId!,
                      subjectId: widget.subjectId!,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                
                // Notes List
                Expanded(
                  child: notesAsync.when(
                    data: (notes) {
                      // Filter notes by search term
                      final filteredNotes = _searchController.text.isEmpty
                          ? notes
                          : notes.where((note) {
                              final searchLower = _searchController.text.toLowerCase();
                              return note.title?.toLowerCase().contains(searchLower) ?? false ||
                                     note.plainTextContent.toLowerCase().contains(searchLower);
                            }).toList();
                      
                      if (filteredNotes.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.note_outlined,
                                  size: 80,
                                  color: AppTheme.primaryGreen.withOpacity(0.3),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'No notes match your search'
                                      : 'No Notes Yet',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'Try a different search term'
                                      : 'Create your first note to get started',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return _buildNoteCard(context, note);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading notes',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddNoteDialog(context);
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildNoteCard(BuildContext context, NoteModel note) {
    final preview = note.plainTextContent.length > 100
        ? '${note.plainTextContent.substring(0, 100)}...'
        : note.plainTextContent;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNoteScreen(
                topicId: note.topicId,
                subjectId: note.subjectId,
                existingNote: note,
              ),
            ),
          );
        },
        child: ListTile(
          title: Text(
            note.title ?? 'Untitled Note',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddNoteScreen(
                      topicId: note.topicId,
                      subjectId: note.subjectId,
                      existingNote: note,
                    ),
                  ),
                );
              } else if (value == 'delete') {
                _showDeleteDialog(context, note);
              }
            },
          ),
        ),
      ),
    );
  }
  
  void _showDeleteDialog(BuildContext context, NoteModel note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(notesControllerProvider).deleteNote(note.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note deleted'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _showAddNoteDialog(BuildContext context) {
    // Check if we have subject and topic already
    if (widget.topicId != null && widget.subjectId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddNoteScreen(
            topicId: widget.topicId!,
            subjectId: widget.subjectId!,
          ),
        ),
      );
      return;
    }
    
    // Otherwise, show dialog to select subject
    final subjectsAsync = ref.read(subjectsProvider);
    subjectsAsync.when(
      data: (subjects) {
        if (subjects.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add a subject first from the Subjects page'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddNoteScreen(
              topicId: '', // Empty for now
              subjectId: subjects.first.id, // Default to first subject
            ),
          ),
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }
}

