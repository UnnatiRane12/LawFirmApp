import 'package:flutter_riverpod/flutter_riverpod.dart';

final clientNavigationProvider = StateProvider<int>((ref) => 0);
final lawyerNavigationProvider = StateProvider<int>((ref) => 0);
final adminNavigationProvider = StateProvider<int>((ref) => 0);
