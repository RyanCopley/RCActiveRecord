//
//  RCActiveRecordTests.m
//  RCActiveRecordTests
//
//  Created by Ryan Copley on 8/14/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCActiveRecordTests.h"
#import "Person.h"
#import "App.h"

#define testsize 1000

@implementation RCActiveRecordTests

- (void)setUp
{
    [super setUp];
    [Person model];
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testNewPerson{
    STAssertNotNil([Person model], @"Person Model failed to load");
}

- (void)testSaveRecord{
    [Person trunctuate];
    Person* p = [Person model];
    p.name = @"Test";
    p.address = [@"Address" mutableCopy];
    p.age = @(21);
    p.ip = @"localhost";
    
    [p saveRecord]; // 1
    [p saveRecord]; // 1
    STAssertTrue([[Person model] recordCount] == 1, @"There should be only 1 person in the database.");
    [p insertRecord]; // 2
    [p insertRecord]; // 3
    STAssertTrue([[Person model] recordCount] == 3, @"There should be 3 people in the database.");
}


- (void)testUpdateRecord{
    __block BOOL waitingForBlock = YES;

    //[Person trunctuate];
    Person* p = [Person model];
    p.name = @"Test-update";
    p.address = [@"Address-update" mutableCopy];
    [p saveRecord]; // Create a record to  update
    
    p.name = @"UpdatedName";
    [p updateRecord]; // Update it
    
    __block Person* tmp;
    [[[Person model] recordsByAttribute:@"address" value:@"Address-update"] execute:^(Person* record){
        tmp = record;
    } finished:^(BOOL error){
        waitingForBlock = NO;
    }];
    
    while(waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    if (tmp == nil){
        STAssertTrue(false, @"Did not find any records");
    }else{
        STAssertTrue([tmp.name isEqualToString:@"UpdatedName"], @"Update did not update the database");
    }
    
}


- (void)testDeleteRecord{
    [Person trunctuate];
    Person* p = [Person model];
    p.name = @"Test";
    p.address = [@"Address" mutableCopy];
    p.age = @(21);
    p.ip = @"localhost";
    
    STAssertEquals([p recordCount], 0, @"Truncate did not empty table");
    [p saveRecord]; // 1
    STAssertEquals([p recordCount], 1, @"Save did not work");
    [p deleteRecord]; // 0
    STAssertEquals([p recordCount], 0, @"Delete did not remove the record");
}


- (void)testAllRecords {
    __block BOOL waitingForBlock = YES;
    [Person trunctuate];
    Person* p = [Person model];
    p.name = @"Test";
    p.address = [@"Address" mutableCopy];
    p.age = @(21);
    p.ip = @"localhost";
    [p saveRecord];
    
    Person* p2 = [Person model];
    p2.name = @"Test2";
    p2.address = [@"Address2" mutableCopy];
    p2.age = @(22);
    p2.ip = @"192.253.23.15";
    [p2 saveRecord];
    
    __block int foundRecords = 0;
    [[Person allRecords] execute: ^(Person* record){
        foundRecords++;
    } finished: ^(BOOL error){
        waitingForBlock = NO;
    }];
    
    while(waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    STAssertTrue(foundRecords==2, @"All records did not return a valid amount of objects");
}

- (void)testAllRecordsWithCriteria {
    __block BOOL waitingForBlock = YES;
    [Person trunctuate];
    Person* p = [Person model];
    p.name = @"Test";
    p.address = [@"Address" mutableCopy];
    p.age = @(21);
    p.ip = @"localhost";
    [p saveRecord];
    
    Person* p2 = [Person model];
    p2.name = @"Test2";
    p2.address = [@"Address2" mutableCopy];
    p2.age = @(22);
    p2.ip = @"192.253.23.15";
    [p2 saveRecord];
    
    __block int foundRecords = 0;
    RCCriteria* criteria = [[RCCriteria alloc] init];
    [criteria addCondition:@"name" is:RCEqualTo to:@"Test"];
    [[Person allRecordsWithCriteria:criteria] execute: ^(Person* record){
        foundRecords++;
    } finished: ^(BOOL error){
        waitingForBlock = NO;
    }];
    
    while(waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    STAssertTrue(foundRecords==1, @"All records w/ criteria did not return a valid amount of objects");
}


- (void)testSettingPrimaryKey{
    Person* p = [Person model];
    p.name = @"Test";
    p.address = [@"Address" mutableCopy];
    p.age = @(21);
    p.ip = @"localhost";
    STAssertTrue([[p primaryKeyValue] isEqualToNumber:@(-1)], @"Primary key should be -1 before being saved.");
    [p saveRecord];
    STAssertFalse([[p primaryKeyValue] isEqualToNumber:@(-1)], @"Primary key should not be -1 after being saved.");
}

- (void)testTruncate {
    int i = testsize;
    do {
        Person* p = [Person model];
        p.name = @"Test";
        [p saveRecord];
    } while (i-->1);
    STAssertTrue([[Person model] recordCount] >= testsize, @"There should be `testsize` people in the database.");
    
    [Person trunctuate];
    STAssertEquals([[Person model] recordCount], 0, @"There should not be any people in the database.");
}

- (void)testTransactioning {
    [Person trunctuate];
    [Person beginTransaction];
    int i = testsize;
    do {
        Person* p = [Person model];
        p.name = @"Test";
        [p saveRecord];
        if (i == floor(testsize/2)){
            [Person rollback];
            [Person beginTransaction];
        }
    } while (i-->1);
    [Person commit];
    int endCount = [[Person model] recordCount];
    
    STAssertTrue( (endCount==testsize/2-1), @"Rollback did not remove first half of testsize.");
}

- (void)testJSONEncoding {
    Person* p = [Person model];
    p.name = @"Json Test";
    p.address = [@"Json Test Address" mutableCopy];
    p.ip = @"localhost";
    p.age = @(100);
    NSDictionary* obj = [p toJSON];
    
    STAssertTrue([[obj objectForKey:@"_id"] isEqual: @(-1)], @"_id should be -1 from JSON");
    STAssertTrue([[obj objectForKey:@"address"] isEqualToString: p.address], @"address should be supplied from JSON");
    STAssertTrue([[obj objectForKey:@"ip"] isEqualToString: @"localhost"], @"ip should be supplied from JSON");
    STAssertTrue([[obj objectForKey:@"age"] isEqual: @(100)], @"age should be 0 from JSON");
}


- (void)testJSONDecoding {
    Person* p = [Person fromJSON:
         @{
           @"name" : @"test",
           @"address" : @"json",
           @"age" : @(22)
           }
         ];
    
    STAssertNil(p._id, @"_id should be -1 from JSON");
    STAssertTrue([p.address isEqualToString:@"json"], @"address should be supplied from JSON");
    STAssertTrue([p.age isEqual: @(22)], @"age should be 100 from JSON");
}




////Empty the table `App`
//
//int writtenCount = 0;
//int i;
//
//[App trunctuate];
//App* a = [App model];
//
//
//int testSize = 14000;
//i = testSize;
//a.address2 = @"Test St";
//
//a.person = p;
//[a beginTransaction];
//[a beginTransaction];//Whoops! Started a transaction twice! No worries, we safe guard against this.
//__block NSTimeInterval writeStart = [NSDate timeIntervalSinceReferenceDate];
//do {
//    a.name2 = [NSString stringWithFormat:@"Ryan-%i",arc4random()%10000];
//    a.age2 = @(arc4random()%50 + 18);
//    a.array = @[@(arc4random()%50),@(arc4random()%50),@(arc4random()%50),@(arc4random()%50),@(arc4random()%50)];
//    a.dict = @{@"Key":@(arc4random()%10000)};
//    [a insertRecord];
//    writtenCount++;
//} while (i-->0);
//[a commit]; //Commit (write) all changes to the database. This is the key to having exceptionally fast SQLite performance!
//
////Delete the latest entry (Since we INSERTED `testSize` times, `a` links to the MOST RECENT insertion.
//[a deleteRecord]; //Since we are outside of a transaction, this will happen immediately!!
//NSLog(@"Deleted 1 record");
//
//
//
//NSLog(@"JSON'd: %@", [a toJSON]);
//
//

//NSLog(@"From JSON Dictionary Name: %@ == test",a.name2);
//
//
//NSArray* objs = [App fromJSON:
//                 @[
//                   @{
//                       @"name2" : @"Array index 0 name",
//                       @"address2" : @"json",
//                       @"age2" : @(22),
//                       @"array" : @[@"1",@"2"],
//                       @"dict" : @{@"a":@"s"}
//                       },
//                   @{
//                       @"name2" : @"Array index 1 name",
//                       @"address2" : @"json",
//                       @"age2" : @(22),
//                       @"array" : @[@"1",@"2"],
//                       @"dict" : @{@"a":@"s"}
//                       }]
//                 ];
//
//App* tmp = [objs objectAtIndex:0];
//NSLog(@"From JSON array: %@ == Array index 0 name", tmp.name2);
//App* tmp2 = [objs objectAtIndex:1];
//NSLog(@"From JSON array: %@ == Array index 1 name", tmp2.name2);
//
//NSLog(@"Wrote %i models",writtenCount);
//
//
////Benchmark how long it took us to write `testSize` entries
//NSTimeInterval writeDuration = [NSDate timeIntervalSinceReferenceDate] - writeStart;
//NSLog(@"(WRITE) Duration: %f, count: %i, ms per record: %f", writeDuration, testSize, (writeDuration/testSize)*1000);
//
//
////Now lets benchmark reading. As you see, this is a fully asyncronous read! Yay!
//__block int recordCount = 0;
//__block NSTimeInterval readStart = [NSDate timeIntervalSinceReferenceDate];
//
//
//
//[[[[App model] allRecords] setProcessQueueCount:32] execute: ^(App* record){
//    NSLog(@"Age: %@ is %@ years old with objs: %@, dict: %@ insertedDate: %@, person id: %@", record.name2,record.age2, record.array, record.dict, record.creationDate, record.person.name);
//    recordCount++;
//    
//} finished: ^(BOOL error){
//    
//    //Once we run out of models from SQLite, this block is called. It is optional, so you don't have to have it.
//    NSTimeInterval readDuration = [NSDate timeIntervalSinceReferenceDate] - readStart;
//    NSLog(@"(READ+Preloading) Duration: %f, count: %i, ms per record: %f", readDuration, recordCount, (readDuration/recordCount)*1000);
//    
//    recordCount = 0;
//    readStart = [NSDate timeIntervalSinceReferenceDate];
//    [App preloadModels:NO];
//    
//    [[[App model] allRecords] execute: ^(App* record){
//        //NSLog(@"Age: %@ is %@ years old with objs: %@, dict: %@ insertedDate: %@, person id: %@", record.name2,record.age2, record.array, record.dict, record.creationDate, record.person.name);
//        recordCount++;
//    } finished: ^(BOOL error){
//        //Once we run out of models from SQLite, this block is called. It is optional, so you don't have to have it.
//        NSTimeInterval readDuration = [NSDate timeIntervalSinceReferenceDate] - readStart;
//        NSLog(@"(READ-Preloading) Duration: %f, count: %i, ms per record: %f", readDuration, recordCount, (readDuration/recordCount)*1000);
//    }];
//
//}];

@end
