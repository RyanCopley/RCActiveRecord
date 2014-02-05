//
//  App.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/11/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "App.h"

@implementation App
@synthesize name, gitCommitHash, versionNumber, files, settings, owner;


-(id)initDefaultValues{
    self = [super init];
    if (self){
        name = @"";
        gitCommitHash = @"";
        versionNumber = @(0);
        files = [[NSArray alloc] init];
        settings = @{};
        owner = [[Person alloc] init];
    }
    return self;
}


-(id)initModel{
    self = [super initModel];
    if (self){
        if (![App hasSchemaDeclared]){
            NSLog(@"Initialized App schema");
            
            [App registerColumn:@"name2"];
            [App registerColumn:@"address2"];
            [App registerColumn:@"age2"];
            [App registerColumn:@"array"];
            [App registerColumn:@"dict"];
            [App generateSchema:NO]; // If you use "YES" here, it will DROP the table and re-create the table in SQLite.
        }
    }
    return self;
}

@end
