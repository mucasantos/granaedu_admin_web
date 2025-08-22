// Sub-model of UserModel
class AuthorInfo {
  final String? fb, twitter, bio, website, jobTitle;
  final int? students;

  AuthorInfo({this.fb, this.twitter, this.bio, this.website, this.jobTitle, this.students});

  factory AuthorInfo.fromMap(Map<String, dynamic> d) {
    return AuthorInfo(
        students: d['students'],
        fb: d['fb'],
        website: d['website'],
        bio: d['bio'],
        jobTitle: d['job_title'],
        twitter: d['twitter']);
  }

  static Map<String, dynamic> getMap(AuthorInfo d) {
    return {
      'fb': d.fb,
      'twitter': d.twitter,
      'bio': d.bio,
      'job_title': d.jobTitle,
      'website': d.website,
    };
  }
}
