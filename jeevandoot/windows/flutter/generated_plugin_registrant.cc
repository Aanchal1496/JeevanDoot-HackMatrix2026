//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <speech_to_text_windows/speech_to_text_windows.h>
#include <flutter_tts/flutter_tts_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  SpeechToTextWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SpeechToTextWindows"));
  FlutterTtsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterTtsPlugin"));
}
