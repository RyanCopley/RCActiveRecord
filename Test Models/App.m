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
@synthesize version;

-(void)defaultValues{
    [super defaultValues];
    name = @"";
    gitCommitHash = @"";
    versionNumber = @(0);
    files = [[NSArray alloc] init];
    settings = @{};
    owner = [[Person alloc] init];
}

//Defines the "base" schema. Once this is deployed, you should only rely on migrations.
-(void)schema{
    [super schema];
    [App registerColumn:@"name"];
    [App registerColumn:@"gitCommitHash"];
    [App registerColumn:@"versionNumber"];
    [App registerColumn:@"files"];
    [App registerColumn:@"settings"];
    [App registerColumn:@"owner"];
}

@end
