//
//  RCInternals.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 2/28/14.
//  Copyright (c) 2014 Ryan Copley. All rights reserved.
//

#import "RCInternals.h"

@implementation RCInternals

@synthesize internalQueue, schemaIsDefined, schemaData, inTransaction;

static RCInternals *gInstance = NULL;

+ (RCInternals *)instance {
	@synchronized(self)
	{
		if (gInstance == NULL) {
			gInstance = [[self alloc] init];
			[gInstance instantiate];
		}
	}

	return(gInstance);
}

- (void)instantiate {
	if (schemaData == nil) {
		schemaData = [[NSMutableDictionary alloc] init];
		inTransaction = NO;
	}

	if (!internalQueue) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		NSString *dbPath =  [NSString stringWithFormat:@"%@/db.sqlite", documentsDirectory];
		internalQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
		schemaIsDefined = [[NSMutableDictionary alloc] init];
	}
}

@end
