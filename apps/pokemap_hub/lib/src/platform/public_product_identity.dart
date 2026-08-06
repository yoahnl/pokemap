/// Public product identity shown inside the app.
///
/// Desktop used to answer "PokeMap Hub" because it ran a separate authoring
/// interface. It now renders the same Avelune console as mobile, so the name it
/// shows is the same too.
///
/// This is the in-app identity only. The desktop bundle name, its Xcode
/// PRODUCT_NAME and the notarized `.app` are a distribution contract and are
/// deliberately untouched.
String publicProductNameForOperatingSystem(String operatingSystem) => 'Avelune';

String get publicProductName => publicProductNameForOperatingSystem('');
