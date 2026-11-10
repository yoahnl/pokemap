class WorldDraftInputs {
  final invalidFields = <String>{};
  String? actionError;

  bool get valid => invalidFields.isEmpty;

  bool accept(String key, bool valid) {
    if (valid) {
      invalidFields.remove(key);
    } else {
      invalidFields.add(key);
    }
    return valid;
  }
}
