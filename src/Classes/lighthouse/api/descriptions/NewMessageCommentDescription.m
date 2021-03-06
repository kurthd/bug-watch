//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NewMessageCommentDescription.h"

@implementation NewMessageCommentDescription

@synthesize title, body;

+ (id)description
{
    return [[[[self class] alloc] init] autorelease];
}

- (void)dealloc
{
    self.title = nil;
    self.body = nil;
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        self.title = @"";
        self.body = @"";
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    NewMessageCommentDescription * desc =
        [[[self class] allocWithZone:zone] init];
    desc.title = self.title;
    desc.body = self.body;

    return desc;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"title: '%@', body: '%@'", title, body];
}

- (NSString *)xmlDescription
{
    return
        [NSString stringWithFormat:
        @"<message>\n"
        "    <title>%@</title>\n"
        "    <body>%@</body>\n"
        "</message>",
        self.title,
        self.body];
}

@end
