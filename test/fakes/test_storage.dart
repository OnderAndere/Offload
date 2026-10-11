import 'package:drift/native.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/storage/app_storage.dart';

/// An [AppStorage] on an unencrypted in-memory database, for widget tests.
Future<AppStorage> openTestStorage([AppDatabase? database]) =>
    AppStorage.load(database ?? AppDatabase(NativeDatabase.memory()));
