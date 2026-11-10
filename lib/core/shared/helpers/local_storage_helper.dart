// import 'package:hive_flutter/hive_flutter.dart';

// class LocalStorageHelper {
//   LocalStorageHelper._();

//   static final LocalStorageHelper instance =
//       LocalStorageHelper._();

//   // Main box name
//   static const String _boxName = 'app_storage';

//   Box<dynamic>? _box;

//   // ============================================================
//   // INITIALIZE HIVE
//   // Call this once before runApp()
//   // ============================================================

//   Future<void> init() async {
//     await Hive.initFlutter();

//     _box = await Hive.openBox<dynamic>(_boxName);
//   }

//   // ============================================================
//   // GET BOX
//   // ============================================================

//   Box<dynamic> get box {
//     if (_box == null || !_box!.isOpen) {
//       throw Exception(
//         'LocalStorageHelper is not initialized. '
//         'Call LocalStorageHelper.instance.init() before runApp().',
//       );
//     }

//     return _box!;
//   }

//   // ============================================================
//   // SAVE ANY HIVE-SUPPORTED VALUE
//   //
//   // Supports:
//   // String
//   // int
//   // double
//   // bool
//   // List
//   // Map
//   // ============================================================

//   Future<void> set<T>(
//     String key,
//     T value,
//   ) async {
//     await box.put(key, value);
//   }

//   // ============================================================
//   // GET VALUE
//   // ============================================================

//   T? get<T>(
//     String key, {
//     T? defaultValue,
//   }) {
//     final value = box.get(
//       key,
//       defaultValue: defaultValue,
//     );

//     if (value == null) {
//       return defaultValue;
//     }

//     return value as T;
//   }

//   // ============================================================
//   // SAVE STRING
//   // ============================================================

//   Future<void> setString(
//     String key,
//     String value,
//   ) async {
//     await box.put(key, value);
//   }

//   // ============================================================
//   // GET STRING
//   // ============================================================

//   String? getString(
//     String key, {
//     String? defaultValue,
//   }) {
//     return box.get(
//       key,
//       defaultValue: defaultValue,
//     ) as String?;
//   }

//   // ============================================================
//   // SAVE INT
//   // ============================================================

//   Future<void> setInt(
//     String key,
//     int value,
//   ) async {
//     await box.put(key, value);
//   }

//   // ============================================================
//   // GET INT
//   // ============================================================

//   int? getInt(
//     String key, {
//     int? defaultValue,
//   }) {
//     return box.get(
//       key,
//       defaultValue: defaultValue,
//     ) as int?;
//   }

//   // ============================================================
//   // SAVE DOUBLE
//   // ============================================================

//   Future<void> setDouble(
//     String key,
//     double value,
//   ) async {
//     await box.put(key, value);
//   }

//   // ============================================================
//   // GET DOUBLE
//   // ============================================================

//   double? getDouble(
//     String key, {
//     double? defaultValue,
//   }) {
//     return box.get(
//       key,
//       defaultValue: defaultValue,
//     ) as double?;
//   }

//   // ============================================================
//   // SAVE BOOL
//   // ============================================================

//   Future<void> setBool(
//     String key,
//     bool value,
//   ) async {
//     await box.put(key, value);
//   }

//   // ============================================================
//   // GET BOOL
//   // ============================================================

//   bool getBool(
//     String key, {
//     bool defaultValue = false,
//   }) {
//     return box.get(
//           key,
//           defaultValue: defaultValue,
//         ) as bool? ??
//         defaultValue;
//   }

//   // ============================================================
//   // SAVE LIST
//   // ============================================================

//   Future<void> setList<T>(
//     String key,
//     List<T> value,
//   ) async {
//     await box.put(key, value);
//   }

//   // ============================================================
//   // GET LIST
//   // ============================================================

//   List<T> getList<T>(
//     String key,
//   ) {
//     final value = box.get(key);

//     if (value == null) {
//       return [];
//     }

//     return List<T>.from(value);
//   }

//   // ============================================================
//   // SAVE MAP
//   // ============================================================

//   Future<void> setMap(
//     String key,
//     Map<String, dynamic> value,
//   ) async {
//     await box.put(key, value);
//   }

//   // ============================================================
//   // GET MAP
//   //
//   // Hive may return Map<dynamic, dynamic>, so convert it safely.
//   // ============================================================

//   Map<String, dynamic>? getMap(
//     String key,
//   ) {
//     final value = box.get(key);

//     if (value == null) {
//       return null;
//     }

//     return Map<String, dynamic>.from(value);
//   }

//   // ============================================================
//   // CHECK IF KEY EXISTS
//   // ============================================================

//   bool containsKey(
//     String key,
//   ) {
//     return box.containsKey(key);
//   }

//   // ============================================================
//   // DELETE SINGLE VALUE
//   // ============================================================

//   Future<void> remove(
//     String key,
//   ) async {
//     await box.delete(key);
//   }

//   // ============================================================
//   // CLEAR ALL LOCAL DATA
//   //
//   // Useful during logout.
//   // ============================================================

//   Future<void> clearAll() async {
//     await box.clear();
//   }

//   // ============================================================
//   // GET ALL KEYS
//   // ============================================================

//   List<dynamic> getAllKeys() {
//     return box.keys.toList();
//   }

//   // ============================================================
//   // CLOSE BOX
//   //
//   // Normally not required during normal app lifecycle.
//   // ============================================================

//   Future<void> close() async {
//     await box.close();
//   }
// }
