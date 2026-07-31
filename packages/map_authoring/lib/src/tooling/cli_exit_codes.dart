/// Sysexits-style process codes used by the PokeMap authoring CLI.
abstract final class AuthoringCliExitCodes {
  static const int success = 0;
  static const int usage = 64;
  static const int dataError = 65;
  static const int noInput = 66;
  static const int software = 70;
  static const int ioError = 74;
  static const int config = 78;
}
