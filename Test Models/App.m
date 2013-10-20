//
//  App.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/11/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "App.h"

@implementation App
@synthesize name2,age2,address2,appPK, array, dict, person;

-(id)initModelValues{
    self = [super init];
    if (self){
        appPK = @(-1);
        name2 = @"";
        address2 = @"";
        age2 = @(0);
        array = @[];
        dict = @{};
        person = [[Person alloc] init]; // Ugh
    }
    return self;
}


-(id)initModel{
    self = [super init];
    if (self){
        if (![App hasSchemaDeclared]){
            NSLog(@"Initialized App schema");
            
            [App registerPrimaryKey:@"appPK"];
            [App registerColumn:@"name2"];
            [App registerColumn:@"address2"];
            [App registerColumn:@"age2"];
            [App registerColumn:@"array"];
            [App registerColumn:@"dict"];
            [App registerColumn:@"person"];
            [App generateSchema:NO]; // If you use "YES" here, it will DROP the table and re-create the table in SQLite.
        }
    }
    return self;
}

@end
