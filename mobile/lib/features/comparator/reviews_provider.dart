import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/isar_service.dart';
import '../../core/database/models/service_review.dart';

// Catalogue statique des services notables
class ReviewableService {
  final String id;
  final String name;
  final String type; // 'operator' | 'ai_provider'
  final String countryCode;

  const ReviewableService({
    required this.id,
    required this.name,
    required this.type,
    this.countryCode = 'BF',
  });
}

const allReviewableServices = [
  ReviewableService(id: 'orange_bf', name: 'Orange Burkina Faso', type: 'operator'),
  ReviewableService(id: 'moov_bf', name: 'Moov Africa Burkina', type: 'operator'),
  ReviewableService(id: 'telecel_bf', name: 'Telecel Faso', type: 'operator'),
  ReviewableService(id: 'orange_ci', name: 'Orange Côte d\'Ivoire', type: 'operator', countryCode: 'CI'),
  ReviewableService(id: 'mtn_ci', name: 'MTN Côte d\'Ivoire', type: 'operator', countryCode: 'CI'),
  ReviewableService(id: 'wave', name: 'Wave (Mobile Money)', type: 'operator'),
  ReviewableService(id: 'anthropic', name: 'Claude (Anthropic)', type: 'ai_provider'),
  ReviewableService(id: 'openai', name: 'ChatGPT (OpenAI)', type: 'ai_provider'),
  ReviewableService(id: 'google_ai', name: 'Gemini (Google)', type: 'ai_provider'),
  ReviewableService(id: 'mistral', name: 'Mistral AI', type: 'ai_provider'),
];

const reviewCategories = {
  'reseau': 'Réseau & Couverture',
  'service_client': 'Service client',
  'prix': 'Prix & Offres',
  'fiabilite': 'Fiabilité',
  'qualite': 'Qualité générale',
};

// Provider: liste paginée de tous les avis, triés par date desc
final reviewsListProvider = FutureProvider.family<List<ServiceReview>, String?>(
  (ref, serviceId) async {
    final isar = IsarService.instance;
    var query = isar.serviceReviews.where().sortByCreatedAtDesc();
    if (serviceId != null && serviceId.isNotEmpty) {
      return isar.serviceReviews
          .filter()
          .serviceIdEqualTo(serviceId)
          .sortByCreatedAtDesc()
          .findAll();
    }
    return query.findAll();
  },
);

// Provider: moyenne des notes par service
final serviceRatingProvider = FutureProvider.family<double?, String>(
  (ref, serviceId) async {
    final reviews = await ref.watch(reviewsListProvider(serviceId).future);
    if (reviews.isEmpty) return null;
    final sum = reviews.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / reviews.length;
  },
);

// Provider: nombre total d'avis par service
final serviceReviewCountProvider = FutureProvider.family<int, String>(
  (ref, serviceId) async {
    final isar = IsarService.instance;
    return isar.serviceReviews.filter().serviceIdEqualTo(serviceId).count();
  },
);

// Notifier pour ajouter / supprimer des avis
class ReviewsNotifier extends StateNotifier<AsyncValue<void>> {
  ReviewsNotifier() : super(const AsyncValue.data(null));

  Future<void> addReview(ServiceReview review) async {
    state = const AsyncValue.loading();
    try {
      final isar = IsarService.instance;
      await isar.writeTxn(() async {
        await isar.serviceReviews.put(review);
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteReview(int id) async {
    state = const AsyncValue.loading();
    try {
      final isar = IsarService.instance;
      await isar.writeTxn(() async {
        await isar.serviceReviews.delete(id);
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final reviewsNotifierProvider = StateNotifierProvider<ReviewsNotifier, AsyncValue<void>>(
  (_) => ReviewsNotifier(),
);
