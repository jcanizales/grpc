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

#import "GRPCError.h"

NSString * const kGRPCErrorDomain = @"io.grpc";

NSString * const kGRPCHeadersKey = @"io.grpc.HeadersKey";
NSString * const kGRPCTrailersKey = @"io.grpc.TrailersKey";

@implementation GRPCError
+ (instancetype)errorWithCode:(GRPCErrorCode)code {
  return [self errorWithDomain:kGRPCErrorDomain
                          code:code
                      userInfo:nil];
}

+ (instancetype)errorFromStatusCode:(grpc_status_code)statusCode details:(char *)details {
  if (statusCode == GRPC_STATUS_OK) {
    return nil;
  }
  NSString *message = [NSString stringWithCString:details encoding:NSASCIIStringEncoding];
  return [[self errorWithCode:statusCode] errorWithMessage:message];
}

+ (instancetype)cancelled {
  return [self errorWithCode:GRPCErrorCodeCancelled];
}
+ (instancetype)unknown {
  return [self errorWithCode:GRPCErrorCodeUnknown];
}
+ (instancetype)invalidArgument {
  return [self errorWithCode:GRPCErrorCodeInvalidArgument];
}
+ (instancetype)deadlineExceeded {
  return [self errorWithCode:GRPCErrorCodeDeadlineExceeded];
}
+ (instancetype)notFound {
  return [self errorWithCode:GRPCErrorCodeNotFound];
}
+ (instancetype)alreadyExists {
  return [self errorWithCode:GRPCErrorCodeAlreadyExists];
}
+ (instancetype)permissionDenied {
  return [self errorWithCode:GRPCErrorCodePermissionDenied];
}
+ (instancetype)unauthenticated {
  return [self errorWithCode:GRPCErrorCodeUnauthenticated];
}
+ (instancetype)resourceExhausted {
  return [self errorWithCode:GRPCErrorCodeResourceExhausted];
}
+ (instancetype)failedPrecondition {
  return [self errorWithCode:GRPCErrorCodeFailedPrecondition];
}
+ (instancetype)aborted {
  return [self errorWithCode:GRPCErrorCodeAborted];
}
+ (instancetype)outOfRange {
  return [self errorWithCode:GRPCErrorCodeOutOfRange];
}
+ (instancetype)unimplemented {
  return [self errorWithCode:GRPCErrorCodeUnimplemented];
}
+ (instancetype)internal {
  return [self errorWithCode:GRPCErrorCodeInternal];
}
+ (instancetype)unavailable {
  return [self errorWithCode:GRPCErrorCodeUnavailable];
}
+ (instancetype)dataLoss {
  return [self errorWithCode:GRPCErrorCodeDataLoss];
}

- (instancetype)initWithDomain:(NSString *)domain
                          code:(NSInteger)code
                      userInfo:(NSDictionary *)dict {
  if (![domain isEqual:kGRPCErrorDomain]) {
    [NSException raise:NSInvalidArgumentException
                format:@"The domain of GRPCError instances must be kGRPCErrorDomain."];
  }
  return [super initWithDomain:domain code:code userInfo:dict];
}

- (instancetype)errorWithMessage:(NSString *)message {
  GRPCMutableError *error = [GRPCMutableError errorWithError:self];
  error.localizedDescription = message;
  return error;
}

@end

@implementation GRPCMutableError {
  NSInteger _code;
  NSMutableDictionary *_userInfo;
}

+ (instancetype)errorWithError:(GRPCError *)error {
  return [[self alloc] initWithError:error];
}

- (instancetype)initWithError:(GRPCError *)error {
  return [self initWithDomain:error.domain code:error.code userInfo:error.userInfo];
}


- (instancetype)initWithDomain:(NSString *)domain
                          code:(NSInteger)code
                      userInfo:(NSDictionary *)dict {
  if ((self = [super initWithDomain:domain code:code userInfo:dict])) {
    _code = code;
    _userInfo = dict
        ? [NSMutableDictionary dictionaryWithDictionary:dict]
        : [NSMutableDictionary dictionary];
  }
  return self;
}

- (NSInteger)code {
  @synchronized (self) {
    return _code;
  }
}

- (void)setCode:(NSInteger)code {
  @synchronized (self) {
    _code = code;
  }
}

- (NSMutableDictionary *)userInfo {
  return _userInfo;
}

- (NSString *)localizedDescription {
  @synchronized (self.userInfo) {
    return self.userInfo[NSLocalizedDescriptionKey];
  }
}

- (void)setLocalizedDescription:(NSString *)localizedDescription {
  @synchronized (self.userInfo) {
    self.userInfo[NSLocalizedDescriptionKey] = [localizedDescription copy];
  }
}
@end
