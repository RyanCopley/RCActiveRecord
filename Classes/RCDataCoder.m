//
//  RCDataDecoder.m
//  RCActiveRecord
//
//  Created by Ryan Copley on 2/5/14.
//  Copyright (c) 2014 Ryan Copley. All rights reserved.
//

#import "RCDataCoder.h"

@implementation RCDataCoder

static RCDataCoder *sharedSingleton;

+ (void)initialize {
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        sharedSingleton = [[RCDataCoder alloc] init];
    }
}

-(id) init{
    self = [super init];
    if (self){
        dataEncoders = [[NSMutableDictionary alloc] init];
        dataDecoders = [[NSMutableDictionary alloc] init];
        
        [self defaultDecoders];
        [self defaultEncoders];
    }
    return self;
}

+(RCDataCoder*)sharedSingleton{
    return sharedSingleton;
}

////////////////////////////////////////////////////////////////////////////////////

-(void)addEncoderForType:(Class)type encoder: (NSString* (^)(id value))encodeBlock{
    [dataEncoders setObject:encodeBlock forKey:NSStringFromClass(type)];
}

-(void)removeEncoderForType:(Class) type{
    [dataEncoders removeObjectForKey:NSStringFromClass(type)];
}

-(NSString*) encode:(id) obj{
    NSString* (^encodeBlock)(id value) = [dataEncoders objectForKey:NSStringFromClass([obj class])];
    return encodeBlock(obj);
}

////////////////////////////////////////////////////////////////////////////////////

-(void)addDecoderForType:(Class)type decoder: (id (^)(NSString* value))decodeBlock{
    [dataDecoders setObject:decodeBlock forKey:NSStringFromClass(type)];
}

-(void)removeDecoderForType:(Class) type{
    [dataDecoders removeObjectForKey:NSStringFromClass(type)];
}

-(id) decode:(NSString*) stringRepresentation toType:(Class)type{
    //You have no idea how much this irks me. 
    NSString* classStr = [[[NSStringFromClass(type) stringByReplacingOccurrencesOfString:@"__" withString:@""] stringByReplacingOccurrencesOfString:@"CF" withString:@""] stringByReplacingOccurrencesOfString:@"Constant" withString:@""];
    id (^decodeBlock)(NSString* value) = [dataDecoders objectForKey:classStr];
    return decodeBlock(stringRepresentation);
}

////////////////////////////////////////////////////////////////////////////////////

-(void) defaultDecoders {

    [self addDecoderForType:[NSArray class] decoder:^id(NSString* stringRepresentation){
        NSError* err = nil;
        return [NSJSONSerialization JSONObjectWithData: [stringRepresentation dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&err];
    }];
    
    [self addDecoderForType:[NSDictionary class] decoder:^id(NSString* stringRepresentation){
        NSError* err = nil;
        return [NSJSONSerialization JSONObjectWithData: [stringRepresentation dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&err];
    }];
    
    [self addDecoderForType:[NSString class] decoder:^id(NSString* stringRepresentation){
        return stringRepresentation;
    }];
    
    [self addDecoderForType:[NSNumber class] decoder:^id(NSString* stringRepresentation){
        static NSNumberFormatter* numFormatter;
        if (numFormatter == nil){
            numFormatter = [[NSNumberFormatter alloc] init];
            [numFormatter setNumberStyle:NSNumberFormatterNoStyle];
        }
        
        return [numFormatter numberFromString:stringRepresentation];
    }];
    
    [self addDecoderForType:[NSDate class] decoder:^id(NSString* stringRepresentation){
        static NSDateFormatter* dateFormatter;
        if (dateFormatter == nil){
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        }
        
        return [dateFormatter dateFromString: stringRepresentation];
    }];
}

-(void)defaultEncoders {
    [self addEncoderForType:[NSArray class] encoder:^NSString*(NSArray* obj){
        NSError* err;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&err];
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }];
    
    [self addEncoderForType:[NSDictionary class] encoder:^NSString*(NSDictionary* obj){
        NSError* err;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&err];
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }];
    
    [self addEncoderForType:[NSString class] encoder:^NSString*(NSString* obj){
        return [NSString stringWithFormat:@"%@",obj]; //As a safety precaution
    }];
    
    [self addEncoderForType:[NSNumber class] encoder:^NSString*(NSNumber* obj){
        return [NSString stringWithFormat:@"%@",obj]; //Works pretty well
    }];
    
    [self addEncoderForType:[NSDate class] encoder:^NSString*(NSDate* obj){
        return [NSString stringWithFormat:@"%@", obj]; //You may want to override this.
    }];
}

////////////////////////////////////////////////////////////////////////////////////

//This will need to be done in every model (Automatically)
/*
 NSError* err;
 
 BOOL preload = [ARClass preloadEnabled];
 if (preload && [class isSubclassOfClass:[RCActiveRecord class]]){
 //To do this shit still D:
 
 __block RCActiveRecord* model = [class model];
 
 NSNumber* pk = [numFormatter numberFromString:stringRepresentation];
 __block id _record;
 [[model recordByPK: pk] execute:^(id record){
 _record = record;
 }];
 return _record;
 
 }
 
 return stringRepresentation;
 */

@end
