class DeletedTaskModel {
  final String title;
  final String description;

  const DeletedTaskModel({required this.title, required this.description});

  factory DeletedTaskModel.fromJson(Map<String, dynamic> json) {
    return DeletedTaskModel(
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }
}
