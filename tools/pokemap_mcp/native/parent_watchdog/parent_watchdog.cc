#include <thread>
#ifdef _WIN32
#include <windows.h>
#include <tlhelp32.h>
#define AVELUNE_EXPORT extern "C" __declspec(dllexport)
#else
#include <unistd.h>
#include <chrono>
#define AVELUNE_EXPORT extern "C" __attribute__((visibility("default")))
#endif

AVELUNE_EXPORT int avelune_watch_parent(int owner) {
  if (owner < 2) return 1;
#ifdef _WIN32
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) return 2;
  PROCESSENTRY32 entry = {};
  entry.dwSize = sizeof(entry);
  bool matched = false;
  if (Process32First(snapshot, &entry)) {
    do {
      if (entry.th32ProcessID == GetCurrentProcessId()) {
        matched = entry.th32ParentProcessID == static_cast<DWORD>(owner);
        break;
      }
    } while (Process32Next(snapshot, &entry));
  }
  CloseHandle(snapshot);
  if (!matched) return 3;
  HANDLE parent = OpenProcess(SYNCHRONIZE | PROCESS_QUERY_LIMITED_INFORMATION, FALSE, owner);
  if (!parent) return 4;
  FILETIME parentStart, childStart, exited, kernel, user;
  if (!GetProcessTimes(parent, &parentStart, &exited, &kernel, &user) ||
      !GetProcessTimes(GetCurrentProcess(), &childStart, &exited, &kernel, &user) ||
      CompareFileTime(&parentStart, &childStart) > 0) {
    CloseHandle(parent);
    return 5;
  }
  std::thread([parent] {
    if (WaitForSingleObject(parent, INFINITE) == WAIT_OBJECT_0) {
      CloseHandle(parent);
      ExitProcess(0);
    }
    CloseHandle(parent);
  }).detach();
#else
  if (getppid() != owner) return 3;
  std::thread([owner] {
    while (getppid() == owner) std::this_thread::sleep_for(std::chrono::milliseconds(250));
    _exit(0);
  }).detach();
#endif
  return 0;
}
