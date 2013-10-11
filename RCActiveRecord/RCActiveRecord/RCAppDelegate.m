//
//  RCAppDelegate.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 8/14/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "RCAppDelegate.h"
#import "Person.h"
#import "App.h"

@implementation RCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    Person* p = [Person model];
    p.name = @"Ryana";
    p.address = [@"Elm St" mutableCopy];
    p.age = @(21);
    p.ip = @"DAWEF";
    NSLog(@"ID (Before insert): %@",p._id);
    [p saveRecord];
    NSLog(@"ID (After insert): %@",p._id);
    [p saveRecord];
    p.address = [@"Elm2222 St" mutableCopy];
    [p saveRecord];
    p.address = [@"Elm4444 St" mutableCopy];
    [p saveRecord];
    NSLog(@"ID (After 4 inserts): %@",p._id);
    
    App* a = [App model];
    
    int testSize = 1000;
    int i = testSize;
    a.name2 = [NSString stringWithFormat:@"Ryan-%i",arc4random()%10000];
    a.address2 = @"Elm St3";
    a.age2 = @(22);
    
    
    __block NSTimeInterval writeStart = [NSDate timeIntervalSinceReferenceDate];
    [a beginTransaction];
    [a beginTransaction];//Whoops! Started a transaction twice!
    do {
        [a insertRecord];
    } while (i-->0);
    
    [a commit];
    
    //Delete the latest
    [a deleteRecord];
    
    
    NSTimeInterval writeDuration = [NSDate timeIntervalSinceReferenceDate] - writeStart;
    NSLog(@"(WRITE) Duration: %f, count: %i, seconds per record: %f", writeDuration, testSize, (writeDuration/testSize));
    
    
    __block int recordCount = 0;
    __block NSTimeInterval readStart = [NSDate timeIntervalSinceReferenceDate];
    [[[App model] allRecords] execute:^(App* record){
        recordCount++;
    } finished:^ (BOOL error){
        NSTimeInterval readDuration = [NSDate timeIntervalSinceReferenceDate] - readStart;
        NSLog(@"(READ) Duration: %f, count: %i, seconds per record: %f", readDuration, recordCount, (readDuration/recordCount));
    }];
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
