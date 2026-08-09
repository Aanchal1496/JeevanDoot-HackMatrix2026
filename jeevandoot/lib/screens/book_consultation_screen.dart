import 'package:flutter/material.dart';
import 'package:jeevandoot/screens/consultation/booking_flow_screen.dart';

/// Entry point for the teleconsultation booking flow.
///
/// Kept as a thin wrapper so existing callers (`const BookConsultationScreen()`)
/// continue to work while the full wizard lives in
/// [ConsultationBookingFlowScreen].
class BookConsultationScreen extends StatelessWidget {
  const BookConsultationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConsultationBookingFlowScreen();
  }
}
