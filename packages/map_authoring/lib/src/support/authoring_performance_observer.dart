final class AuthoringPerformanceSpanName {
  const AuthoringPerformanceSpanName._();

  static const snapshot = 'snapshot';
  static const plan = 'plan';
  static const apply = 'apply';
  static const saveQueue = 'save.queue';
  static const saveEncode = 'save.encode';
}

final class AuthoringPerformanceCounterName {
  const AuthoringPerformanceCounterName._();

  static const filesystemRead = 'filesystem.read';
  static const filesystemWrite = 'filesystem.write';
  static const filesystemMetadata = 'filesystem.metadata';
  static const jsonEncode = 'json.encode';
  static const jsonDecode = 'json.decode';
  static const base64Encode = 'base64.encode';
  static const base64Decode = 'base64.decode';
  static const resourcePackAuthorizeReadBytes =
      'io.resourcePack.authorize.readBytes';
  static const resourcePackStageSourceReadBytes =
      'io.resourcePack.stageSource.readBytes';
  static const resourcePackStagePrivateCompletedWriteInputBytes =
      'io.resourcePack.stagePrivate.completedWriteInputBytes';
  static const resourcePackPostCopyVerifyReadBytes =
      'io.resourcePack.postCopyVerify.readBytes';
  static const resourcePackStageVerifyReadBytes =
      'io.resourcePack.stageVerify.readBytes';
  static const resourcePackConsumerReadAtReturnedBytes =
      'io.resourcePack.consumerReadAt.returnedBytes';
  static const resourcePackWorkerVerifyReadBytes =
      'io.resourcePack.workerVerify.readBytes';
  static const resourcePackWorkerConsumerReadAtReturnedBytes =
      'io.resourcePack.workerConsumerReadAt.returnedBytes';
  static const resourcePackWorkerCoverageIncompleteOperations =
      'io.resourcePack.workerCoverage.incompleteOperations';
  static const gatewayResourceReadBytes = 'io.gateway.resource.readBytes';
  static const gatewayVerificationReadBytes =
      'io.gateway.verification.readBytes';
  static const gatewayStagedPayloadCompletedWriteInputBytes =
      'io.gateway.stagedPayload.completedWriteInputBytes';
  static const gatewayDescriptorCompletedWriteInputBytes =
      'io.gateway.descriptor.completedWriteInputBytes';
  static const gatewayJournalCompletedWriteInputBytes =
      'io.gateway.journal.completedWriteInputBytes';
  static const journalCompletedWrites = 'journal.completedWrites';

  static const snapshotReaderReturnedBytes = 'io.snapshot.readerReturnedBytes';
  static const snapshotStreamDeliveredBytes =
      'io.snapshot.streamDeliveredBytes';
  static const harnessArchiveReadBytes = 'io.harness.archive.readBytes';
  static const harnessArchiveCompletedWriteInputBytes =
      'io.harness.archive.completedWriteInputBytes';
}

abstract interface class AuthoringPerformanceSpan {
  void finish();
}

abstract interface class AuthoringPerformanceObserver {
  AuthoringPerformanceSpan? startSpan(String name);

  void incrementCounter(String name, {int by = 1});
}
