import 'package:avanti/features/tours/presentation/tour_detail_screen.dart';
import 'package:flutter/material.dart';

class TourDetailRoute extends StatelessWidget {
  final String tourId;
  const TourDetailRoute({super.key, required this.tourId});

  @override
  Widget build(BuildContext context) {
    return TourDetailScreen(tourId: tourId);
  }
}
