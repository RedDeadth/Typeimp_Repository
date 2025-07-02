// lib/View/AppCategory.dart
import 'package:flutter/material.dart'; // Necesario para Color si lo usas directamente

class AppCategory {
  final String? userId; // Ahora es anulable
  final String categoryId; // Usando 'categoryId' como identificador
  String name;
  final String color;
  final String? createdAt; // Ahora es anulable
  String? updatedAt; // Ahora es anulable

  AppCategory({
    this.userId, // Ya no es 'required'
    required this.categoryId,
    required this.name,
    required this.color,
    this.createdAt, // Ya no es 'required'
    this.updatedAt, // Ya no es 'required'
  });

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    return AppCategory(
      userId: json['userId'] as String?,
      categoryId: json['categoryId'] as String, // Mapea 'categoryId' del JSON
      name: json['name'] as String,
      color: json['color'] as String,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'categoryId': categoryId, // Mapea 'categoryId' de la propiedad
      'name': name,
      'color': color,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Método para convertir el string de color hex a un objeto Color de Flutter
  Color toColor() {
    String hexColor = color.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor'; // Añade opacidad si falta
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}