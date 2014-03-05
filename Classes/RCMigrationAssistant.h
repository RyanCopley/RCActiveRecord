//
//  RCMigrationAssistant.h
//  RCActiveRecord
//
//  Created by Ryan Copley on 3/4/14.
//  Copyright (c) 2014 Ryan Copley. All rights reserved.
//

#import "RCActiveRecord.h"

@interface RCMigrationAssistant : RCActiveRecord

@property (nonatomic, strong) NSString* table;
@property (nonatomic, strong) NSNumber* version;

@end
