#include <node_api.h>
#include <string>

extern "C" int avelune_access_grant(const char *, const char *);
extern "C" void avelune_access_revoke_all();

static bool string_value(napi_env env, napi_value value, std::string &output) {
  size_t size = 0;
  if (napi_get_value_string_utf8(env, value, nullptr, 0, &size) != napi_ok || size > 2 * 1024 * 1024) return false;
  output.resize(size + 1);
  if (napi_get_value_string_utf8(env, value, output.data(), size + 1, &size) != napi_ok) return false;
  output.resize(size);
  return output.find('\0') == std::string::npos;
}

static napi_value grant(napi_env env, napi_callback_info info) {
  size_t count = 2;
  napi_value args[2], result;
  napi_get_cb_info(env, info, &count, args, nullptr, nullptr);
  std::string root, bookmark;
  int status = count == 2 && string_value(env, args[0], root) && string_value(env, args[1], bookmark)
    ? avelune_access_grant(root.c_str(), bookmark.c_str()) : 1;
  napi_create_int32(env, status, &result);
  return result;
}

static napi_value revoke(napi_env env, napi_callback_info info) {
  avelune_access_revoke_all();
  napi_value result;
  napi_get_undefined(env, &result);
  return result;
}

static napi_value initialize(napi_env env, napi_value exports) {
  napi_property_descriptor properties[] = {
    {"grant", nullptr, grant, nullptr, nullptr, nullptr, napi_default, nullptr},
    {"revokeAll", nullptr, revoke, nullptr, nullptr, nullptr, napi_default, nullptr},
  };
  napi_define_properties(env, exports, 2, properties);
  return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, initialize)
