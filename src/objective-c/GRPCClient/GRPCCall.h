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
#import <RxLibrary/GRXWriter.h>

#include <AvailabilityMacros.h>

#import "GRPCError.h"

/**
 * Represents a single gRPC remote call.
 *
 * The gRPC protocol is an RPC protocol on top of HTTP2.
 *
 * While the most common type of RPC receives only one request message and returns only one response
 * message, the protocol also supports RPCs that return multiple individual messages in a streaming
 * fashion, RPCs that accept a stream of request messages, or RPCs with both streaming requests and
 * responses.
 *
 * Conceptually, each gRPC call consists of a bidirectional stream of binary messages, with RPCs of
 * the "non-streaming type" sending only one message in the corresponding direction (the protocol
 * doesn't make any distinction).
 *
 * Each RPC uses a different HTTP2 stream, and thus multiple simultaneous RPCs can be multiplexed
 * transparently on the same TCP connection.
 */
@interface GRPCCall : GRXWriter

/**
 * These HTTP headers will be passed to the server as part of this call. Each HTTP header is a
 * name-value pair with string names and either string or binary values.
 *
 * The keys of this container are the header names, which per the HTTP standard are case-
 * insensitive. They are stored in lowercase (which is how HTTP/2 mandates them on the wire), and
 * can only consist of ASCII characters.
 * A header value is a NSString object (with only ASCII characters), unless the header name has the
 * suffix "-bin", in which case the value has to be a NSData object.
 *
 * Examples:
 *
 * call.requestHeaders[@"authorization"] = @"Bearer ...";
 *
 * call.requestHeaders[@"my-header-bin"] = someData;
 *
 * After the call is started, trying to modify this property is an error.
 *
 * The property is initialized to an empty NSMutableDictionary.
 */
@property(atomic, readonly) NSMutableDictionary *requestHeaders;

/**
 * This dictionary is populated with the HTTP headers received from the server. This happens before
 * any response message is received from the server. It has the same structure as the request
 * headers dictionary: Keys are NSString header names; names ending with the suffix "-bin" have a
 * NSData value; the others have a NSString value.
 *
 * The value of this property is nil until all response headers are received, and will change before
 * any of -writeValue: or -writesFinishedWithError: are sent to the writeable.
 */
@property(atomic, readonly) NSDictionary *responseHeaders;

/**
 * Same as responseHeaders, but populated with the HTTP trailers received from the server before the
 * call finishes.
 *
 * The value of this property is nil until all response trailers are received, and will change
 * before -writesFinishedWithError: is sent to the writeable.
 */
@property(atomic, readonly) NSDictionary *responseTrailers;

/**
 * The request writer has to write NSData objects into the provided Writeable. The server will
 * receive each of those separately and in order as distinct messages.
 * A gRPC call might not complete until the request writer finishes. On the other hand, the request
 * finishing doesn't necessarily make the call to finish, as the server might continue sending
 * messages to the response side of the call indefinitely (depending on the semantics of the
 * specific remote method called).
 * To finish a call right away, invoke cancel.
 * host parameter should not contain the scheme (http:// or https://), only the name or IP addr
 * and the port number, for example @"localhost:5050".
 */
- (instancetype)initWithHost:(NSString *)host
                        path:(NSString *)path
              requestsWriter:(GRXWriter *)requestsWriter NS_DESIGNATED_INITIALIZER;

/**
 * Finishes the request side of this call, notifies the server that the RPC should be cancelled, and
 * finishes the response side of the call with an error of code CANCELED.
 */
- (void)cancel;

// TODO(jcanizales): Let specify a deadline. As a category of GRXWriter?
@end

#pragma mark Backwards compatibiity

/** This protocol is kept for backwards compatibility with existing code. */
DEPRECATED_MSG_ATTRIBUTE("Use NSDictionary or NSMutableDictionary instead.")
@protocol GRPCRequestHeaders <NSObject>
@property(nonatomic, readonly) NSUInteger count;

- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)obj forKeyedSubscript:(id)key;

- (void)removeAllObjects;
- (void)removeObjectForKey:(id)key;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
/** This is only needed for backwards-compatibility. */
@interface NSMutableDictionary (GRPCRequestHeaders) <GRPCRequestHeaders>
@end
#pragma clang diagnostic pop
