/*
 *
 * Copyright 2015, Google Inc.
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

#import "GRPCChannelState.h"

#import "GRPCCompletionQueue.h"

@implementation GRPCChannelState {
  grpc_channel *_channel;
  GRPCCompletionQueue *_completionQueue;
  grpc_connectivity_state _lastKnownState;
}

- (instancetype)init {
  return [self initWithUnmanagedChannel:NULL];
}

// Designated initializer
- (instancetype)initWithUnmanagedChannel:(grpc_channel *)channel {
  if (!channel) {
    [NSException raise:NSInvalidArgumentException format:@"channel can't be NULL"];
  }
  if ((self = [super init])) {
    _channel = channel;
    _queue = dispatch_get_main_queue();
    _completionQueue = [[GRPCCompletionQueue alloc] init];
  }
  return self;
}

- (void)enqueueCallback {
  __weak GRPCChannelState *weakSelf = self;
  dispatch_async(_queue, ^{
    [weakSelf notifyAndSubscribe];
  });
}

- (void)notifyAndSubscribe {
  grpc_connectivity_state state = grpc_channel_check_connectivity_state(_channel, 0);
  if (_lastKnownState != state) {
    _lastKnownState = state;
    _handler(state);
  }

  __weak GRPCChannelState *weakSelf = self;
  grpc_channel_watch_connectivity_state(_channel,
                                        state,
                                        gpr_inf_future(GPR_CLOCK_REALTIME),
                                        _completionQueue.unmanagedQueue,
                                        (__bridge_retained void *)^(bool _){
                                          [weakSelf enqueueCallback];
                                        });
}

- (void)resume {
  // TODO(jcanizales): Raise an exception if handler is nil.
  _lastKnownState = grpc_channel_check_connectivity_state(_channel, 0);
  _handler(_lastKnownState);
  [self enqueueCallback];
}

- (void)pause {
}

@end
