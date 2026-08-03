#include "editor_updater_bridge.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>
#include <winsparkle.h>

#include <cstdint>
#include <filesystem>
#include <optional>
#include <utility>
#include <variant>

namespace {

std::wstring Utf16FromUtf8(const std::string& utf8) {
  if (utf8.empty()) {
    return std::wstring();
  }
  const int length = MultiByteToWideChar(
      CP_UTF8, MB_ERR_INVALID_CHARS, utf8.data(),
      static_cast<int>(utf8.size()), nullptr, 0);
  if (length <= 0) {
    return std::wstring();
  }
  std::wstring utf16(length, L'\0');
  if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8.data(),
                          static_cast<int>(utf8.size()), utf16.data(),
                          length) <= 0) {
    return std::wstring();
  }
  return utf16;
}

bool IsTrustedGitHubUri(const std::string& uri) {
  constexpr char kGithubPrefix[] = "https://github.com/";
  return uri.rfind(kGithubPrefix, 0) == 0;
}

const flutter::EncodableMap* MapArguments(
    const flutter::MethodCall<flutter::EncodableValue>& call) {
  return std::get_if<flutter::EncodableMap>(call.arguments());
}

template <typename Value>
std::optional<Value> Argument(const flutter::EncodableMap* arguments,
                              const char* key) {
  if (arguments == nullptr) {
    return std::nullopt;
  }
  const auto entry = arguments->find(flutter::EncodableValue(key));
  if (entry == arguments->end()) {
    return std::nullopt;
  }
  const auto* value = std::get_if<Value>(&entry->second);
  if (value == nullptr) {
    return std::nullopt;
  }
  return *value;
}

template <typename Procedure>
bool LoadProcedure(HMODULE module, const char* name, Procedure* procedure) {
  *procedure = reinterpret_cast<Procedure>(GetProcAddress(module, name));
  return *procedure != nullptr;
}

std::filesystem::path ExecutableDirectory() {
  std::wstring executable(MAX_PATH, L'\0');
  const DWORD length = GetModuleFileNameW(
      nullptr, executable.data(), static_cast<DWORD>(executable.size()));
  if (length == 0 || length >= executable.size()) {
    return std::filesystem::path();
  }
  executable.resize(length);
  return std::filesystem::path(executable).parent_path();
}

}  // namespace

struct EditorUpdaterBridge::WinSparkleApi {
  decltype(&win_sparkle_init) init = nullptr;
  decltype(&win_sparkle_cleanup) cleanup = nullptr;
  decltype(&win_sparkle_set_automatic_check_for_updates) set_automatic =
      nullptr;
  decltype(&win_sparkle_set_can_shutdown_callback) set_can_shutdown = nullptr;
  decltype(&win_sparkle_set_shutdown_request_callback) set_shutdown_request =
      nullptr;
  decltype(&win_sparkle_set_did_find_update_callback) set_did_find = nullptr;
  decltype(&win_sparkle_set_did_not_find_update_callback) set_did_not_find =
      nullptr;
  decltype(&win_sparkle_set_update_cancelled_callback) set_cancelled = nullptr;
  decltype(&win_sparkle_set_error_callback) set_error = nullptr;
  decltype(&win_sparkle_check_update_with_ui) check_with_ui = nullptr;
};

std::atomic<EditorUpdaterBridge*> EditorUpdaterBridge::active_bridge_{nullptr};

EditorUpdaterBridge::EditorUpdaterBridge(flutter::BinaryMessenger* messenger,
                                         HWND window)
    : window_(window),
      channel_(std::make_unique<
               flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "map_editor/editor_updates",
          &flutter::StandardMethodCodec::GetInstance())) {
  InstallMethodHandler();
  initialized_ = LoadWinSparkle();
}

EditorUpdaterBridge::~EditorUpdaterBridge() {
  if (channel_) {
    channel_->SetMethodCallHandler(nullptr);
  }
  if (initialized_ && api_) {
    api_->cleanup();
  }
  if (active_bridge_.load() == this) {
    active_bridge_.store(nullptr);
  }
  api_.reset();
  if (module_ != nullptr) {
    FreeLibrary(module_);
    module_ = nullptr;
  }
}

