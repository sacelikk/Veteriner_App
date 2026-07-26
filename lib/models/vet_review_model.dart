class VetReviewModel {
  final String id;
  final String vetId;
  final String reviewerName;
  final double rating; // 1.0 - 5.0
  final String comment;
  final DateTime createdAt;

  VetReviewModel({
    required this.id,
    required this.vetId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory VetReviewModel.fromMap(String id, Map<String, dynamic> data) {
    return VetReviewModel(
      id: id,
      vetId: data['vetId'] ?? '',
      reviewerName: data['reviewerName'] ?? 'Anonim Pet Sahibi',
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vetId': vetId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}
