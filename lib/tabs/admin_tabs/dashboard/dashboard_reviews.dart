import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/components/side_menu.dart';
import 'package:lms_admin/mixins/user_mixin.dart';
import 'package:lms_admin/models/review.dart';
import 'package:lms_admin/services/firebase_service.dart';

import '../../../components/rating_view.dart';
import '../../../pages/home.dart';

final dashboardReviewsProvider = FutureProvider<List<Review>>((ref) async {
  final List<Review> reviews = await FirebaseService().getLatestReviews(5);
  return reviews;
});

class DashboardReviews extends ConsumerWidget {
  const DashboardReviews({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(dashboardReviewsProvider);
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.grey.shade300,
        )
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Reviews',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                  onPressed: () {
                    ref.read(menuIndexProvider.notifier).update((state) => 5);
                    ref.read(pageControllerProvider.notifier).state.jumpToPage(5);
                  },
                  child: const Text('View All'))
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: reviews.when(
              skipError: true,
              data: (data) {
                return Column(
                  children: data.map((review) {
                    return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 3),
                        leading: UserMixin.getUserImageByUrl(imageUrl: review.reviewUser.imageUrl),
                        title: Text(
                          review.reviewUser.name,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RatingView(rating: review.rating, showText: true),
                            Visibility(
                              visible: review.review != null && review.review!.isNotEmpty,
                              child: Text(
                                review.review ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ));
                  }).toList(),
                );
              },
              error: (a, b) => Container(),
              loading: () => Container(),
            ),
          )
        ],
      ),
    );
  }
}
