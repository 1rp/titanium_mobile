//
//  TiBonjourBrowserProxy.m
//  Titanium
//
//  Created by Stiv on 2/20/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "TiBonjourBrowserProxy.h"
#import "TiBonjourServiceProxy.h"
#import "BonjourModule.h"

@implementation TiBonjourBrowserProxy

@synthesize serviceType, domain;

#pragma mark Public

-(id)init
{
    if (self = [super init]) {
        browser = [[NSNetServiceBrowser alloc] init];
        services = [[NSMutableArray alloc] init];
        
        [browser removeFromRunLoop:[NSRunLoop currentRunLoop] 
                           forMode:NSDefaultRunLoopMode];
        [browser scheduleInRunLoop:[NSRunLoop mainRunLoop] 
                           forMode:NSDefaultRunLoopMode];
        
        [browser setDelegate:self];
        searching = NO;
        error = nil;
    }
    
    return self;
}

-(void)dealloc
{
    [browser release];
    [serviceType release];
    [domain release];
    [services release];
    
    [super dealloc];
}

-(NSArray*)services
{
    [services retain];
    [services autorelease];
    return services;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"BonjourServiceBrowser: %@ (%d)", [services description], [services retainCount]];
}

-(void)setServiceType:(NSString*)type_
{
    if (serviceType == type_) {
        return;
    }
    
    [serviceType release];
    serviceType = [type_ retain];
}

-(void)setDomain:(NSString*)domain_
{
    if (domain == domain_) {
        return;
    }
    
    [domain release];
    domain = [domain_ retain];
}

-(void)search:(id)unused
{
    RELEASE_TO_NIL(error);
    [browser searchForServicesOfType:serviceType 
                            inDomain:domain];
    
    if (!searching && !error) {
        [searchCondition lock];
        [searchCondition wait];
        [searchCondition unlock];
    }
    
    if (error) {
        [self throwException:[@"Failed to search: " stringByAppendingString:error]
                   subreason:nil
                    location:CODELOCATION];
    }
}

-(void)stopSearch:(id)unused
{
    [browser stop];
    
    if (searching) {
        [searchCondition lock];
        [searchCondition wait];
        [searchCondition unlock];
    }
}

-(void)purgeServices:(id)unused
{
    [services removeAllObjects];
    
    [self fireEvent:@"updatedServices"
         withObject:nil];
}

-(NSNumber*)isSearching:(id)unused
{
    return [NSNumber numberWithBool:searching];
}

#pragma mark Private

-(void)setError:(NSString*)error_
{
    if (error != error_) {
        [error release];
        error = [error_ retain];
    }
}

#pragma mark Delegate methods

#pragma mark Service management

-(void)netServiceBrowser:(NSNetServiceBrowser*)browser_ didFindService:(NSNetService*)service moreComing:(BOOL)more
{
    [services addObject:[[[TiBonjourServiceProxy alloc] initWithContext:[self pageContext]
                                                                service:service
                                                                  local:NO] autorelease]];
    
    if (!more) {
        [self fireEvent:@"updatedServices"
             withObject:nil];
    }
}

-(void)netServiceBrowser:(NSNetServiceBrowser*)browser_ didRemoveService:(NSNetService*)service moreComing:(BOOL)more
{
    // Create a temp object to release; this is what -[TiBonjourServiceProxy isEqual:] is for
    [services removeObject:[[[TiBonjourServiceProxy alloc] initWithContext:[self pageContext]
                                                                   service:service
                                                                     local:NO] autorelease]];
    
    if (!more) {
        [self fireEvent:@"updatedServices"
             withObject:nil];
    }
}

#pragma mark Search management

-(void)netServiceBrowserWillSearch:(NSNetServiceBrowser*)browser_
{
    searching = YES;
    [searchCondition lock];
    [searchCondition signal];
    [searchCondition unlock];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)browser_ didNotSearch:(NSDictionary *)errorDict
{
    [self setError:[BonjourModule stringForErrorCode:[[errorDict objectForKey:NSNetServicesErrorCode] intValue]]];
    
    [searchCondition lock];
    [searchCondition signal];
    [searchCondition unlock];
}

-(void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser*)browser_
{
    searching = NO;
    
    [searchCondition lock];
    [searchCondition signal];
    [searchCondition unlock];
}

@end
