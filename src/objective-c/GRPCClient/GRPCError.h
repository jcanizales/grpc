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

#import <Foundation/Foundation.h>
#include <grpc/grpc.h>

/** Domain of NSError objects produced by gRPC. */
extern NSString *const kGRPCErrorDomain;

/**
 * gRPC error codes.
 * Note that a few of these are never produced by the gRPC libraries, but are of general utility for
 * server applications to produce.
 */
typedef NS_ENUM(NSUInteger, GRPCErrorCode) {
  /** The operation was cancelled (typically by the caller). */
  GRPCErrorCodeCancelled = 1,

  /**
   * Unknown error. Errors raised by APIs that do not return enough error information may be
   * converted to this error.
   */
  GRPCErrorCodeUnknown = 2,

  /**
   * The client specified an invalid argument. Note that this differs from FAILED_PRECONDITION.
   * INVALID_ARGUMENT indicates arguments that are problematic regardless of the state of the
   * server (e.g., a malformed file name).
   */
  GRPCErrorCodeInvalidArgument = 3,

  /**
   * Deadline expired before operation could complete. For operations that change the state of the
   * server, this error may be returned even if the operation has completed successfully. For
   * example, a successful response from the server could have been delayed long enough for the
   * deadline to expire.
   */
  GRPCErrorCodeDeadlineExceeded = 4,

  /** Some requested entity (e.g., file or directory) was not found. */
  GRPCErrorCodeNotFound = 5,

  /** Some entity that we attempted to create (e.g., file or directory) already exists. */
  GRPCErrorCodeAlreadyExists = 6,

  /**
   * The caller does not have permission to execute the specified operation. PERMISSION_DENIED isn't
   * used for rejections caused by exhausting some resource (RESOURCE_EXHAUSTED is used instead for
   * those errors). PERMISSION_DENIED doesn't indicate a failure to identify the caller
   * (UNAUTHENTICATED is used instead for those errors).
   */
  GRPCErrorCodePermissionDenied = 7,

  /**
   * The request does not have valid authentication credentials for the operation (e.g. the caller's
   * identity can't be verified).
   */
  GRPCErrorCodeUnauthenticated = 16,

  /** Some resource has been exhausted, perhaps a per-user quota. */
  GRPCErrorCodeResourceExhausted = 8,

  /**
   * The RPC was rejected because the server is not in a state required for the procedure's
   * execution. For example, a directory to be deleted may be non-empty, etc.
   * The client should not retry until the server state has been explicitly fixed (e.g. by
   * performing another RPC). The details depend on the service being called, and should be found in
   * the NSError's userInfo.
   */
  GRPCErrorCodeFailedPrecondition = 9,

  /**
   * The RPC was aborted, typically due to a concurrency issue like sequencer check failures,
   * transaction aborts, etc. The client should retry at a higher-level (e.g., restarting a read-
   * modify-write sequence).
   */
  GRPCErrorCodeAborted = 10,

  /**
   * The RPC was attempted past the valid range. E.g., enumerating past the end of a list.
   * Unlike INVALID_ARGUMENT, this error indicates a problem that may be fixed if the system state
   * changes. For example, an RPC to get elements of a list will generate INVALID_ARGUMENT if asked
   * to return the element at a negative index, but it will generate OUT_OF_RANGE if asked to return
   * the element at an index past the current size of the list.
   */
  GRPCErrorCodeOutOfRange = 11,

  /** The procedure is not implemented or not supported/enabled in this server. */
  GRPCErrorCodeUnimplemented = 12,

  /**
   * Internal error. Means some invariant expected by the server application or the gRPC library has
   * been broken.
   */
  GRPCErrorCodeInternal = 13,

  /**
   * The server is currently unavailable. This is most likely a transient condition and may be
   * corrected by retrying with a backoff.
   */
  GRPCErrorCodeUnavailable = 14,

  /** Unrecoverable data loss or corruption. */
  GRPCErrorCodeDataLoss = 15,
};

/**
 * Keys used in |NSError|'s |userInfo| dictionary to store the response headers and trailers sent by
 * the server.
 */
extern id const kGRPCHeadersKey;
extern id const kGRPCTrailersKey;

@interface GRPCError : NSError
/**
 * Returns a NSError whose code is one of |GRPCErrorCode| and whose domain is |kGRPCErrorDomain|.
 */
+ (instancetype)errorWithCode:(GRPCErrorCode)code;

/**
 * Returns nil if the status code is OK. Otherwise, a NSError whose code is one of |GRPCErrorCode|
 * and whose domain is |kGRPCErrorDomain|.
 */
+ (instancetype)errorFromStatusCode:(grpc_status_code)statusCode details:(char *)details;

+ (instancetype)cancelled;
+ (instancetype)unknown;
+ (instancetype)invalidArgument;
+ (instancetype)deadlineExceeded;
+ (instancetype)notFound;
+ (instancetype)alreadyExists;
+ (instancetype)permissionDenied;
+ (instancetype)unauthenticated;
+ (instancetype)resourceExhausted;
+ (instancetype)failedPrecondition;
+ (instancetype)aborted;
+ (instancetype)outOfRange;
+ (instancetype)unimplemented;
+ (instancetype)internal;
+ (instancetype)unavailable;
+ (instancetype)dataLoss;

- (instancetype)errorWithMessage:(NSString *)message;

@end

@interface GRPCMutableError : GRPCError
+ (instancetype)errorWithError:(GRPCError *)error;
- (instancetype)initWithError:(GRPCError *)error;

@property (readwrite) NSInteger code;
@property (readonly, copy) NSMutableDictionary *userInfo;
@property (readwrite, copy) NSString *localizedDescription;
@end