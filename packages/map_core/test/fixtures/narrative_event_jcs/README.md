# Narrative Event JCS vectors

This fixture pack makes the Event V2 canonical JSON and SHA-256 contract
reproducible without network access or dynamically installed tools.

Sources:

- RFC 8785 sections 3.2.2 and 3.2.3 for number serialization, string
  serialization, and UTF-16 property ordering;
- RFC 8785 Appendix B and RFC 7493 I-JSON constraints for finite numbers,
  safe integers, Unicode scalar sequences, and duplicate member rejection;
- PokeMap NS-EVENT-V2 Phase B committed claim and legacy-source fingerprint
  goldens for project-specific preimages.

The `official/` pairs are copied from
`cyberphone/json-canonicalization/testdata` at commit
`19d51d7fe467d4706a3ff08adf8a748f29fc21e0`. That upstream repository
publishes them under Apache License 2.0. Inputs are paired with the official
UTF-8 output expressed as hexadecimal bytes so control characters remain
reviewable in Git.

`vectors.json` stores the original structured input or raw JSON source, the
expected canonical form, the expected SHA-256 digest, and the provenance of
each vector. Run either:

```text
dart test test/narrative_event_claim_fingerprints_test.dart
dart run tool/verify_narrative_event_jcs_vectors.dart
```

The tool is a convenience verifier. The normal Dart test is authoritative and
requires no Node.js installation.

An additional optional oracle replays the upstream deterministic IEEE-754
sequence and compares 200,000 Dart serializations with Node.js. It is pinned to
checksum `b4294dfb5683285868d038434aaf0d0dfd0fd0cdb7570d79107757f9fd500b57`
and was verified with Node.js `v26.3.1`:

```text
dart run tool/verify_narrative_event_jcs_number_oracle.dart
```
