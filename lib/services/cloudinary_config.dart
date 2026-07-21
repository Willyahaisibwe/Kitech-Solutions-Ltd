class CloudinaryConfig {
  static const String cloudName = 'm7gc2gop';
  static const String uploadPreset = 'kitech_profile_photos';

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}
