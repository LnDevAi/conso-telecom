import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/models/service_review.dart';
import '../../core/theme/app_theme.dart';
import 'reviews_provider.dart';
import 'add_review_sheet.dart';

// Filtre actif (null = tous les services)
final _reviewFilterProvider = StateProvider<String?>((ref) => null);

class ReviewsTab extends ConsumerWidget {
  const ReviewsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeFilter = ref.watch(_reviewFilterProvider);
    final reviewsAsync = ref.watch(reviewsListProvider(activeFilter));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, ref),
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Donner un avis'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtres par service
          _ServiceFilterBar(activeFilter: activeFilter),
          // Synthèse par service (si pas de filtre)
          if (activeFilter == null) const _ServiceSummaryRow(),
          const Divider(height: 1),
          // Liste avis
          Expanded(
            child: reviewsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (reviews) {
                if (reviews.isEmpty) {
                  return _EmptyState(
                    onAdd: () => _openAddSheet(context, ref),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ReviewCard(
                    review: reviews[i],
                    onDelete: () => _delete(ref, reviews[i].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddReviewSheet(),
    );
    if (added == true) {
      ref.invalidate(reviewsListProvider);
      ref.invalidate(serviceRatingProvider);
      ref.invalidate(serviceReviewCountProvider);
    }
  }

  Future<void> _delete(WidgetRef ref, int id) async {
    await ref.read(reviewsNotifierProvider.notifier).deleteReview(id);
    ref.invalidate(reviewsListProvider);
    ref.invalidate(serviceRatingProvider);
    ref.invalidate(serviceReviewCountProvider);
  }
}

// ---- Barre de filtres ----
class _ServiceFilterBar extends ConsumerWidget {
  const _ServiceFilterBar({required this.activeFilter});
  final String? activeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = [
      (null, 'Tous'),
      ...allReviewableServices.map((s) => (s.id, s.name.split(' ').first)),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (id, label) = categories[i];
          final selected = activeFilter == id;
          return FilterChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) =>
                ref.read(_reviewFilterProvider.notifier).state = selected ? null : id,
            selectedColor: AppTheme.primary.withOpacity(0.15),
            labelStyle: TextStyle(
              fontSize: 12,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          );
        },
      ),
    );
  }
}

// ---- Ligne de synthèse des notes moyennes ----
class _ServiceSummaryRow extends ConsumerWidget {
  const _ServiceSummaryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = allReviewableServices;
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = services[i];
          final ratingAsync = ref.watch(serviceRatingProvider(s.id));
          final countAsync = ref.watch(serviceReviewCountProvider(s.id));
          final rating = ratingAsync.asData?.value;
          final count = countAsync.asData?.value ?? 0;

          return GestureDetector(
            onTap: () =>
                ref.read(_reviewFilterProvider.notifier).state = s.id,
            child: Container(
              width: 110,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        s.type == 'operator' ? Icons.cell_tower : Icons.psychology,
                        size: 12,
                        color: s.type == 'operator' ? AppTheme.primary : AppTheme.aiPurple,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s.name.split(' ').take(2).join(' '),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (rating != null)
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: AppTheme.warning),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Aucun avis',
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  Text(
                    '$count avis',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---- Carte d'un avis ----
class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.review, required this.onDelete});

  final ServiceReview review;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('d MMM yyyy', 'fr_FR');
    final isOperator = review.serviceType == 'operator';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : service + date + supprimer
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isOperator ? AppTheme.primary : AppTheme.aiPurple).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOperator ? Icons.cell_tower : Icons.psychology,
                        size: 12,
                        color: isOperator ? AppTheme.primary : AppTheme.aiPurple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        review.serviceName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOperator ? AppTheme.primary : AppTheme.aiPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  dateFmt.format(review.createdAt),
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Étoiles + catégorie
            Row(
              children: [
                _StarDisplay(rating: review.rating),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    reviewCategories[review.category] ?? review.category,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ),
                if (review.isAnonymous) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.visibility_off, size: 12, color: AppTheme.textSecondary),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Commentaire
            Text(
              review.comment,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'avis ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }
}

class _StarDisplay extends StatelessWidget {
  const _StarDisplay({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
        size: 16,
        color: i < rating ? AppTheme.warning : AppTheme.border,
      )),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: AppTheme.border),
            const SizedBox(height: 16),
            Text(
              'Aucun avis pour l\'instant',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Soyez le premier à partager votre expérience sur un opérateur ou un fournisseur IA.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Donner un avis'),
            ),
          ],
        ),
      ),
    );
  }
}
