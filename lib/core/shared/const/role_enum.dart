enum RoleEnum {
  user,
  seller,
  rider,
  admin;

  static RoleEnum? fromString(String? value) {
    if (value == null || value.isEmpty) return null;

    switch (value.toUpperCase()) {
      case 'USER':
        return RoleEnum.user;
      case 'SELLER':
        return RoleEnum.seller;
      case 'RIDER':
        return RoleEnum.rider;
      case 'ADMIN':
        return RoleEnum.admin;
      default:
        return null;
    }
  }

  String get apiValue {
    switch (this) {
      case RoleEnum.user:
        return 'USER';
      case RoleEnum.seller:
        return 'SELLER';
      case RoleEnum.rider:
        return 'RIDER';
      case RoleEnum.admin:
        return 'ADMIN';
    }
  }

  String get displayName {
    switch (this) {
      case RoleEnum.user:
        return 'User';
      case RoleEnum.seller:
        return 'Seller';
      case RoleEnum.rider:
        return 'Rider';
      case RoleEnum.admin:
        return 'Admin';
    }
  }
}
