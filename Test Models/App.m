//
//  App.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/11/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "App.h"

@implementation App

@synthesize name;
@synthesize gitCommitHash;
@synthesize versionNumber;
@synthesize files;
@synthesize settings;
@synthesize owner;

-(void)defaultValues{
    [super defaultValues];
    name = @"";
    gitCommitHash = @"";
    versionNumber = @(0);
    files = [[NSArray alloc] init];
    settings = @{};
    owner = [[Person alloc] init];
}

-(void)schema{
    [super schema];
    if (![App hasSchemaDeclared]){
        [App registerColumn:@"name"];
        [App registerColumn:@"gitCommitHash"];
        [App registerColumn:@"versionNumber"];
        [App registerColumn:@"files"];
        [App registerColumn:@"settings"];
        [App registerColumn:@"owner"];
        [App generateSchema:NO]; // If you use "YES" here, it will DROP the table and re-create the table in SQLite.
    }
}

@end
