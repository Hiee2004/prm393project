class CustomFocusAudio {
  const CustomFocusAudio({
    required this.id,
    required this.label,
    required this.filePath,
  });

  final String id;
  final String label;
  final String filePath;

  factory CustomFocusAudio.fromJson(Map<String, dynamic> json) {
    return CustomFocusAudio(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Custom audio',
      filePath: json['filePath']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'filePath': filePath,
    };
  }
}
