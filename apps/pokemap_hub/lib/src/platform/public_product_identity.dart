import 'dart:io';

String publicProductNameForOperatingSystem(String operatingSystem) {
  return switch (operatingSystem) {
    'android' || 'ios' => 'Avelune',
    _ => 'PokeMap Hub',
  };
}

String get publicProductName =>
    publicProductNameForOperatingSystem(Platform.operatingSystem);
