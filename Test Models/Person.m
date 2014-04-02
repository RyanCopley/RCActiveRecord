//
//  Person.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/11/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "Person.h"

@implementation Person

@synthesize name, address, age, ip, md5, version, sha1;

-(void)defaultValues{
    [super defaultValues];
    name = @"";
    address = @"";
    age = @(0);
    ip = @"";
    md5 = @"e21b0ff3877dca5c2b3c5a37f3fa3ee4"; // Bonus points to whoever cracks this hash.
    sha1 = @"";
}

-(void)schema{
    [super schema];
    
    //Since we have default values associated above, we do not need to assign the type. 
    [Person registerColumn:@"name"];
    [Person registerColumn:@"address"];
    [Person registerColumn:@"age"];
    [Person registerColumn:@"ip"];
    
    //If you don't want to set a default value above, you must specify the class type.
    [Person registerColumn:@"version" ofType: [NSNumber class]];
}
-(BOOL) migrateToVersion_1{
    
    
    [Person deleteColumn:@"ip"];
    return YES;
}

-(BOOL) migrateToVersion_2{
    [Person registerColumn:@"md5"];
    return YES;
}
-(BOOL) migrateToVersion_3{
    [Person registerColumn:@"sha1"];
    return YES;
}

@end
