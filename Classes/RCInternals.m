//
//  RCInternals.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 2/28/14.
//  Copyright (c) 2014 Ryan Copley. All rights reserved.
//

#import "RCInternals.h"

@implementation RCInternals

@synthesize RCActiveRecordQueue, RCActiveRecordSchemas, pkName, schemaData, foreignKeyData, RCActiveRecordPreload, inTransaction;

static RCInternals *gInstance = NULL;

+ (RCInternals *)instance {
    @synchronized(self) {
        if (gInstance == NULL) {
            gInstance = [[self alloc] init];
            [gInstance instantiate];
        }
    }
    
    return(gInstance);
}

-(void) instantiate {
    if (pkName == nil) {
        pkName = [[NSMutableDictionary alloc] init];
        schemaData = [[NSMutableDictionary alloc] init];
        foreignKeyData = [[NSMutableDictionary alloc] init];
        RCActiveRecordPreload = [[NSMutableDictionary alloc] init];
        inTransaction = NO;
    }
    

    if (!RCActiveRecordQueue) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString* dbPath =  [NSString stringWithFormat:@"%@/db.sqlite",documentsDirectory];
        RCActiveRecordQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        RCActiveRecordSchemas = [[NSMutableDictionary alloc] init];
    }
}
@end
