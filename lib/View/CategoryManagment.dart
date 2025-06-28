import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:convert';
import 'AppCategory.dart'; // *** IMPORTACIÓN ACTUALIZADA ***

class CategoryManagementScreen extends StatefulWidget {
  final VoidCallback onCategoriesUpdated;

  const CategoryManagementScreen({
    super.key,
    required this.onCategoriesUpdated,
  });

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<AppCategory> _categories = []; // *** CAMBIADO A AppCategory ***
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
    });
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
          _categories.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        });
      } else {
        safePrint('Failed to load categories: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: ${response.decodeBody()}')),
        );
      }
    } on ApiException catch (e) {
      safePrint('GET /categories failed: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de API: ${e.message}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addCategory() async {
    final String? newCategoryName = await _showCategoryInputDialog(context, 'Añadir Categoría', '');
    if (newCategoryName != null && newCategoryName.isNotEmpty) {
      try {
        final restOperation = Amplify.API.post(
          '/categories',
          apiName: 'notesApi',
          body: HttpPayload.json({'name': newCategoryName}),
        );
        final response = await restOperation.response;
        safePrint('POST /categories response: ${response.statusCode} - ${response.decodeBody()}');
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoría creada con éxito!')),
          );
          await _fetchCategories();
          widget.onCategoriesUpdated();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear categoría: ${response.decodeBody()}')),
          );
        }
      } on ApiException catch (e) {
        safePrint('POST /categories failed: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de API: ${e.message}')),
        );
      }
    }
  }

  Future<void> _editCategory(AppCategory category) async { // *** CAMBIADO A AppCategory ***
    final String? updatedCategoryName = await _showCategoryInputDialog(context, 'Editar Categoría', category.name);
    if (updatedCategoryName != null && updatedCategoryName.isNotEmpty) {
      try {
        final restOperation = Amplify.API.put(
          '/categories/${category.categoryId}',
          apiName: 'notesApi',
          body: HttpPayload.json({'name': updatedCategoryName}),
        );
        final response = await restOperation.response;
        safePrint('PUT /categories/${category.categoryId} response: ${response.statusCode} - ${response.decodeBody()}');
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoría actualizada con éxito!')),
          );
          await _fetchCategories();
          widget.onCategoriesUpdated();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar categoría: ${response.decodeBody()}')),
          );
        }
      } on ApiException catch (e) {
        safePrint('PUT /categories/${category.categoryId} failed: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de API: ${e.message}')),
        );
      }
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar esta categoría? Todas las notas asociadas a ella también serán eliminadas.'),
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
          '/categories/$categoryId',
          apiName: 'notesApi',
        );
        final response = await restOperation.response;
        safePrint('DELETE /categories/$categoryId response: ${response.statusCode} - ${response.decodeBody()}');
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoría y notas asociadas eliminadas con éxito!')),
          );
          await _fetchCategories();
          widget.onCategoriesUpdated();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar categoría: ${response.decodeBody()}')),
          );
        }
      } on ApiException catch (e) {
        safePrint('DELETE /categories/$categoryId failed: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de API: ${e.message}')),
        );
      }
    }
  }

  Future<String?> _showCategoryInputDialog(BuildContext context, String title, String initialValue) async {
    TextEditingController controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nombre de la categoría'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Categorías'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No tienes categorías aún.'),
                      Text('Crea una nueva para organizar tus notas.'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(category.name),
                        subtitle: Text('ID: ${category.categoryId}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editCategory(category),
                            ),
                            if (category.categoryId != 'Uncategorized' && category.name.toLowerCase() != 'uncategorized')
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteCategory(category.categoryId),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
        tooltip: 'Añadir nueva categoría',
      ),
    );
  }
}
