//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TicketBinDataSourceDelegate

- (void)receivedTicketBinsFromDataSource:(NSArray *)someTicketBins;
- (void)failedToFetchTicketBins:(NSArray *)errors;

@end
