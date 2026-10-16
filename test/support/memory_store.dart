import 'package:geoswipe/data/progress_repository.dart';

class MemoryStore implements ProgressStore {
  MemoryStore([this.value]);
  String? value;
  bool failRead = false;
  bool failWrite = false;
  int writes = 0;
  @override
  Future<String?> read() async {
    if (failRead) throw StateError('Storage unavailable');
    return value;
  }

  @override
  Future<void> write(String value) async {
    if (failWrite) throw StateError('Storage full');
    writes++;
    this.value = value;
  }
}
