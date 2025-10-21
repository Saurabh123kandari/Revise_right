class AppConstants {
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String schedulesCollection = 'schedules';
  static const String subjectsCollection = 'subjects';
  static const String topicsCollection = 'topics';
  
  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String studyMaterialsPath = 'study_materials';
  
  // Notification IDs
  static const int studyReminderId = 1001;
  static const int breakReminderId = 1002;
  
  // Study Session Settings
  static const int defaultStudyDuration = 25; // minutes
  static const int defaultBreakDuration = 5; // minutes
  static const int maxStudySessionsPerDay = 8;
  
  // Priority Levels
  static const int highPriority = 3;
  static const int mediumPriority = 2;
  static const int lowPriority = 1;
}
