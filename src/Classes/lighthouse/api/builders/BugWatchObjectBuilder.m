//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "BugWatchObjectBuilder.h"
#import "LighthouseApiParser.h"

@interface BugWatchObjectBuilder ()

@property (nonatomic, retain) LighthouseApiParser * parser;

@end

@implementation BugWatchObjectBuilder

@synthesize parser;

#pragma mark Instantiation and initialization

+ (id)builderWithParser:(LighthouseApiParser *)aParser
{
    return [[[[self class] alloc] initWithParser:aParser] autorelease];
}

- (id)initWithParser:(LighthouseApiParser *)aParser
{
    if (self = [super init])
        self.parser = aParser;

    return self;
}

#pragma mark Building objects

- (NSArray *)parseErrors:(NSData *)xml
{
    parser.className = @"NSString";
    parser.classElementType = @"error";
    parser.classElementCollection = @"errors";
    parser.attributeMappings = nil;

    return [parser parse:xml];
}

- (NSArray *)parseTicketUrls:(NSData *)xml
{
    parser.className = @"NSString";
    parser.classElementType = @"ticket";
    parser.classElementCollection = @"tickets";
    parser.attributeMappings =
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"string", @"url", nil];

    return [parser parse:xml];
}

@end