bool EditorUpdaterBridge::LoadWinSparkle() {
#if !POKEMAP_WINSPARKLE_CONFIGURED
  return false;
#else
  const auto directory = ExecutableDirectory();
  if (directory.empty()) {
    return false;
  }
  const auto dll_path = directory / L"WinSparkle.dll";
  module_ = LoadLibraryExW(
      dll_path.c_str(), nullptr,
      LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);
  if (module_ == nullptr) {
    return false;
  }

  auto api = std::make_unique<WinSparkleApi>();
  const bool loaded =
      LoadProcedure(module_, "win_sparkle_init", &api->init) &&
      LoadProcedure(module_, "win_sparkle_cleanup", &api->cleanup) &&
      LoadProcedure(module_, "win_sparkle_set_automatic_check_for_updates",
                    &api->set_automatic) &&
      LoadProcedure(module_, "win_sparkle_set_can_shutdown_callback",
                    &api->set_can_shutdown) &&
      LoadProcedure(module_, "win_sparkle_set_shutdown_request_callback",
                    &api->set_shutdown_request) &&
      LoadProcedure(module_, "win_sparkle_set_did_find_update_callback",
                    &api->set_did_find) &&
      LoadProcedure(module_, "win_sparkle_set_did_not_find_update_callback",
                    &api->set_did_not_find) &&
      LoadProcedure(module_, "win_sparkle_set_update_cancelled_callback",
                    &api->set_cancelled) &&
      LoadProcedure(module_, "win_sparkle_set_error_callback",
                    &api->set_error) &&
      LoadProcedure(module_, "win_sparkle_check_update_with_ui",
                    &api->check_with_ui);
  if (!loaded) {
    return false;
  }

  api_ = std::move(api);
  active_bridge_.store(this);
  api_->set_automatic(0);
  api_->set_can_shutdown(&EditorUpdaterBridge::CanShutdownCallback);
  api_->set_shutdown_request(&EditorUpdaterBridge::ShutdownRequestCallback);
  api_->set_did_find(&EditorUpdaterBridge::DidFindUpdateCallback);
  api_->set_did_not_find(&EditorUpdaterBridge::DidNotFindUpdateCallback);
  api_->set_cancelled(&EditorUpdaterBridge::UpdateCancelledCallback);
  api_->set_error(&EditorUpdaterBridge::ErrorCallback);
  api_->init();
  return true;
#endif
}

void EditorUpdaterBridge::InstallMethodHandler() {
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        const auto* arguments = MapArguments(call);
        if (call.method_name() == "openExternalUri") {
          const auto uri = Argument<std::string>(arguments, "uri");
          if (!uri || !IsTrustedGitHubUri(*uri)) {
            result->Success(flutter::EncodableValue(false));
            return;
          }
          const auto wide_uri = Utf16FromUtf8(*uri);
          if (wide_uri.empty()) {
            result->Success(flutter::EncodableValue(false));
            return;
          }
          const auto shell_result = reinterpret_cast<intptr_t>(ShellExecuteW(
              nullptr, L"open", wide_uri.c_str(), nullptr, nullptr,
              SW_SHOWNORMAL));
          result->Success(flutter::EncodableValue(shell_result > 32));
          return;
        }
        if (call.method_name() == "setRestartReady") {
          const auto can_restart = Argument<bool>(arguments, "canRestart");
          if (!can_restart) {
            result->Error("invalid_args", "Expected {canRestart: bool}.");
            return;
          }
          SetRestartReady(*can_restart);
          result->Success();
          return;
        }
        if (call.method_name() == "respondToRestart") {
          const auto operation_id =
              Argument<std::string>(arguments, "operationId");
          const auto can_restart = Argument<bool>(arguments, "canRestart");
          if (!operation_id || *operation_id != ActiveOperationId() ||
              !can_restart) {
            result->Error("invalid_args",
                          "Expected the active operation and canRestart.");
            return;
          }
          SetRestartReady(*can_restart);
          result->Success();
          return;
        }
        if (call.method_name() == "openUpdateFlow") {
          const auto operation_id =
              Argument<std::string>(arguments, "operationId");
          if (!operation_id || operation_id->empty()) {
            result->Error("invalid_args", "Expected {operationId: String}.");
            return;
          }
          if (!initialized_ || !api_) {
            result->Error("native_update_failed",
                          "WinSparkle or its public key is unavailable.");
            return;
          }
          {
            const std::lock_guard<std::mutex> lock(operation_mutex_);
            active_operation_id_ = *operation_id;
          }
          restart_request_posted_.store(false);
          api_->check_with_ui();
          result->Success();
          return;
        }
        result->NotImplemented();
      });
}

