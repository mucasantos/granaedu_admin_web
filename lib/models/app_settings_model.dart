import 'package:cloud_firestore/cloud_firestore.dart';
import 'ads_model.dart';

class AppSettingsModel {
  final bool? freeCourses, topAuthors, categories, featured, tags, skipLogin, onBoarding, latestCourses, contentSecurity;
  final String? supportEmail, website, privacyUrl;
  final HomeCategory? homeCategory1, homeCategory2, homeCategory3;
  final AppSettingsSocialInfo? social;
  final AdsModel? ads;
  

  AppSettingsModel({
    this.freeCourses,
    this.topAuthors,
    this.categories,
    this.featured,
    this.tags,
    this.onBoarding,
    this.supportEmail,
    this.website,
    this.privacyUrl,
    this.homeCategory1,
    this.homeCategory2,
    this.homeCategory3,
    this.social,
    this.skipLogin,
    this.latestCourses,
    this.ads,
    this.contentSecurity,
  });

  factory AppSettingsModel.fromFirestore(DocumentSnapshot snap) {
    final Map d = snap.data() as Map<String, dynamic>;
    return AppSettingsModel(
      featured: d['featured'] ?? true,
      topAuthors: d['top_authors'] ?? true,
      categories: d['categories'] ?? true,
      freeCourses: d['free_courses'] ?? true,
      onBoarding: d['onboarding'] ?? true,
      skipLogin: d['skip_login'] ?? false,
      latestCourses: d['latest_courses'] ?? true,
      tags: d['tags'] ?? true,
      supportEmail: d['email'],
      privacyUrl: d['privacy_url'],
      website: d['website'],
      homeCategory1: d['category1'] != null ? HomeCategory.fromMap(d['category1']) : null,
      homeCategory2: d['category2'] != null ? HomeCategory.fromMap(d['category2']) : null,
      homeCategory3: d['category3'] != null ? HomeCategory.fromMap(d['category3']) : null,
      social: d['social'] != null ? AppSettingsSocialInfo.fromMap(d['social']) : null,
      ads: d['ads'] != null ? AdsModel.fromMap(d['ads']) : null,
      contentSecurity: d['content_security'] ?? false,
    );
  }

  static Map<String, dynamic> getMap(AppSettingsModel d) {
    return {
      'featured': d.featured,
      'top_authors': d.topAuthors,
      'categories': d.categories,
      'free_courses': d.freeCourses,
      'onboarding': d.onBoarding,
      'skip_login': d.skipLogin,
      'latest_courses': d.latestCourses,
      'tags': d.tags,
      'email': d.supportEmail,
      'privacy_url': d.privacyUrl,
      'website': d.website,
      'category1': d.homeCategory1 != null ? HomeCategory.getMap(d.homeCategory1!) : null,
      'category2': d.homeCategory2 != null ? HomeCategory.getMap(d.homeCategory2!) : null,
      'category3': d.homeCategory3 != null ? HomeCategory.getMap(d.homeCategory3!) : null,
      'social': d.social != null ? AppSettingsSocialInfo.getMap(d.social!) : null,
      'content_security': d.contentSecurity,
    };
  }

  static Map<String, dynamic> getMapAdsSettings(AppSettingsModel d) {
    return {
      'ads': d.ads != null ? AdsModel.getMap(d.ads!) : null,
    };
  }

  
}

class HomeCategory {
  final String id, name;

  HomeCategory({required this.id, required this.name});

  factory HomeCategory.fromMap(Map<String, dynamic> d) {
    return HomeCategory(
      id: d['id'],
      name: d['name'],
    );
  }

  static Map<String, dynamic> getMap(HomeCategory d) {
    return {
      'id': d.id,
      'name': d.name,
    };
  }
}

class AppSettingsSocialInfo {
  final String? fb, youtube, twitter, instagram;

  AppSettingsSocialInfo({required this.fb, required this.youtube, required this.twitter, required this.instagram});

  factory AppSettingsSocialInfo.fromMap(Map<String, dynamic> d) {
    return AppSettingsSocialInfo(
      fb: d['fb'],
      youtube: d['youtube'],
      instagram: d['instagram'],
      twitter: d['twitter'],
    );
  }

  static Map<String, dynamic> getMap(AppSettingsSocialInfo d) {
    return {
      'fb': d.fb,
      'youtube': d.youtube,
      'instagram': d.instagram,
      'twitter': d.twitter,
    };
  }
}
