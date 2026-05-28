import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/models/service_review.dart';
import '../../core/theme/app_theme.dart';
import 'reviews_provider.dart';

class AddReviewSheet extends ConsumerStatefulWidget {
  const AddReviewSheet({super.key, this.preselectedServiceId});

  final String? preselectedServiceId;

  @override
  ConsumerState<AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends ConsumerState<AddReviewSheet> {
  ReviewableService? _selectedService;
  String _selectedCategory = 'qualite';
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _anonymous = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedServiceId != null) {
      _selectedService = allReviewableServices
          .where((s) => s.id == widget.preselectedServiceId)
          .firstOrNull;
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedService != null && _rating > 0 && _commentCtrl.text.trim().length >= 5;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);

    final review = ServiceReview.create(
      serviceId: _selectedService!.id,
      serviceType: _selectedService!.type,
      serviceName: _selectedService!.name,
      rating: _rating,
      comment: _commentCtrl.text.trim(),
      category: _selectedCategory,
      isAnonymous: _anonymous,
    );

    await ref.read(reviewsNotifierProvider.notifier).addReview(review);

    // Invalider les providers de liste et stats
    ref.invalidate(reviewsListProvider);
    ref.invalidate(serviceRatingProvider);
    ref.invalidate(serviceReviewCountProvider);

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final operators = allReviewableServices.where((s) => s.type == 'operator').toList();
    final aiProviders = allReviewableServices.where((s) => s.type == 'ai_provider').toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Donner un avis', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Partagez votre expérience sur un opérateur ou un fournisseur IA.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            // Service selector
            Text('Service', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _ServiceDropdown(
              operators: operators,
              aiProviders: aiProviders,
              selected: _selectedService,
              onChanged: (s) => setState(() => _selectedService = s),
            ),
            const SizedBox(height: 16),

            // Catégorie
            Text('Catégorie', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: reviewCategories.entries.map((entry) {
                final selected = _selectedCategory == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = entry.key),
                  selectedColor: AppTheme.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: selected ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Étoiles
            Text('Note', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _StarRating(
              rating: _rating,
              onChanged: (r) => setState(() => _rating = r),
            ),
            const SizedBox(height: 4),
            if (_rating > 0)
              Text(
                _ratingLabel(_rating),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _ratingColor(_rating),
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 16),

            // Commentaire
            Text('Commentaire', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Décrivez votre expérience (min. 5 caractères)…',
                counterStyle: TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 12),

            // Anonymat
            Row(
              children: [
                Switch(value: _anonymous, onChanged: (v) => setState(() => _anonymous = v)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Publier anonymement',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bouton submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit && !_submitting ? _submit : null,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Publier l\'avis'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Très mauvais';
      case 2:
        return 'Mauvais';
      case 3:
        return 'Correct';
      case 4:
        return 'Bien';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _ratingColor(int r) {
    if (r >= 4) return AppTheme.success;
    if (r == 3) return AppTheme.warning;
    return AppTheme.danger;
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < rating;
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 36,
              color: filled ? AppTheme.warning : AppTheme.border,
            ),
          ),
        );
      }),
    );
  }
}

class _ServiceDropdown extends StatelessWidget {
  const _ServiceDropdown({
    required this.operators,
    required this.aiProviders,
    required this.selected,
    required this.onChanged,
  });

  final List<ReviewableService> operators;
  final List<ReviewableService> aiProviders;
  final ReviewableService? selected;
  final ValueChanged<ReviewableService?> onChanged;

  @override
  Widget build(BuildContext context) {
    final all = [...operators, ...aiProviders];

    return DropdownButtonFormField<ReviewableService>(
      value: selected,
      isExpanded: true,
      decoration: const InputDecoration(hintText: 'Sélectionner un service'),
      items: [
        const DropdownMenuItem<ReviewableService>(
          enabled: false,
          child: Text(
            '— Opérateurs télécom —',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        ...operators.map((s) => DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  const Icon(Icons.cell_tower, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(s.name, style: const TextStyle(fontSize: 14)),
                ],
              ),
            )),
        const DropdownMenuItem<ReviewableService>(
          enabled: false,
          child: Text(
            '— Fournisseurs IA —',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        ...aiProviders.map((s) => DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  const Icon(Icons.psychology, size: 16, color: AppTheme.aiPurple),
                  const SizedBox(width: 8),
                  Text(s.name, style: const TextStyle(fontSize: 14)),
                ],
              ),
            )),
      ],
      onChanged: onChanged,
    );
  }
}
