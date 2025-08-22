import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/firebase_service.dart';

final categoriesProvider = StateNotifierProvider<CategoryData, List<Category>>((ref) => CategoryData());

class CategoryData extends StateNotifier<List<Category>>{
  CategoryData(): super([]);

  Future getCategories () async{
    state = await FirebaseService().getCategories();
    debugPrint('got categories');
  }
}