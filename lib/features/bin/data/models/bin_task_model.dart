class BinTaskModel {
  final String id;
  final String title;
  final DateTime deletedAt;

  BinTaskModel({required this.id, required this.title, required this.deletedAt});

  factory BinTaskModel.fromJson(Map<String, dynamic> json) {
    return BinTaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : DateTime.now(),
    );
  }
}
