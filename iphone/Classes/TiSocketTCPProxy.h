/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import <Foundation/Foundation.h>
#import "TiProxy.h"
#import "SocketModule.h"
#import "TiBlob.h"

@interface TiSocketTCPProxy : TiProxy {
    CFSocketRef socket;
    NSString* hostName;
    int port;
    
    NSMutableDictionary* remoteSocketDictionary; // remoteSocket->{inputStream, outputStream, writeBuffer, writePos}
    
    NSCondition* configureCondition;
	
	SocketMode mode;
}

-(void)listen:(id)unused;
-(void)connect:(id)unused;
-(void)close:(id)unused;

-(NSNumber*)isValid:(id)unused;
-(void)write:(id)arg;

@property(readonly, nonatomic) NSString* hostName;
@property(readonly, nonatomic) NSNumber* port;
@property(readonly, nonatomic) NSNumber* mode;

@end