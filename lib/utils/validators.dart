class Validators {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidProjectName(String name) {
    return name.isNotEmpty && name.length <= 50;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    if (!isValidEmail(email)) {
      return '有効なメールアドレスを入力してください';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'パスワードを入力してください';
    }
    if (!isValidPassword(password)) {
      return 'パスワードは6文字以上です';
    }
    return null;
  }

  static String? validateProjectName(String? name) {
    if (name == null || name.isEmpty) {
      return 'プロジェクト名を入力してください';
    }
    if (!isValidProjectName(name)) {
      return 'プロジェクト名は50文字以下です';
    }
    return null;
  }
}
