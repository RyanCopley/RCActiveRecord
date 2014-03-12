//
//  RCActiveRecordResultSet.h
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/10/13.
//  Copyright (c)2013 Ryan Copley. All rights reserved.
//

#import "FMDatabaseQueue.h"
#import "FMResultSet.h"

@interface RCResultSet : NSObject {
	dispatch_queue_t processQueue;
	NSString *internalQuery;
	FMDatabaseQueue *queue;
	Class ARClass;
	FMResultSet *resultSet;
	BOOL error;
}

- (void)execute:(void (^)(id recordResult))recordCallback; //Tested
- (void)execute:(void (^)(id recordResult))recordCallback finished:(void (^)(BOOL error))finishedCallback;  //Tested
- (RCResultSet *)initWithFMDatabaseQueue:(FMDatabaseQueue *)_queue andQuery:(NSString *)query andActiveRecordClass:(Class)_ARClass; //Internal

@end
