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
@synthesize md5,version;

-(void)defaultValues{
    [super defaultValues];
    name = @"";
    address = [@"" mutableCopy];
    age = @(0);
    ip = @"";
    version = @(1.0f);
    md5 = @"e21b0ff3877dca5c2b3c5a37f3fa3ee4"; // Bonus points to whoever cracks this hash.
}

-(void)schema{
    [super schema];
    [Person registerColumn:@"name"];
    [Person registerColumn:@"address"];
    [Person registerColumn:@"age"];
    [Person registerColumn:@"ip"];
}
-(BOOL) migrateToVersion_1{
    [Person registerColumn:@"version"];
    [Person deleteColumn:@"ip"];
    return YES;
}

-(BOOL) migrateToVersion_2{
    [Person registerColumn:@"md5"];
    return YES;
}

@end
