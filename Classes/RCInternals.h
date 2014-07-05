//
//  RCInternals.h
//  RCActiveRecord
//
//  Created by Ryan Copley on 2/28/14.
//  Copyright (c) 2014 Ryan Copley. All rights reserved.
//

#import "FMDatabaseQueue.h"

@interface RCInternals : NSObject

@property (nonatomic, strong) FMDatabaseQueue *internalQueue;
@property (nonatomic, strong) NSMutableDictionary *schemaIsDefined;
@property (nonatomic, strong) NSMutableDictionary *schemaData;
@property (nonatomic, assign) BOOL inTransaction;



+ (RCInternals *)instance;

@end
