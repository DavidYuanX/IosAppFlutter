class Banner {
  final int? id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? backgroundColor;
  final String? textColor;
  final String? linkUrl;
  final int sortOrder;
  final bool active;

  Banner({
    this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.backgroundColor,
    this.textColor,
    this.linkUrl,
    this.sortOrder = 0,
    this.active = true,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'] as int?,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['imageUrl'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      textColor: json['textColor'] as String?,
      linkUrl: json['linkUrl'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'linkUrl': linkUrl,
      'sortOrder': sortOrder,
      'active': active,
    };
  }

  Banner copyWith({
    int? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? backgroundColor,
    String? textColor,
    String? linkUrl,
    int? sortOrder,
    bool? active,
  }) {
    return Banner(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      linkUrl: linkUrl ?? this.linkUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      active: active ?? this.active,
    );
  }
}