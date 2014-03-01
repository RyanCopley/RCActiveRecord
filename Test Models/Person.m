//
//  Person.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/11/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "Person.h"

@implementation Person

@synthesize name;
@synthesize address;
@synthesize age;
@synthesize ip;

-(id)defaultValues{
    [super defaultValues];
    name = @"";
    address = [@"" mutableCopy];
    age = @(0);
    ip = @"";
    return self;
}


-(id)schema{
    [super schema];
    if (![Person hasSchemaDeclared]){
        NSLog(@"Initialized person schema");
        [Person registerColumn:@"name"];
        [Person registerColumn:@"address"];
        [Person registerColumn:@"age"];
        [Person registerColumn:@"ip"];
        [Person generateSchema:NO]; // If you use "YES" here, it will DROP the table and re-create the table in SQLite.
    }
    return self;
}

@end
