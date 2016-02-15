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

/**
 * "X-macro" file that lists the flags names of Apple's Network Reachability API, along with a nice
 * Objective-C method name used to query each of them.
 *
 * Example usage: To generate a dictionary from flag value to name, one can do:

  NSDictionary *flagNames = @{
#define GRX_ITEM(methodName, FlagName) \
    @(kSCNetworkReachabilityFlags ## FlagName): @#methodName,
#include "GRXReachabilityFlagNames.xmacro.h"
#undef GRX_ITEM
  };

  XCTAssertEqualObjects(flagNames[@(kSCNetworkReachabilityFlagsIsWWAN)], @"isCell");

 */

#ifndef GRX_ITEM
#error This file is to be used with the "X-macro" pattern: Please #define \
       GRX_ITEM(methodName, FlagName), then #include this file, and then #undef GRX_ITEM.
#endif

GRX_ITEM(isCell, IsWWAN)
GRX_ITEM(reachable, Reachable)
GRX_ITEM(transientConnection, TransientConnection)
GRX_ITEM(connectionRequired, ConnectionRequired)
GRX_ITEM(connectionOnTraffic, ConnectionOnTraffic)
GRX_ITEM(interventionRequired, InterventionRequired)
GRX_ITEM(connectionOnDemand, ConnectionOnDemand)
GRX_ITEM(isLocalAddress, IsLocalAddress)
GRX_ITEM(isDirect, IsDirect)
