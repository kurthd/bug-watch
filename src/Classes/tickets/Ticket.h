//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Ticket : NSObject
{
    NSString * description;
    NSDate * creationDate;
    NSString * link;
}

@property (nonatomic, copy, readonly) NSString * description;
@property (nonatomic, copy, readonly) NSDate * creationDate;
@property (nonatomic, copy, readonly) NSString * link;

- (id)initWithDescription:(NSString *)aDescription
    creationDate:(NSDate *)aCreationDate link:(NSString *)aLink;

- (NSComparisonResult)compare:(Ticket *)anotherTicket;

@end
