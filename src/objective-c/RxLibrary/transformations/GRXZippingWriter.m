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

#import "GRXZippingWriter.h"

@implementation GRXZippingWriter {
  NSDictionary *_writers;
  NSMutableDictionary *_nextValues;
  NSMutableSet *_pendingKeys;
  id<GRXWriteable> _writeable;
  BOOL _writersDone;
}
+ (instancetype)writerWithWriters:(NSDictionary *)writers {
  return [[self alloc] initWithWriters:writers];
}
- (instancetype)init {
  return [self initWithWriters:nil];
}
- (instancetype)initWithWriters:(NSDictionary *)writers {
  if (!writers.count) {
    return nil;
  }
  if ((self = [super init])) {
    _writers = writers;
    _nextValues = [NSMutableDictionary dictionaryWithCapacity:_writers.count];
    _pendingKeys = [NSMutableSet setWithArray:_writers.allKeys];
  }
  return self;
}

- (void)startWithWriteable:(id<GRXWriteable>)writeable {
  for (id key in _writers) {
    GRXWriter *writer = _writers[key]; // RENAME TO EVENTHANDLER
    [writer startWithWriteable:[GRXWriteable writeableWithStreamHandler:^(BOOL done, id value, NSError *error) {
      BOOL shouldResumeWriters = NO;

      @synchronized(self) {
        if (_writersDone) {
          if (!done) {
            writer.state = GRXWriterStateFinished;
          }
          return;
        }
        if (value) {
          writer.state = GRXWriterStatePaused;
          _nextValues[key] = value;
          [_pendingKeys removeObject:key];
          if (!_pendingKeys.count) {
            // The next round is ready.
            [writeable writeValue:[NSDictionary dictionaryWithDictionary:_nextValues]];

            // Reset pendingWriters and nextValues
            _nextValues = [NSMutableDictionary dictionaryWithCapacity:_writers.count];
            _pendingKeys = [NSMutableSet setWithArray:_writers.allKeys];

            // Do it outside the @synchronized(self) block, to prevent a deadlock!
            shouldResumeWriters = YES;
          }
        }
      }

      // Resume the writers that are paused (one might have gone to Finished and just be waiting at
      // the start of this critical section).
      if (shouldResumeWriters) {
        for (id key in _writers) {
          GRXWriter *writer = _writers[key];
          @synchronized(writer) {
            if (writer.state == GRXWriterStatePaused) {
              writer.state = GRXWriterStateStarted;
            }
          }
        }
      }

      @synchronized(self) {
        if (done && !_writersDone) {
          _writersDone = YES;
          [writeable writesFinishedWithError:error];
        }
      }
    }]];
  }
}

// TODO(jcanizales): Flow control!
@end
