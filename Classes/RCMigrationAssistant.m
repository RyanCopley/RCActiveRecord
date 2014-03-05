//
//  RCMigrationAssistant.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 3/4/14.
//  Copyright (c) 2014 Ryan Copley. All rights reserved.
//

#import "RCMigrationAssistant.h"

@implementation RCMigrationAssistant

@synthesize table,version;

-(void)defaultValues{
    [super defaultValues];
    table = @"";
    version = @(0);
}

-(void)schema{
    [super schema];
    [RCMigrationAssistant registerColumn:@"table"];
    [RCMigrationAssistant registerColumn:@"version"];
}
@end
