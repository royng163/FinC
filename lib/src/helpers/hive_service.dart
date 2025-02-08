import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  Future<Box<T>> openBox<T>(String boxName) async {
    return await Hive.openBox<T>(boxName);
  }

  // Save data to a box
  Future<void> setData<T>(String boxName, String key, T value) async {
    final box = await openBox<T>(boxName);
    await box.put(key, value);
  }

  // Retrieve data from a box
  Future<T?> getData<T>(String boxName, String key) async {
    final box = await openBox<T>(boxName);
    return box.get(key);
  }
}
