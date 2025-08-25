import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class IsarService {
  static Isar? _isar;
  static Future<Isar> open({List<CollectionSchema<dynamic>> schemas = const []}) async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationSupportDirectory();
    _isar = await Isar.open(schemas, directory: dir.path, inspector: false);
    return _isar!;
  }
}
