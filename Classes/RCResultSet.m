//
//  RCActiveRecordResultSet.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/10/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCActiveRecord.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "RCResultSet.h"
#import "RCDataCoder.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@implementation RCResultSet

- (void)execute:(void (^) (id recordResult))recordCallback {
	[self execute:recordCallback finished: ^(BOOL error) {}];
}

- (void)execute:(void (^) (id recordResult))recordCallback finished:(void (^) (BOOL error))finishedCallback {
	dispatch_async(processQueue, ^{
	    error = NO;
	    [queue inDatabase: ^(FMDatabase *db) {
	        RCDataCoder *coder = [RCDataCoder sharedSingleton];
	        FMResultSet *s = [db executeQuery:internalQuery];
	        while ([s next]) {
	            id AR = [[ARClass alloc] init];
	            [AR defaultValues];
	            [(RCActiveRecord *)AR setIsNewRecord: NO];
	            [(RCActiveRecord *)AR setIsSavedRecord: YES];
	            @autoreleasepool {
	                for (int i = 0; i < [s columnCount]; i++) {
	                    NSString *varName = [s columnNameForIndex:i];
	                    NSString *setConversion = [NSString stringWithFormat:@"set%@%@:", [[varName substringToIndex:1] uppercaseString], [varName substringFromIndex:1]];
	                    NSString *value = [NSString stringWithFormat:@"%s", [s UTF8StringForColumnIndex:i]];
	                    id convertedValue = [coder decode:value toType:[[AR performSelector:NSSelectorFromString(varName)] class]];
	                    @try {
	                        [AR performSelector:NSSelectorFromString(setConversion) withObject:convertedValue];
						}
	                    @catch (NSException *e)
	                    {
	                        error = YES;
	                        NSLog(@"RCActiveRecord: (%@) is not properly synthesized (Invalid setter). Unable to set: %@", NSStringFromClass([AR class]), varName);
						}
					}
				}
	            recordCallback(AR);
			}
	        dispatch_async(dispatch_queue_create("", NULL), ^{
	            finishedCallback(error);
			});
		}];
	});
}

//Internal
- (RCResultSet *)initWithFMDatabaseQueue:(FMDatabaseQueue *)_queue andQuery:(NSString *)query andActiveRecordClass:(Class)_ARClass {
	self = [super init];
	if (self) {
		processQueue = dispatch_queue_create("", NULL);
		internalQuery = query;
		queue = _queue;
		ARClass = _ARClass;
	}
	return self;
}

@end

#pragma clang diagnostic pop
