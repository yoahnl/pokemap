#ifndef RUNNER_EDITOR_UPDATER_BRIDGE_H_
#define RUNNER_EDITOR_UPDATER_BRIDGE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <atomic>
#include <memory>
#include <mutex>
#include <string>

class EditorUpdaterBridge {
 public:
  EditorUpdaterBridge(flutter::BinaryMessenger* messenger, HWND window);
  ~EditorUpdaterBridge();

  EditorUpdaterBridge(const EditorUpdaterBridge&) = delete;
  EditorUpdaterBridge& operator=(const EditorUpdaterBridge&) = delete;

  bool HandleWindowMessage(UINT message, WPARAM wparam, LPARAM lparam);

 private:
  enum class NativeEvent : WPARAM {
    kNoUpdate = 1,
    kCancelled = 2,
    kFailed = 3,
    kRestartRequested = 4,
    kInstallingAndShutdown = 5,
  };

  struct WinSparkleApi;

  static constexpr UINT kUpdaterMessage = WM_APP + 0x51;
  static std::atomic<EditorUpdaterBridge*> active_bridge_;

  static int __cdecl CanShutdownCallback();
  static void __cdecl ShutdownRequestCallback();
  static void __cdecl DidFindUpdateCallback();
  static void __cdecl DidNotFindUpdateCallback();
  static void __cdecl UpdateCancelledCallback();
  static void __cdecl ErrorCallback();

  bool LoadWinSparkle();
  void InstallMethodHandler();
  void PostEvent(NativeEvent event) const;
  void EmitEvent(const char* kind, bool terminal);
  void SetRestartReady(bool can_restart);
  std::string ActiveOperationId() const;

  HWND window_;
  HMODULE module_ = nullptr;
  std::unique_ptr<WinSparkleApi> api_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  std::atomic_bool can_restart_{false};
  std::atomic_bool restart_request_posted_{false};
  bool initialized_ = false;
  mutable std::mutex operation_mutex_;
  std::string active_operation_id_;
};

#endif  // RUNNER_EDITOR_UPDATER_BRIDGE_H_
