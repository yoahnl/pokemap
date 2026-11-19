package com.yoahnl.avelune.player.runtime

import com.yoahnl.avelune.player.R
import com.yoahnl.avelune.player.localization.NativeFailure

internal fun runtimeChannelFailure(method: String, code: String, details: Any?): NativeFailure {
    val version = (details as? Map<*, *>)?.get("gameVersion") as? String
    val resource = when (code) {
        "installation.releaseConflict" -> if (version.isNullOrBlank()) {
            R.string.error_install_release_conflict
        } else {
            R.string.error_install_release_conflict_version
        }
        "installation.cancelled" -> R.string.error_install_cancelled
        "installation.incompatible" -> R.string.error_install_incompatible
        "installation.insufficientDisk" -> R.string.error_install_disk
        "installation.integrityFailed", "installation.sourceChanged" -> R.string.error_install_integrity
        "installation.notAnUpdate" -> R.string.error_install_not_update
        "installation.alreadyInstalled" -> R.string.error_install_already_installed
        "installation.extractionFailed" -> R.string.error_install_extraction
        "installation.smokeFailed" -> R.string.error_install_smoke
        "installation.savePreparationFailed" -> R.string.error_install_save_preparation
        "installation.unsafePath" -> R.string.error_install_unsafe_path
        "installation.storageFailure" -> R.string.error_install_storage
        "installation.operationInProgress" -> R.string.error_install_in_progress
        "installation.notInstalled", "gameNotInstalled" -> R.string.error_game_not_installed
        "installation.currentPointerCorrupt", "installation.receiptMissing", "installation.installationCorrupt" ->
            R.string.error_install_corrupt
        "installation.repairIdentityMismatch" -> R.string.error_install_repair_identity
        "installation.rollbackConfirmationRequired" -> R.string.error_install_rollback_confirmation
        "installation.rollbackSnapshotUnavailable" -> R.string.error_install_rollback_snapshot
        "installation.uninstallFallbackRequired" -> R.string.error_uninstall_fallback
        "gameAlreadyPlaying" -> R.string.error_game_already_playing
        else -> when (method) {
            "listGames" -> R.string.error_library_load
            "installGame" -> R.string.error_game_import
            "uninstallGame" -> R.string.error_game_uninstall
            "playGame" -> R.string.error_game_start
            "stopGame" -> R.string.error_game_stop
            else -> R.string.error_runtime_action
        }
    }
    val arguments = if (resource == R.string.error_install_release_conflict_version) listOf(requireNotNull(version)) else emptyList()
    return NativeFailure(resource, code = code.takeUnless { it == "error" || it.isBlank() }, arguments = arguments)
}
