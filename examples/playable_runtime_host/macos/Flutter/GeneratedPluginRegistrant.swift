//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import audioplayers_darwin
import file_picker
import file_selector_macos
import gamepads_darwin
import screen_retriever_macos
import video_player_avfoundation
import window_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  AudioplayersDarwinPlugin.register(with: registry.registrar(forPlugin: "AudioplayersDarwinPlugin"))
  FilePickerPlugin.register(with: registry.registrar(forPlugin: "FilePickerPlugin"))
  FileSelectorPlugin.register(with: registry.registrar(forPlugin: "FileSelectorPlugin"))
  GamepadsDarwinPlugin.register(with: registry.registrar(forPlugin: "GamepadsDarwinPlugin"))
  ScreenRetrieverMacosPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverMacosPlugin"))
  VideoPlayerPlugin.register(with: registry.registrar(forPlugin: "VideoPlayerPlugin"))
  WindowManagerPlugin.register(with: registry.registrar(forPlugin: "WindowManagerPlugin"))
}
