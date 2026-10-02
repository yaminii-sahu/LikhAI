class AppLocale {
  static String text(String currentLanguage, String english, String hindi) {
    if (currentLanguage.toLowerCase() == 'hindi' || currentLanguage == 'hi') {
      return hindi;
    }
    return english;
  }
}
