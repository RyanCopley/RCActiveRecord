//
//  RCMigrationAssistant.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 3/4/14.
//  Copyright (c) 2014 Ryan Copley. All rights reserved.
//

#import "RCMigrationAssistant.h"

@implementation RCMigrationAssistant

-(void)defaultValues{
    [super defaultValues];
}

-(void)schema{
    [super schema];
    if (![RCMigrationAssistant hasSchemaDeclared]){
        [RCMigrationAssistant registerColumn:@""];
        
    }
}
@end
