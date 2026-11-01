class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? requiredField(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? name(String? value) {
    final required = requiredField(value, 'Por favor, insira seu nome');
    if (required != null) return required;
    if (value!.trim().length < 3) {
      return 'O nome deve ter pelo menos 3 caracteres';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredField(value, 'Por favor, insira seu email');
    if (required != null) return required;
    if (!_emailRegex.hasMatch(value!.trim())) {
      return 'Por favor, insira um email válido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira sua senha';
    }
    if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Por favor, confirme sua senha';
    }
    if (value != password) return 'As senhas não coincidem';
    return null;
  }

  static String? taskTitle(String? value) =>
      requiredField(value, 'Informe o título');
}
