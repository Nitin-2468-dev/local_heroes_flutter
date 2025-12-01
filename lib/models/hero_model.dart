/// Hero model representing a local community hero.
class LocalHero {
  final String id;
  final String name;
  final String field;
  final String bio;
  final String? imageUrl;
  final String? profileImageUrl;
  final String? contactInfo;
  final String? wikiLink;
  final DateTime? keptAt;

  const LocalHero({
    required this.id,
    required this.name,
    required this.field,
    required this.bio,
    this.imageUrl,
    this.profileImageUrl,
    this.contactInfo,
    this.wikiLink,
    this.keptAt,
  });

  /// Create a copy with optional new values.
  LocalHero copyWith({
    String? id,
    String? name,
    String? field,
    String? bio,
    String? imageUrl,
    String? profileImageUrl,
    String? contactInfo,
    String? wikiLink,
    DateTime? keptAt,
  }) {
    return LocalHero(
      id: id ?? this.id,
      name: name ?? this.name,
      field: field ?? this.field,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      contactInfo: contactInfo ?? this.contactInfo,
      wikiLink: wikiLink ?? this.wikiLink,
      keptAt: keptAt ?? this.keptAt,
    );
  }

  /// Get the initials of the hero's name (first 2 characters).
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
  }

  /// Convert to Map for JSON/CSV export.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'field': field,
      'bio': bio,
      'imageUrl': imageUrl,
      'profileImageUrl': profileImageUrl,
      'contactInfo': contactInfo,
      'wikiLink': wikiLink,
      'keptAt': keptAt?.toIso8601String(),
    };
  }

  /// Create from Map.
  factory LocalHero.fromMap(Map<String, dynamic> map) {
    return LocalHero(
      id: map['id'] as String,
      name: map['name'] as String,
      field: map['field'] as String,
      bio: map['bio'] as String,
      imageUrl: map['imageUrl'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      contactInfo: map['contactInfo'] as String?,
      wikiLink: map['wikiLink'] as String?,
      keptAt: map['keptAt'] != null ? DateTime.parse(map['keptAt']) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalHero && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
