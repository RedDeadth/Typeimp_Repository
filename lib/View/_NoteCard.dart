import 'package:flutter/material.dart';
// Corrección: Si Note.dart está en la misma carpeta (lib/View/), la ruta es solo el nombre.
// Si Note.dart estuviera en 'lib/', la ruta correcta sería '../Note.dart'.
// Dado el error anterior, asumimos que está en la misma carpeta o que la ruta 'package:...' no funciona para archivos no-paquetes.
// Vamos a usar la ruta relativa, que es más robusta para archivos dentro del mismo directorio de vistas.
import 'Note.dart'; // ¡CORRECCIÓN DE RUTA AHORA ES RELATIVA!
import '../utils/app_constants.dart'; // La ruta a app_constants.dart es relativa subiendo un nivel y luego a utils.

class NoteCard extends StatelessWidget {
  final Note note;
  final Function(Note) onEdit;
  final Function(String) onDelete;
  final Color cardColor;
  final String displayCategory;
  final bool isDarkMode;
  final String userName;
  final bool isLoading;

  const NoteCard({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
    required this.cardColor,
    required this.displayCategory,
    this.isDarkMode = false,
    required this.userName,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color titleColor = isDarkMode ? Colors.white : const Color(0xFF333333);
    final Color contentColor = isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;
    final Color dateColor = isDarkMode ? Colors.grey[500]! : Colors.grey[500]!;
    final Color cardBorderColor = isDarkMode ? cardColor.darken(0.3) : cardColor.darken(0.1);
    final Color cardBackground = isDarkMode ? Colors.grey[850]! : Colors.white;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: cardBorderColor,
          width: 2,
        ),
      ),
      color: cardBackground,
      child: Stack(
        children: [
          InkWell(
            onTap: isLoading ? null : () => onEdit(note),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cardColor.darken(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                      fontFamily: 'Montserrat',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      note.content,
                      style: TextStyle(fontSize: 14, color: contentColor, fontFamily: 'Open Sans'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          note.createdAt.substring(0, 10),
                          style: TextStyle(fontSize: 12, color: dateColor, fontFamily: 'Open Sans'),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: null,
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(Icons.edit, size: 20, color: Colors.transparent),
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isLoading ? null : () => onDelete(note.noteId),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(Icons.delete, size: 20, color: isLoading ? Colors.grey : const Color(0xFFEF233C)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF3B30),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}