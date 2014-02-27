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
    if(!initialized) {
        initialized = YES;
        sharedSingleton = [[RCDataCoder alloc] init];
    }
}

-(id) init{
    self = [super init];
    if (self) {
        dataEncoders = [[NSMutableDictionary alloc] init];
        dataDecoders = [[NSMutableDictionary alloc] init];
        typeAliases = [[NSMutableDictionary alloc] init];
        [self defaultDecoders];
        [self defaultEncoders];

        [self addAlias:@"__NSArrayI" forType:[NSArray class]];
        [self addAlias:@"__NSArrayM" forType:[NSMutableArray class]];
        [self addAlias:@"__NSCFArray" forType:[NSArray class]];
        [self addAlias:@"__NSCFString" forType:[NSString class]];
        [self addAlias:@"__NSDate" forType:[NSDate class]];
        [self addAlias:@"__NSCFConstantString" forType:[NSString class]];
        [self addAlias:@"__NSCFNumber" forType:[NSNumber class]];
                
    }
    return self;
}

+(RCDataCoder*)sharedSingleton{
    return sharedSingleton;
}

-(void) addAlias:(NSString*)alias forType: (Class) class{
    [typeAliases setObject:NSStringFromClass(class) forKey:alias];
}

////////////////////////////////////////////////////////////////////////////////////

-(void)addEncoderForType:(Class)type encoder: (NSString* (^)(id value))encodeBlock{
    [dataEncoders setObject:encodeBlock forKey:NSStringFromClass(type)];
}

-(NSString*)encode:(id) obj{
    NSString* classStr = NSStringFromClass([obj class]);
    
    NSString* (^encodeBlock)(id value) = [dataEncoders objectForKey:classStr];
    if (encodeBlock == NULL){
        //Fetch aliases if needed
        encodeBlock = [dataEncoders objectForKey:[typeAliases objectForKey: classStr]];
    }
    
    return [self sanitize: encodeBlock(obj)];
}

////////////////////////////////////////////////////////////////////////////////////

-(void)addDecoderForType:(Class)type decoder: (id (^)(NSString* value, Class type))decodeBlock{
    [dataDecoders setObject:decodeBlock forKey:NSStringFromClass(type)];
}

-(id)decode:(NSString*) stringRepresentation toType:(Class)type{
    //You have no idea how much this irks me.
    NSString* classStr = NSStringFromClass(type);
    id (^decodeBlock)(NSString* value, Class type) = [dataDecoders objectForKey:classStr];
    if (decodeBlock == NULL){
        //Fetch aliases if needed
        decodeBlock = [dataDecoders objectForKey:[typeAliases objectForKey: classStr]];
    }
    return decodeBlock(stringRepresentation, type);
}

////////////////////////////////////////////////////////////////////////////////////

-(void)defaultDecoders {
    __typeof__(self) __weak weakself = self;
    
    [self addDecoderForType:[NSArray class] decoder:^id(NSString* stringRepresentation, Class type) {
        NSError* err = nil;
        return [NSJSONSerialization JSONObjectWithData: [stringRepresentation dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&err];
    }];
    
    [self addDecoderForType:[NSDictionary class] decoder:^id(NSString* stringRepresentation, Class type) {
        NSError* err = nil;
        return [NSJSONSerialization JSONObjectWithData: [stringRepresentation dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&err];
    }];
    
    [self addDecoderForType:[NSString class] decoder:^id(NSString* stringRepresentation, Class type) {
        return [weakself sanitize: stringRepresentation];
    }];
    
    [self addDecoderForType:[NSNumber class] decoder:^id(NSString* stringRepresentation, Class type) {
        static NSNumberFormatter* numFormatter;
        if (numFormatter == nil) {
            numFormatter = [[NSNumberFormatter alloc] init];
            [numFormatter setNumberStyle:NSNumberFormatterNoStyle];
        }
        return [numFormatter numberFromString:stringRepresentation];
    }];
    
    [self addDecoderForType:[NSDate class] decoder:^id(NSString* stringRepresentation, Class type) {
        static NSDateFormatter* dateFormatter;
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        }
        return [dateFormatter dateFromString: stringRepresentation];
    }];
}

-(void)defaultEncoders {
    [self addEncoderForType:[NSArray class] encoder:^NSString*(NSArray* obj) {
        NSError* err;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&err];
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }];
    [self addEncoderForType:[NSMutableArray class] encoder:^NSString*(NSArray* obj) {
        NSError* err;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&err];
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }];
    [self addEncoderForType:[NSDictionary class] encoder:^NSString*(NSDictionary* obj) {
        NSError* err;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&err];
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }];
    __typeof__(self) __weak weakself = self;
    [self addEncoderForType:[NSString class] encoder:^NSString*(NSString* obj) {
        return [weakself sanitize:[NSString stringWithFormat:@"%@",obj] ]; //As a safety precaution
    }];
    [self addEncoderForType:[NSNumber class] encoder:^NSString*(NSNumber* obj) {
        return [NSString stringWithFormat:@"%@",obj]; //Works pretty well
    }];
    [self addEncoderForType:[NSDate class] encoder:^NSString*(NSDate* obj) {
        return [NSString stringWithFormat:@"%@", obj]; //You may want to override this.
    }];
}

////////////////////////////////////////////////////////////////////////////////////

-(NSString*) sanitize: (NSString*) value{
    value = [NSString stringWithFormat:@"%@",value];
    value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
    value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    return value;
}



@end
