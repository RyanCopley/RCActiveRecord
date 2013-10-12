//
//  App.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/11/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "App.h"

@implementation App
@synthesize name2,age2,address2,appPK;

-(id)initModelValues{
    self = [super init];
    
    name2 = @"";
    address2 = @"";
    age2 = @(0);
    return self;
}


-(id)initModel{
    self = [super init];
    if (self){
        NSLog(@"Initialized App");
        if (![App hasSchemaDeclared]){
            NSLog(@"Initialized App schema");
            
            [App registerPrimaryKey:@"appPK"];
            [App registerColumn:@"name2"];
            [App registerColumn:@"address2"];
            [App registerColumn:@"age2"];
            [App generateSchema:NO]; // If you use "YES" here, it will DROP the table and re-create the table in SQLite.
        }
    }
    return self;
}

@end
