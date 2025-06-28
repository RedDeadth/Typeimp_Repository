import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'AuthScreen.dart'; 
import 'dart:convert';
import 'Note.dart'; 
import 'AppCategory.dart'; 
import 'CategoryManagment.dart';
import 'AddEditNoteDialog.dart';

// AddEditNoteDialog - Si está en un archivo separado, asegúrate de importarlo aquí
// import 'AddEditNoteDialog.dart'; // Descomenta si AddEditNoteDialog está en un archivo separado

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  List<AppCategory> _categories = []; // *** CAMBIADO A AppCategory ***
  bool _isLoading = true;
  String _selectedCategoryFilter = 'All'; // Para filtrar por categoría (ID o nombre)

  @override
  void initState() {
    super.initState();
    _initializeAppAndFetchData();
  }

  Future<void> _initializeAppAndFetchData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([
      _fetchCategories(),
      _fetchNotes(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await Amplify.Auth.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    } on AuthException catch (e) {
      safePrint('Error al cerrar sesión: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: ${e.message}')),
      );
    }
  }

  // --- Métodos para Categorías ---
  Future<void> _fetchCategories() async {
    try {
      final restOperation = Amplify.API.get(
        '/categories',
        apiName: 'notesApi',
      );
      final response = await restOperation.response;
      safePrint('GET /categories response: ${response.statusCode} - ${response.decodeBody()}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.decodeBody());
        final List<dynamic> categoriesJson = responseBody['categories'];
        setState(() {
          _categories = categoriesJson.map((json) => AppCategory.fromJson(json)).toList(); // *** CAMBIADO A AppCategory ***
        });
      } else {
        safePrint('Failed to load categories: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      safePrint('GET /categories failed: ${e.message}');
    }
  }

  Future<void> _manageCategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryManagementScreen( // *** Ya no es "método", sino clase ***
          onCategoriesUpdated: _fetchCategories,
        ),
      ),
    );
    _fetchNotes(); 
  }

  // --- Métodos para Notas (con actualizaciones para categoría) ---
  Future<void> _fetchNotes() async {
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
          _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      } else {
        safePrint('Failed to load notes: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar notas: ${response.decodeBody()}')),
        );
      }
    } on ApiException catch (e) {
      safePrint('GET failed: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de API: ${e.message}')),
      );
    }
  }

  Future<void> _addNote() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddEditNoteDialog( // *** Ya no es "método", sino clase ***
        initialTitle: '',
        initialContent: '',
        initialCategory: 'Uncategorized',
        isEdit: false,
        availableCategories: _categories,
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
          _fetchNotes();
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
      builder: (context) => AddEditNoteDialog( // *** Ya no es "método", sino clase ***
        initialTitle: note.title,
        initialContent: note.content,
        initialCategory: note.categoryId,
        isEdit: true,
        availableCategories: _categories,
      ),
    );

    if (result != null) {
      try {
        final restOperation = Amplify.API.put(
          '/notes/${note.noteId}',
          apiName: 'notesApi',
          body: HttpPayload.json(result),
        );
        final response = await restOperation.response;
        safePrint('PUT /notes/${note.noteId} response: ${response.statusCode} - ${response.decodeBody()}');
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nota actualizada con éxito!')),
          );
          _fetchNotes();
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
          _fetchNotes();
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
    if (_selectedCategoryFilter == 'All') {
      return _notes;
    }
    return _notes.where((note) => note.categoryId == _selectedCategoryFilter).toList();
  }


  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<String>> categoryFilterItems = [
      const DropdownMenuItem<String>(value: 'All', child: Text('Todas las Categorías')),
      // Asegúrate de que 'Uncategorized' esté en la lista si no viene del backend
      // Esto es crucial para notas antiguas que no tienen categoryId o tienen 'Uncategorized'
      const DropdownMenuItem<String>(value: 'Uncategorized', child: Text('Sin Categoría')),
      ..._categories.map<DropdownMenuItem<String>>((AppCategory category) { // *** CAMBIADO A AppCategory ***
        return DropdownMenuItem<String>(
          value: category.categoryId,
          child: Text(category.name),
        );
      }),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas App (Bienvenido!)'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategoryFilter,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategoryFilter = newValue!;
                });
              },
              items: categoryFilterItems,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Gestionar Categorías',
            onPressed: _manageCategories,
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
                      final categoryName = _categories
                              .firstWhere(
                                (cat) => cat.categoryId == note.categoryId,
                                orElse: () => AppCategory(userId: '', categoryId: 'Uncategorized', name: 'Sin Categoría', createdAt: '', updatedAt: ''), // *** CAMBIADO A AppCategory ***
                              )
                              .name;

                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(note.title),
                          subtitle: Text('${note.content}\nCategoría: $categoryName'),
                          isThreeLine: true,
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
                          onTap: () {
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
