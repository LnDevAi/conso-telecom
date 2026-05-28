import 'package:isar/isar.dart';

part 'service_review.g.dart';

@Collection()
class ServiceReview {
  Id id = Isar.autoIncrement;

  @Index()
  late String serviceId;

  @Index()
  late String serviceType; // 'operator' | 'ai_provider'

  late String serviceName;

  late int rating; // 1-5

  late String comment;

  @Index()
  late DateTime createdAt;

  late String category; // 'reseau' | 'service_client' | 'prix' | 'fiabilite' | 'qualite'

  bool isAnonymous = true;

  ServiceReview();

  ServiceReview.create({
    required this.serviceId,
    required this.serviceType,
    required this.serviceName,
    required this.rating,
    required this.comment,
    required this.category,
    this.isAnonymous = true,
  }) {
    createdAt = DateTime.now();
  }
}