bool EditorUpdaterBridge::HandleWindowMessage(UINT message, WPARAM wparam,
                                              LPARAM lparam) {
  if (message != kUpdaterMessage) {
    return false;
  }
  const auto event = static_cast<NativeEvent>(wparam);
  switch (event) {
    case NativeEvent::kNoUpdate:
      EmitEvent("noUpdate", true);
      break;
    case NativeEvent::kCancelled:
      EmitEvent("cancelled", true);
      break;
    case NativeEvent::kFailed:
      EmitEvent("failed", true);
      break;
    case NativeEvent::kRestartRequested:
      EmitEvent("restartRequested", false);
      break;
    case NativeEvent::kInstallingAndShutdown:
      EmitEvent("installing", false);
      PostMessageW(window_, WM_CLOSE, 0, 0);
      break;
  }
  return true;
}

void EditorUpdaterBridge::PostEvent(NativeEvent event) const {
  PostMessageW(window_, kUpdaterMessage, static_cast<WPARAM>(event), 0);
}

void EditorUpdaterBridge::EmitEvent(const char* kind, bool terminal) {
  const auto operation_id = ActiveOperationId();
  if (operation_id.empty()) {
    return;
  }
  channel_->InvokeMethod(
      "updateEvent",
      std::make_unique<flutter::EncodableValue>(flutter::EncodableMap{
          {flutter::EncodableValue("kind"), flutter::EncodableValue(kind)},
          {flutter::EncodableValue("operationId"),
           flutter::EncodableValue(operation_id)},
      }));
  if (terminal) {
    const std::lock_guard<std::mutex> lock(operation_mutex_);
    active_operation_id_.clear();
    restart_request_posted_.store(false);
  }
}

void EditorUpdaterBridge::SetRestartReady(bool can_restart) {
  can_restart_.store(can_restart);
}

std::string EditorUpdaterBridge::ActiveOperationId() const {
  const std::lock_guard<std::mutex> lock(operation_mutex_);
  return active_operation_id_;
}

int __cdecl EditorUpdaterBridge::CanShutdownCallback() {
  auto* bridge = active_bridge_.load();
  if (bridge == nullptr) {
    return FALSE;
  }
  if (!bridge->restart_request_posted_.exchange(true)) {
    bridge->PostEvent(NativeEvent::kRestartRequested);
  }
  return bridge->can_restart_.load() ? TRUE : FALSE;
}

void __cdecl EditorUpdaterBridge::ShutdownRequestCallback() {
  if (auto* bridge = active_bridge_.load()) {
    bridge->PostEvent(NativeEvent::kInstallingAndShutdown);
  }
}

void __cdecl EditorUpdaterBridge::DidFindUpdateCallback() {}

void __cdecl EditorUpdaterBridge::DidNotFindUpdateCallback() {
  if (auto* bridge = active_bridge_.load()) {
    bridge->PostEvent(NativeEvent::kNoUpdate);
  }
}

void __cdecl EditorUpdaterBridge::UpdateCancelledCallback() {
  if (auto* bridge = active_bridge_.load()) {
    bridge->PostEvent(NativeEvent::kCancelled);
  }
}

void __cdecl EditorUpdaterBridge::ErrorCallback() {
  if (auto* bridge = active_bridge_.load()) {
    bridge->PostEvent(NativeEvent::kFailed);
  }
}
