import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

class DashboardTile extends StatelessWidget {
  const DashboardTile({Key? key, required this.info, required this.count, required this.icon, this.bgColor}) : super(key: key);

  final String info;
  final int count;
  final IconData icon;
  final Color?  bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Wrap(
        runAlignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: bgColor ?? Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                radius: 20,
                child: Icon(icon, size: 20),
              ),
              AnimatedFlipCounter(
                duration: const Duration(milliseconds: 500),
                value: count,
                thousandSeparator: ',',
                textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 28),
              )
            ],
          ),
          Text(
            info,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.blueGrey, fontWeight: FontWeight.w400),
          )
        ],
      ),
    );
  }
}
