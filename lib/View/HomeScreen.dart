import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'AuthScreen.dart';
import 'dart:convert';
import 'Note.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  bool _isLoading = true;
  String _selectedCategory = 'All'; // Para filtrar por categoría
  // Listado de categorías disponibles (podrías obtenerlas dinámicamente)
  final List<String> _categories = ['All', 'Work', 'Personal', 'Ideas', 'Uncategorized'];

  @override
  void initState() {
    super.initState();
    _fetchNotes(); // Cargar notas al iniciar la pantalla
  }

  Future<void> _signOut(BuildContext context) async {
    // ... tu código de signOut existente
    try {
      await Amplify.Auth.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    } on AuthException catch (e) {
      safePrint('Error al cerrar sesión: ${e.message}');
    }
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final restOperation = Amplify.API.get(
        '/notes',
        apiName: 'notesApi',
      );
      final response = await restOperation.response;
      safePrint('GET /notes response: ${response.statusCode} - ${response.decodeBody()}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.decodeBody());
        final List<dynamic> notesJson = responseBody['notes'];
        setState(() {
          _notes = notesJson.map((json) => Note.fromJson(json)).toList();
          // Ordenar por fecha de creación por defecto (más reciente primero)
          _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      } else {
        safePrint('Failed to load notes: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      safePrint('GET failed: ${e.message}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addNote() async {
    // Implementar un showDialog o showModalBottomSheet con un formulario
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddEditNoteDialog(
        initialTitle: '',
        initialContent: '',
        initialCategory: 'Uncategorized',
        isEdit: false,
      ),
    );

    if (result != null) {
      try {
        final restOperation = Amplify.API.post(
          '/notes',
          apiName: 'notesApi',
          body: HttpPayload.json(result), 
        );
        final response = await restOperation.response;
        safePrint('POST /notes response: ${response.statusCode} - ${response.decodeBody()}');
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nota creada con éxito!')),
          );
          _fetchNotes(); // Recargar notas
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear nota: ${response.decodeBody()}')),
          );
        }
      } on ApiException catch (e) {
        safePrint('POST failed: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de API: ${e.message}')),
        );
      }
    }
  }

  Future<void> _editNote(Note note) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddEditNoteDialog(
        initialTitle: note.title,
        initialContent: note.content,
        initialCategory: note.categoryId,
        isEdit: true,
      ),
    );

    if (result != null) {
      try {
        final restOperation = Amplify.API.put(
          '/notes/${note.noteId}', // Usar el ID de la nota
          apiName: 'notesApi',
          body: HttpPayload.json(result),
        );
        final response = await restOperation.response;
        safePrint('PUT /notes/${note.noteId} response: ${response.statusCode} - ${response.decodeBody()}');
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nota actualizada con éxito!')),
          );
          _fetchNotes(); // Recargar notas
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar nota: ${response.decodeBody()}')),
          );
        }
      } on ApiException catch (e) {
        safePrint('PUT failed: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de API: ${e.message}')),
        );
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta nota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final restOperation = Amplify.API.delete(
          '/notes/$noteId',
          apiName: 'notesApi',
        );
        final response = await restOperation.response;
        safePrint('DELETE /notes/$noteId response: ${response.statusCode} - ${response.decodeBody()}');
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nota eliminada con éxito!')),
          );
          _fetchNotes(); // Recargar notas
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar nota: ${response.decodeBody()}')),
          );
        }
      } on ApiException catch (e) {
        safePrint('DELETE failed: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de API: ${e.message}')),
        );
      }
    }
  }

  // Método para filtrar notas por categoría
  List<Note> get _filteredNotes {
    if (_selectedCategory == 'All') {
      return _notes;
    }
    return _notes.where((note) => note.categoryId == _selectedCategory).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas App (Bienvenido!)'),
        actions: [
          // Dropdown para filtrar por categoría
          DropdownButton<String>(
            value: _selectedCategory,
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue!;
                // Aquí, si tu API soporta filtrar por categoría en el backend,
                // harías una nueva _fetchNotes(categoryId: newValue);
                // Por ahora, solo filtraremos el cliente.
              });
            },
            items: _categories.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('¡Has iniciado sesión con éxito!'),
                      Text('No tienes notas aún. Crea una nueva.'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = _filteredNotes[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(note.title),
                        subtitle: Text(note.content),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editNote(note),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteNote(note.noteId),
                            ),
                          ],
                        ),
                        // Puedes añadir más detalles como categoría y fechas
                        onTap: () {
                          // Opcional: ver detalles completos de la nota
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Dialogo para Añadir/Editar Nota
class AddEditNoteDialog extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final String initialCategory;
  final bool isEdit;

  const AddEditNoteDialog({
    super.key,
    required this.initialTitle,
    required this.initialContent,
    required this.initialCategory,
    required this.isEdit,
  });

  @override
  State<AddEditNoteDialog> createState() => _AddEditNoteDialogState();
}

class _AddEditNoteDialogState extends State<AddEditNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedCategory; // Para el dropdown de categoría

  // Listado de categorías disponibles (debería ser el mismo que en HomeScreen)
  final List<String> _categories = ['Work', 'Personal', 'Ideas', 'Uncategorized'];


  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Editar Nota' : 'Añadir Nueva Nota'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un título';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Contenido'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el contenido de la nota';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'title': _titleController.text,
                'content': _contentController.text,
                'categoryId': _selectedCategory,
              });
            }
          },
          child: Text(widget.isEdit ? 'Guardar Cambios' : 'Añadir Nota'),
        ),
      ],
    );
  }
}