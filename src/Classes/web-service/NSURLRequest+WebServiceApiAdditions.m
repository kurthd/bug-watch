//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NSURLRequest+WebServiceApiAdditions.h"

@interface NSURLRequest (Private)

+ (NSURL *)urlWithBaseUrlString:(NSString *)baseUrlString
                   getArguments:(NSDictionary *)getArguments;

@end

@implementation NSURLRequest (WebServiceApiAdditions)

+ (id)requestWithBaseUrlString:(NSString *)baseUrlString
                  getArguments:(NSDictionary *)getArguments
{
    return [[[[self class] alloc]
        initWithBaseUrlString:baseUrlString getArguments:getArguments]
        autorelease];
}

+ (id)requestWithBaseUrlString:(NSString *)baseUrlString
                  getArguments:(NSDictionary *)getArguments
                   cachePolicy:(NSURLRequestCachePolicy)cachePolicy
               timeoutInterval:(NSTimeInterval)timeoutInterval
{
    return [[[[self class] alloc]
        initWithBaseUrlString:baseUrlString getArguments:getArguments
        cachePolicy:cachePolicy timeoutInterval:timeoutInterval]
        autorelease];
}

- (id)initWithBaseUrlString:(NSString *)baseUrlString
               getArguments:(NSDictionary *)getArguments
{
    NSURL * url = [[self class] urlWithBaseUrlString:baseUrlString
                                        getArguments:getArguments];

    return self = [self initWithURL:url];
}

- (id)initWithBaseUrlString:(NSString *)baseUrlString
               getArguments:(NSDictionary *)getArguments
                cachePolicy:(NSURLRequestCachePolicy)cachePolicy
            timeoutInterval:(NSTimeInterval)timeoutInterval
{
    NSURL * url = [[self class] urlWithBaseUrlString:baseUrlString
                                        getArguments:getArguments];

    return [self initWithURL:url cachePolicy:cachePolicy
        timeoutInterval:timeoutInterval];
}

#pragma mark Helper methods

+ (NSURL *)urlWithBaseUrlString:(NSString *)baseUrlString
                   getArguments:(NSDictionary *)getArguments
{
    NSMutableString * urlString = [baseUrlString mutableCopy];

    // append arguments to the URL string if there are any
    if (getArguments && getArguments.count > 0) {
        NSArray * keys = getArguments.allKeys;

        id key = [keys objectAtIndex:0];
        id value = [getArguments objectForKey:key];
        [urlString appendFormat:@"?%@=%@", key, value];

        for (NSInteger i = 1, count = keys.count; i < count; ++i) {
            id key = [keys objectAtIndex:i];
            id value = [getArguments objectForKey:key];
            [urlString appendFormat:@"&%@=%@", key, value];
        }
    }

    NSString * encodedUrlString =
        [urlString
        stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL * url = [NSURL URLWithString:encodedUrlString];

    [urlString release];

    return url;
}

@end
