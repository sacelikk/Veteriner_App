import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../models/vet_review_model.dart';
import '../../services/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/animated_dialog.dart';
import '../chat/live_support_request_screen.dart';
import '../welcome/welcome_screen.dart';

class VetProfileScreen extends ConsumerStatefulWidget {
  final UserModel vet;

  const VetProfileScreen({super.key, required this.vet});

  @override
  ConsumerState<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends ConsumerState<VetProfileScreen> {
  void _showAddReviewDialog(BuildContext context) {
    final db = ref.read(databaseProvider);
    final isGuest = db.currentUser?.isGuest ?? true;

    if (isGuest) {
      AnimatedDialog.show(
        context,
        title: 'Kayıt Olmanız Gerekiyor',
        message: 'Veteriner hekimlere değerlendirme ve yorum yapabilmek için lütfen giriş yapın veya kayıt olun.',
        type: DialogType.info,
        buttonText: 'Giriş Yap / Kayıt Ol',
        onConfirm: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        },
      );
      return;
    }

    double selectedRating = 5.0;
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Değerlendirme & Yorum Yap',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.vet.name} hakkındaki deneyiminizi değerlendirin:',
                    style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        onPressed: () {
                          setModalState(() {
                            selectedRating = starValue.toDouble();
                          });
                        },
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Yorumunuzu yazın (örn: Kliniğin hijyeni ve ilgisi harikaydı...)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty) {
                        AnimatedDialog.show(
                          context,
                          title: 'Yorum Boş',
                          message: 'Lütfen bir yorum yazın.',
                          type: DialogType.info,
                        );
                        return;
                      }

                      await db.addVetReview(
                        widget.vet.id,
                        selectedRating,
                        commentController.text.trim(),
                      );
                      ref.invalidate(vetReviewsProvider(widget.vet.id));

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      AnimatedDialog.show(
                        context,
                        title: 'Teşekkürler! ⭐',
                        message: 'Değerlendirmeniz başarıyla eklendi.',
                        type: DialogType.success,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Değerlendirmeyi Gönder', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(vetReviewsProvider(widget.vet.id));
    final db = ref.watch(databaseProvider);
    final isGuest = db.currentUser?.isGuest ?? true;

    // Listen to real-time vet updates
    final veterinariansAsync = ref.watch(veterinariansProvider);
    final currentVet = veterinariansAsync.value?.firstWhere(
      (v) => v.id == widget.vet.id,
      orElse: () => widget.vet,
    ) ?? widget.vet;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Veteriner Hekim Profili'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 43,
                          backgroundColor: AppTheme.primaryLight,
                          child: Text(
                            currentVet.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: currentVet.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentVet.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentVet.clinicName ?? 'Klinik Bilgisi Yok',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  // Rating & Status Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${currentVet.rating} (${currentVet.reviewCount} Yorum)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: currentVet.isOnline ? Colors.green.shade600 : Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          currentVet.isOnline ? '● Müsait (Çevrimiçi)' : '○ Çevrimdışı',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Müsaitlik & Çalışma Saatleri Kartı
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.access_time_filled, color: AppTheme.primaryColor),
                              SizedBox(width: 8),
                              Text(
                                'Çalışma Günleri & Saatleri',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: AppTheme.textLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentVet.workingDaysHours ?? 'Çalışma saatleri belirtilmedi',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: const [
                              Icon(Icons.verified, size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Acil durum ve Canlı Destek için aktif',
                                style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Uzmanlık Alanları
                  if (currentVet.specialties != null && currentVet.specialties!.isNotEmpty) ...[
                    const Text(
                      'Uzmanlık Alanları',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentVet.specialties!.map((specialty) {
                        return Chip(
                          avatar: const Icon(Icons.pets, size: 16, color: AppTheme.primaryColor),
                          label: Text(specialty, style: const TextStyle(fontSize: 13)),
                          backgroundColor: AppTheme.primaryLight.withOpacity(0.15),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // (İletişim & Adres Kartı Kaldırıldı - Güvenlik Nedeniyle)


                  // Biyografi / Hakkında
                  if (currentVet.bio != null) ...[
                    const Text(
                      'Hakkında',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          currentVet.bio!,
                          style: const TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Değerlendirmeler ve Yorumlar Bölümü
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Değerlendirmeler & Yorumlar',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddReviewDialog(context),
                        icon: const Icon(Icons.rate_review, size: 18),
                        label: const Text('Yorum Yap'),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  reviewsAsync.when(
                    data: (reviews) {
                      if (reviews.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text('Henüz değerlendirme yapılmamış. İlk yorumu siz yapın!'),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 16,
                                            backgroundColor: AppTheme.primaryLight,
                                            child: Icon(Icons.person, size: 18, color: Colors.white),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            review.reviewerName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: List.generate(5, (starIdx) {
                                          return Icon(
                                            starIdx < review.rating ? Icons.star : Icons.star_border,
                                            color: Colors.amber,
                                            size: 16,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    review.comment,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Hata: $err'),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Call-to-action
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (isGuest) {
                    AnimatedDialog.show(
                      context,
                      title: 'Misafir Girişi',
                      message: 'Canlı destek almak için lütfen giriş yapın.',
                      type: DialogType.info,
                      onConfirm: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                          (route) => false,
                        );
                      },
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveSupportRequestScreen(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.video_camera_front),
                label: const Text('Canlı Destek Başlat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
