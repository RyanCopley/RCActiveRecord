//
//  Person.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/11/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "Person.h"

@implementation Person
@synthesize name,address,age;

-(id)init{
    self = [super init];
    if (self){
        NSLog(@"Initialized person");
        if (![Person hasSchemaDeclared]){
            NSLog(@"Initialized person schema");
            [Person registerPrimaryKey:@"personPK"];
            [Person registerColumn:@"name"];
            [Person registerColumn:@"address"];
            [Person registerColumn:@"age"];
            [Person generateSchema:NO]; // If you use "YES" here, it will DROP the table and re-create the table in SQLite.
        }
    }
    return self;
}

@end
