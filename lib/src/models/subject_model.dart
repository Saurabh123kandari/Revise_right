import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectModel {
  final String id;
  final String name;
  final String color;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  
  const SubjectModel({
    required this.id,
    required this.name,
    required this.color,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });
  
  // Validation: Name cannot be empty, color must be valid hex format
  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    // Validate name
    final name = map['name'] ?? '';
    if (name.trim().isEmpty) {
      throw ArgumentError('Subject name cannot be empty');
    }
    
    // Validate color format (basic hex color validation)
    final color = map['color'] ?? '#5FC8A5';
    if (!_isValidHexColor(color)) {
      throw ArgumentError('Invalid color format, expected hex color like #RRGGBB, got: $color');
    }
    
    return SubjectModel(
      id: map['id'] ?? '',
      name: name.trim(),
      color: color,
      description: map['description'],
      createdAt: map['createdAt'] != null 
        ? (map['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
        ? (map['updatedAt'] as Timestamp).toDate()
        : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }
  
  // Validation: Ensure name is not empty and color is valid
  SubjectModel copyWith({
    String? id,
    String? name,
    String? color,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    // Validate name if provided
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('Subject name cannot be empty');
    }
    
    // Validate color if provided
    if (color != null && !_isValidHexColor(color)) {
      throw ArgumentError('Invalid color format, expected hex color like #RRGGBB, got: $color');
    }
    
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
  
  // Helper method to validate hex color format
  static bool _isValidHexColor(String color) {
    final hexColorRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return hexColorRegex.hasMatch(color);
  }
  
  @override
  String toString() {
    return 'SubjectModel(id: $id, name: $name, color: $color, isActive: $isActive)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubjectModel && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}