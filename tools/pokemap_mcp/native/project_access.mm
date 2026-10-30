#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#include <unistd.h>
#include <sys/stat.h>
#include <thread>
#include <chrono>

static NSMutableDictionary<NSString *, NSURL *> *scopes;

extern "C" __attribute__((visibility("default")))
int avelune_access_grant(const char *root, const char *bookmark) {
  @autoreleasepool {
    if (!root || !bookmark) return 1;
    NSString *path = [NSString stringWithUTF8String:root];
    NSData *data = [[NSData alloc] initWithBase64EncodedString:[NSString stringWithUTF8String:bookmark] options:0];
    if (!path || !data || data.length > 1024 * 1024) return 2;
    Boolean stale = false;
    CFErrorRef error = nullptr;
    CFURLRef resolved = CFURLCreateByResolvingBookmarkData(kCFAllocatorDefault,
      (__bridge CFDataRef)data, kCFURLBookmarkResolutionWithoutUIMask |
      kCFURLBookmarkResolutionWithoutImplicitStartAccessing, nullptr, nullptr, &stale, &error);
    if (error) CFRelease(error);
    if (!resolved || stale) { if (resolved) CFRelease(resolved); return 3; }
    NSURL *url = CFBridgingRelease(resolved);
    if (![url startAccessingSecurityScopedResource]) return 5;
    struct stat expected, actual;
    if (stat(path.fileSystemRepresentation, &expected) != 0 ||
        stat(url.path.fileSystemRepresentation, &actual) != 0 ||
        !S_ISDIR(expected.st_mode) || !S_ISDIR(actual.st_mode) ||
        expected.st_dev != actual.st_dev || expected.st_ino != actual.st_ino) {
      [url stopAccessingSecurityScopedResource];
      return 4;
    }
    @synchronized(NSFileManager.class) {
      if (!scopes) scopes = [NSMutableDictionary new];
      if (scopes[path]) {
        [url stopAccessingSecurityScopedResource];
        return 0;
      }
      scopes[path] = url;
    }
    return 0;
  }
}

extern "C" __attribute__((visibility("default")))
void avelune_access_revoke_all() {
  @autoreleasepool {
    @synchronized(NSFileManager.class) {
      for (NSURL *url in scopes.allValues) [url stopAccessingSecurityScopedResource];
      [scopes removeAllObjects];
    }
  }
}

extern "C" __attribute__((visibility("default")))
int avelune_watch_parent(int owner) {
  if (owner < 2 || getppid() != owner) return 1;
  std::thread([owner] {
    while (getppid() == owner) std::this_thread::sleep_for(std::chrono::milliseconds(250));
    _exit(0);
  }).detach();
  return 0;
}
