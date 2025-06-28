

    class AppCategory { // Cambiado de Category a AppCategory
      final String userId;
      final String categoryId;
      String name;
      final String createdAt;
      String updatedAt;

      AppCategory({ // Cambiado de Category a AppCategory
        required this.userId,
        required this.categoryId,
        required this.name,
        required this.createdAt,
        required this.updatedAt,
      });

      // Factory constructor para crear una instancia de AppCategory desde un mapa JSON
      factory AppCategory.fromJson(Map<String, dynamic> json) { // Cambiado de Category a AppCategory
        return AppCategory( // Cambiado de Category a AppCategory
          userId: json['userId'] as String,
          categoryId: json['categoryId'] as String,
          name: json['name'] as String,
          createdAt: json['createdAt'] as String,
          updatedAt: json['updatedAt'] as String,
        );
      }

      // Método para convertir una instancia de AppCategory a un mapa JSON
      Map<String, dynamic> toJson() {
        return {
          'userId': userId,
          'categoryId': categoryId,
          'name': name,
          'createdAt': createdAt,
          'updatedAt': updatedAt,
        };
      }
    }
    