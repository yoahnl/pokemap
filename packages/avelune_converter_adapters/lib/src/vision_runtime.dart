import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'vision_support.dart';

void requireVision(bool condition, String code) {
  if (!condition) throw VisionAssistanceException(code);
}

void checkVisionCancellation(ScanCancellation cancellation) =>
    requireVision(!cancellation.isCancelled, 'vision.cancelled');

void validateVisionPolicy(VisionAssistancePolicy policy) {
  requireVision(
      policy.maxRequests > 0 &&
          policy.maxRequests <= 2048 &&
          policy.maxRetries >= 0 &&
          policy.maxRetries <= 3 &&
          policy.maxInputTokensPerAttempt > 0 &&
          policy.maxInputTokensPerAttempt <= 2097152 &&
          policy.maxRequestBytes > 0 &&
          policy.maxRequestBytes <= 12582912 &&
          policy.maxResponseBytes > 0 &&
          policy.maxResponseBytes <= 1048576 &&
          policy.timeout > Duration.zero &&
          policy.timeout <= const Duration(seconds: 60) &&
          policy.retryDelay >= Duration.zero &&
          policy.retryDelay <= const Duration(seconds: 2) &&
          (policy.maxCostMicros == null ||
              (policy.maxCostMicros! >= 0 &&
                  policy.maxCostMicros! <= 1000000000000)),
      'vision.policy');
}

VisionPricing? effectiveVisionPricing(
    VisionAssistancePolicy policy, String model, DateTime now) {
  validateVisionPolicy(policy);
  final pricing = policy.pricing;
  final uri = pricing == null ? null : Uri.tryParse(pricing.sourceUrl);
  final valid = pricing != null &&
      pricing.model == model &&
      pricing.inputMicrosPerMillionTokens >= 0 &&
      pricing.inputMicrosPerMillionTokens <= 1000000000000 &&
      pricing.outputMicrosPerMillionTokens >= 0 &&
      pricing.outputMicrosPerMillionTokens <= 1000000000000 &&
      !pricing.verifiedAt.isAfter(now) &&
      pricing.validUntil.isAfter(now) &&
      pricing.validUntil.isAfter(pricing.verifiedAt) &&
      pricing.validUntil.difference(pricing.verifiedAt) <=
          const Duration(days: 31) &&
      uri?.scheme == 'https' &&
      const {'developers.openai.com', 'openai.com', 'platform.openai.com'}
          .contains(uri?.host) &&
      uri!.userInfo.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment;
  requireVision(
      valid || policy.maxCostMicros == null, 'vision.pricingUnavailable');
  return valid ? pricing : null;
}

int visionTokenCost(VisionPricing pricing, int inputTokens, int outputTokens) {
  requireVision(
      inputTokens >= 0 &&
          inputTokens <= 2097152 &&
          outputTokens >= 0 &&
          outputTokens <= 2097152,
      'vision.usage');
  return (inputTokens * pricing.inputMicrosPerMillionTokens +
          outputTokens * pricing.outputMicrosPerMillionTokens +
          999999) ~/
      1000000;
}

Object? decodeVisionJson(List<int> bytes, int maxBytes) {
  requireVision(bytes.length <= maxBytes, 'vision.jsonQuota');
  final text = utf8.decode(bytes);
  var quoted = false;
  var escaped = false;
  var depth = 0;
  var nodes = 0;
  for (final unit in text.codeUnits) {
    if (quoted) {
      if (escaped) {
        escaped = false;
      } else if (unit == 92) {
        escaped = true;
      } else if (unit == 34) {
        quoted = false;
      }
    } else if (unit == 34) {
      quoted = true;
    } else if (unit == 123 || unit == 91) {
      requireVision(++depth <= 32, 'vision.jsonQuota');
    } else if (unit == 125 || unit == 93) {
      depth--;
    } else if (unit == 44) {
      requireVision(++nodes <= 50000, 'vision.jsonQuota');
    }
  }
  requireVision(depth == 0 && !quoted, 'vision.json');
  return jsonDecode(text);
}

Map<String, Object?> visionObject(Object? value) {
  requireVision(value is Map<String, dynamic>, 'vision.document');
  return Map<String, Object?>.from(value as Map);
}

void visionKeys(Map<String, Object?> json, Set<String> keys) => requireVision(
    json.length == keys.length && json.keys.every(keys.contains),
    'vision.document');

bool visionContainsSecret(Object? input, String secret) {
  var nodes = 0;
  bool visit(Object? value, int depth) {
    requireVision(++nodes <= 50000 && depth <= 32, 'vision.jsonQuota');
    if (value is String) return value.contains(secret);
    if (value is List) return value.any((item) => visit(item, depth + 1));
    if (value is Map) {
      return value.entries.any((entry) =>
          visit(entry.key, depth + 1) || visit(entry.value, depth + 1));
    }
    return false;
  }

  return visit(input, 0);
}
