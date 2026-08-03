#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>

#include <cstdint>
#include <optional>
#include <string>
#include <variant>

#include "flutter/generated_plugin_registrant.h"

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

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  editor_update_channel_ = std::make_unique<
      flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "map_editor/editor_updates",
      &flutter::StandardMethodCodec::GetInstance());
  editor_update_channel_->SetMethodCallHandler(
      [](const auto& call, auto result) {
        if (call.method_name() != "openExternalUri") {
          result->NotImplemented();
          return;
        }
        const auto* arguments = std::get_if<flutter::EncodableMap>(
            call.arguments());
        if (arguments == nullptr) {
          result->Success(flutter::EncodableValue(false));
          return;
        }
        const auto uri_entry = arguments->find(flutter::EncodableValue("uri"));
        if (uri_entry == arguments->end()) {
          result->Success(flutter::EncodableValue(false));
          return;
        }
        const auto* uri = std::get_if<std::string>(&uri_entry->second);
        if (uri == nullptr || !IsTrustedGitHubUri(*uri)) {
          result->Success(flutter::EncodableValue(false));
          return;
        }
        const auto wide_uri = Utf16FromUtf8(*uri);
        if (wide_uri.empty()) {
          result->Success(flutter::EncodableValue(false));
          return;
        }
        const auto shell_result = reinterpret_cast<intptr_t>(ShellExecuteW(
            nullptr, L"open", wide_uri.c_str(), nullptr, nullptr, SW_SHOWNORMAL));
        result->Success(flutter::EncodableValue(shell_result > 32));
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    editor_update_channel_.reset();
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
