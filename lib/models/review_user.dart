// Sub-model of Review

class ReviewUser {
  final String id, name;
  final String? imageUrl;

  ReviewUser({required this.id, required this.name, this.imageUrl});

  factory ReviewUser.fromFirebase(Map<String, dynamic> d) {
    final String id = d['id'] == null ? '' : d['id'].toString();
    final String name = d['name'] == null ? '' : d['name'].toString();
    final String? imageUrl = d['image_url'] == null ? null : d['image_url'].toString();

    return ReviewUser(
      id: id,
      name: name,
      imageUrl: imageUrl,
    );
  }

  static Map<String, dynamic> getMap(ReviewUser d) {
    return {'id': d.id, 'name': d.name, 'image_url': d.imageUrl};
  }
}