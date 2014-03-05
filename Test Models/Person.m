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

-(void)defaultValues{
    [super defaultValues];
    name = @"";
    address = [@"" mutableCopy];
    age = @(0);
    ip = @"";
}


-(void)schema{
    [super schema];
    if (![Person hasSchemaDeclared]){
        NSLog(@"Initialized person schema");
        [Person registerColumn:@"name"];
        [Person registerColumn:@"address"];
        [Person registerColumn:@"age"];
        [Person registerColumn:@"ip"];
    }
}

@end
