/*
 *
 * Copyright 2016, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <CoreFoundation/CoreFoundation.h>

#import "GRPCConnectivityMonitor.h"

#import <RxLibrary/GRXWriteable.h>
#import <RxLibrary/GRXWriter+Immediate.h>
#import <RxLibrary/GRXWriter+Transformations.h>


#pragma mark Flags

@implementation GRXReachabilityFlags {
  SCNetworkReachabilityFlags _flags;
}

+ (instancetype)flagsWithFlags:(SCNetworkReachabilityFlags)flags {
  return [[self alloc] initWithFlags:flags];
}

- (instancetype)initWithFlags:(SCNetworkReachabilityFlags)flags {
  if ((self = [super init])) {
    _flags = flags;
  }
  return self;
}

/*
 * One accessor method implementation per flag. Example:

- (BOOL)isCell { \
  return !!(_flags & kSCNetworkReachabilityFlagsIsWWAN); \
}

 */
#define GRX_ITEM(methodName, FlagName) \
- (BOOL)methodName { \
  return !!(_flags & kSCNetworkReachabilityFlags ## FlagName); \
}
#include "GRXReachabilityFlagNames.xmacro.h"
#undef GRX_ITEM

- (BOOL)isHostReachable {
  // Note: connectionOnDemand means it'll be reachable only if using the CFSocketStream API or APIs
  // on top of it.
  // connectionRequired means we can't tell until a connection is attempted (e.g. for VPN on
  // demand).
  return self.reachable && !self.interventionRequired && !self.connectionOnDemand;
}

- (NSString *)description {
  NSMutableArray *activeOptions = [NSMutableArray arrayWithCapacity:9];

  /*
   * For each flag, add its name to the array if it's on. Example:

  if (self.isCell) {
    [activeOptions addObject:@"isCell"];
  }

   */
#define GRX_ITEM(methodName, FlagName) \
  if (self.methodName) { \
    [activeOptions addObject:@#methodName]; \
  }
#include "GRXReachabilityFlagNames.xmacro.h"
#undef GRX_ITEM

  return activeOptions.count == 0 ? @"(none)" : [activeOptions componentsJoinedByString:@", "];
}

- (BOOL)isEqual:(id)object {
  return [object isKindOfClass:self.class] &&
      _flags == ((GRXReachabilityFlags *)object)->_flags;
}

@end


#pragma mark Reachability

@interface GRPCConnectivityMonitor ()
- (void)notifyNewFlags:(SCNetworkReachabilityFlags)flags;
@end

static void ReachabilityCallback(SCNetworkReachabilityRef target,
                                 SCNetworkReachabilityFlags flags,
                                 void *info) {
  #pragma unused (target)
  GRPCConnectivityMonitor *reachability = (__bridge GRPCConnectivityMonitor *)info;
  [reachability notifyNewFlags:flags];
}

@implementation GRPCConnectivityMonitor {
	SCNetworkReachabilityRef _reachabilityRef;
  GRXReachabilityFlags *_lastKnownFlags;
}

+ (void)handleLossForHost:(NSString *)host withHandler:(void (^)())handler {
  __block GRPCConnectivityMonitor *reachability = [self monitorWithHost:host];
  [reachability handleLossWithHandler:^{
    handler();
    NSLog(@"Deallocating anonymous connectivity monitor to host %@.", host);
    reachability = nil;
  }];
}

- (void)handleLossWithHandler:(void (^)())handler {
  _handler = ^(GRXReachabilityFlags *flags) {
    if (!flags.isHostReachable) {
      handler();
    }
  };
  [self resume];
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability {
  if (!reachability) {
    return nil;
  }
  if ((self = [super init])) {
    _reachabilityRef = CFRetain(reachability);
    _queue = dispatch_get_main_queue();
  }
  return self;
}

+ (nonnull instancetype)monitorWithHost:(nonnull NSString *)host {
  const char *hostName = host.UTF8String;
  if (!hostName) {
    [NSException raise:NSInvalidArgumentException
                format:@"host.UTF8String returns NULL for %@", host];
  }
	SCNetworkReachabilityRef reachability =
      SCNetworkReachabilityCreateWithName(NULL, hostName);

  GRPCConnectivityMonitor *returnValue = [[self alloc] initWithReachability:reachability];
  if (reachability) {
    CFRelease(reachability);
  }
	return returnValue;
}

- (void)notifyNewFlags:(SCNetworkReachabilityFlags)flags {
  GRXReachabilityFlags *newFlags = [[GRXReachabilityFlags alloc] initWithFlags:flags];
  if ([_lastKnownFlags isEqual:newFlags]) {
    return;
  }
  _lastKnownFlags = newFlags;
  _handler(newFlags);
}

- (void)resume {
  SCNetworkReachabilityContext context = {
    .version = 0,
    .info = (__bridge_retained void *)self,
    .release = CFRelease
  };

  SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityCallback, &context);
  SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, _queue);
}

- (void)pause {
  SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
  SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, NULL);
}

- (void)setQueue:(dispatch_queue_t)queue {
  _queue = queue ?: dispatch_get_main_queue();
}

- (void)dealloc {
  [self pause];
  CFRelease(_reachabilityRef);
}

- (GRXReachabilityFlags *)currentFlags {
	SCNetworkReachabilityFlags flags;
  if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
    _lastKnownFlags = [[GRXReachabilityFlags alloc] initWithFlags:flags];
  }
  return _lastKnownFlags;
}

@end
