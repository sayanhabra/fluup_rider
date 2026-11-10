class Validator {
  static String get emailRegex => "";
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty !';
    }
    if (!RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(value)) {
      return 'Please enter a valid email address !';
    }
    return null;
  }

  static String? passwordValidator(
    String? value, {
    String? otherPassword,
    int minLength = 3,
  }) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty !';
    }
    if (value.length <= minLength) {
      return 'Password is too short';
    }
    if (otherPassword != null && value != otherPassword) {
      return 'Password & Confirm Password should be same';
    }
    return null;
  }

  static String? zipcodeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty !';
    }
    if (value.length != 10) {
      return 'Incorrect Country Code';
    }
    return null;
  }

  static String? countryCodeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty !';
    }
    if (value.length != 2) {
      return 'Incorrect Country Code';
    }
    return null;
  }

  static String? phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty !';
    }
    if (value.length != 10) {
      return 'Phone number should be 10 digit';
    }
    return null;
  }

  static String? defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty !';
    }
    return null;
  }

  static String? minLengthValidator(
    String? value, {
    String? incorrectMessage,
    int length = 2,
  }) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty !';
    }
    if (value.length < length) {
      return incorrectMessage ??
          'Value too short. (Minimum length is $length characters)';
    }
    return null;
  }

  static String? fourDigitsValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty !';
    }
    if (value.length != 4) {
      return 'Incorrect value';
    }
    return null;
  }
}
