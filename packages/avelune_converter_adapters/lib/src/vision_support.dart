import 'package:avelune_converter_core/avelune_converter_core.dart';

abstract interface class VisionSecretVault {
  Future<String?> read();
  Future<void> write(String secret);
  Future<void> delete();
}

final class VisionPricing {
  const VisionPricing(
      {required this.model,
      required this.inputMicrosPerMillionTokens,
      required this.outputMicrosPerMillionTokens,
      required this.verifiedAt,
      required this.validUntil,
      required this.sourceUrl});
  final String model;
  final int inputMicrosPerMillionTokens;
  final int outputMicrosPerMillionTokens;
  final DateTime verifiedAt;
  final DateTime validUntil;
  final String sourceUrl;
}

final class VisionAssistancePolicy {
  const VisionAssistancePolicy(
      {this.maxRequests = 20,
      this.maxRetries = 1,
      this.maxCostMicros,
      this.pricing,
      this.maxInputTokensPerAttempt = 131072,
      this.maxRequestBytes = 12582912,
      this.maxResponseBytes = 262144,
      this.timeout = const Duration(seconds: 45),
      this.retryDelay = const Duration(milliseconds: 250)});
  final int maxRequests;
  final int maxRetries;
  final int? maxCostMicros;
  final VisionPricing? pricing;
  final int maxInputTokensPerAttempt;
  final int maxRequestBytes;
  final int maxResponseBytes;
  final Duration timeout;
  final Duration retryDelay;
}

final class VisionStoreLimits {
  const VisionStoreLimits(
      {this.maxLedgerBytes = 1048576,
      this.maxAttempts = 2048,
      this.maxCacheEntries = 64,
      this.maxCacheBytes = 16777216,
      this.maxEntryBytes = 262144,
      this.cacheTtl = const Duration(days: 7)});
  final int maxLedgerBytes;
  final int maxAttempts;
  final int maxCacheEntries;
  final int maxCacheBytes;
  final int maxEntryBytes;
  final Duration cacheTtl;
}

final class VisionTokenUsage {
  const VisionTokenUsage(
      {required this.inputTokens, required this.outputTokens});
  final int inputTokens;
  final int outputTokens;
}

final class VisionUsageSnapshot {
  const VisionUsageSnapshot(
      {required this.requestCount,
      required this.retryCount,
      required this.unknownAttempts,
      required this.knownCostMicros,
      required this.reservedCostMicros});
  final int requestCount;
  final int retryCount;
  final int unknownAttempts;
  final int? knownCostMicros;
  final int? reservedCostMicros;
}

final class VisionAttemptReservation {
  const VisionAttemptReservation(
      {required this.id, required this.estimatedCostMicros});
  final ConverterId id;
  final int? estimatedCostMicros;
}

final class VisionAssistanceException implements Exception {
  const VisionAssistanceException(this.code);
  final String code;
  @override
  String toString() => code;
}
