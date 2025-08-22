import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

class DashboardTile1 extends StatelessWidget {
  const DashboardTile1({Key? key, required this.info, required this.count, required this.icon}) : super(key: key);

  final String info;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              radius: 20,
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey),
                ),
                AnimatedFlipCounter(
                  duration: const Duration(milliseconds: 500),
                  value: count,
                  thousandSeparator: ',',
                  textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 28),
                )
              ],
            )
          ],
        ));
  }
}
