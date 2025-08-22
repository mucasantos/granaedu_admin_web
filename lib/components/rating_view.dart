import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingView extends StatelessWidget {
  const RatingView({Key? key, required this.rating, this.iconSize, this.showText}) : super(key: key);

  final double rating;
  final double? iconSize;
  final bool? showText;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RatingBarIndicator(
          itemSize: iconSize ?? 16,
          rating: rating,
          itemPadding: const EdgeInsets.symmetric(vertical: 7),
          itemCount: 5,
          itemBuilder: (context, index) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
        ),
        Visibility(
          visible: showText ?? true,
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              rating.toStringAsFixed(2),
              style: const TextStyle(fontSize: 13, color: Colors.amber),
            ),
          ),
        )
      ],
    );
  }
}
