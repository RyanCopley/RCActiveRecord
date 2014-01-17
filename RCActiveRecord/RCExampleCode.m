//
//  RCExampleCode.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 10/12/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCExampleCode.h"
#import "Person.h"
#import "App.h"

@implementation RCExampleCode

-(void) runExample{
    
    Person* p = [Person model]; //Initialize a model
    
    
    //Set some attributes
    p.name = @"Ryan C.";
    p.address = [@"Fisher Street" mutableCopy];
    p.age = @(21);
    p.ip = @"127.0.0.1";
    
    //Lets save it a few times.
    //If the model is NEW (You instantiated it and it was never written to the DB), it will INSERT it.
    //If the model is OLD, and is already in the DB, it will UPDATE it.
    //You can FORCE a model to INSERT by using [p insertRecord], but [p saveRecord] is a umbrella method to do whatever neccessary.
    //If you update a record that has never been written, you may have odd results.
    
    NSLog(@"ID (Before save) [Should be -1, since it is not set]: %@",[p primaryKeyValue]);
    [p saveRecord]; // <-- Inserts since it is a NEW model
    NSLog(@"ID (After save) [Should be NOT -1]: %@",[p primaryKeyValue]);
    [p saveRecord]; // <-- Updates since it has previously been saved
    p.address = [@"Price Street" mutableCopy];
    [p updateRecord]; // <-- Updates since it has previously been saved
    p.address = [@"Rice Street" mutableCopy];
    [p saveRecord]; // <-- Updates since it has previously been saved
    NSLog(@"ID (Shouldn't change): %@",[p primaryKeyValue]);
    
    
    //Empty the table `App`
    
    int writtenCount = 0;
    int i;
    
    [App trunctuate];
    App* a = [App model];
    
    
    int testSize = 14000;
    i = testSize;
    a.address2 = @"Test St";
    
    a.person = p;
    [a beginTransaction];
    [a beginTransaction];//Whoops! Started a transaction twice! No worries, we safe guard against this.
    __block NSTimeInterval writeStart = [NSDate timeIntervalSinceReferenceDate];
    do {
        a.name2 = [NSString stringWithFormat:@"Ryan-%i",arc4random()%10000];
        a.age2 = @(arc4random()%50 + 18);
        a.array = @[@(arc4random()%50),@(arc4random()%50),@(arc4random()%50),@(arc4random()%50),@(arc4random()%50)];
        a.dict = @{@"Key":@(arc4random()%10000)};
        [a insertRecord];
        writtenCount++;
    } while (i-->0);
    [a commit]; //Commit (write) all changes to the database. This is the key to having exceptionally fast SQLite performance!
    
    //Delete the latest entry (Since we INSERTED `testSize` times, `a` links to the MOST RECENT insertion.
    [a deleteRecord]; //Since we are outside of a transaction, this will happen immediately!!
    NSLog(@"Deleted 1 record");
    
    
    
    NSLog(@"JSON'd: %@", [a toJSON]);
    
    
    a = [App fromJSON:
         @{
           @"name2" : @"test",
           @"address2" : @"json",
           @"age2" : @(22),
           @"array" : @[@"1",@"2"],
           @"dict" : @{@"a":@"s"}
           }
         ];
    NSLog(@"From JSON Dictionary Name: %@ == test",a.name2);
    
    
    NSArray* objs = [App fromJSON:
                     @[
                       @{
                           @"name2" : @"Array index 0 name",
                           @"address2" : @"json",
                           @"age2" : @(22),
                           @"array" : @[@"1",@"2"],
                           @"dict" : @{@"a":@"s"}
                           },
                       @{
                           @"name2" : @"Array index 1 name",
                           @"address2" : @"json",
                           @"age2" : @(22),
                           @"array" : @[@"1",@"2"],
                           @"dict" : @{@"a":@"s"}
                           }]
                     ];
    
    App* tmp = [objs objectAtIndex:0];
    NSLog(@"From JSON array: %@ == Array index 0 name", tmp.name2);
    App* tmp2 = [objs objectAtIndex:1];
    NSLog(@"From JSON array: %@ == Array index 1 name", tmp2.name2);
    
    NSLog(@"Wrote %i models",writtenCount);
    
    
    //Benchmark how long it took us to write `testSize` entries
    NSTimeInterval writeDuration = [NSDate timeIntervalSinceReferenceDate] - writeStart;
    NSLog(@"(WRITE) Duration: %f, count: %i, ms per record: %f", writeDuration, testSize, (writeDuration/testSize)*1000);
    
    
    //Now lets benchmark reading. As you see, this is a fully asyncronous read! Yay!
    __block int recordCount = 0;
    __block NSTimeInterval readStart = [NSDate timeIntervalSinceReferenceDate];
    
    
    
    [[[[App model] allRecords] setProcessQueueCount:32] execute: ^(App* record){
        NSLog(@"Age: %@ is %@ years old with objs: %@, dict: %@ insertedDate: %@, person id: %@", record.name2,record.age2, record.array, record.dict, record.creationDate, record.person.name);
        recordCount++;
        
    } finished: ^(BOOL error){
        
        //Once we run out of models from SQLite, this block is called. It is optional, so you don't have to have it.
        NSTimeInterval readDuration = [NSDate timeIntervalSinceReferenceDate] - readStart;
        NSLog(@"(READ+Preloading) Duration: %f, count: %i, ms per record: %f", readDuration, recordCount, (readDuration/recordCount)*1000);
        
        recordCount = 0;
        readStart = [NSDate timeIntervalSinceReferenceDate];
        [App preloadModels:NO];
        
        [[[App model] allRecords] execute: ^(App* record){
            //NSLog(@"Age: %@ is %@ years old with objs: %@, dict: %@ insertedDate: %@, person id: %@", record.name2,record.age2, record.array, record.dict, record.creationDate, record.person.name);
            recordCount++;
        } finished: ^(BOOL error){
            //Once we run out of models from SQLite, this block is called. It is optional, so you don't have to have it.
            NSTimeInterval readDuration = [NSDate timeIntervalSinceReferenceDate] - readStart;
            NSLog(@"(READ-Preloading) Duration: %f, count: %i, ms per record: %f", readDuration, recordCount, (readDuration/recordCount)*1000);
        }];
        
    }];
    
    
}
@end
