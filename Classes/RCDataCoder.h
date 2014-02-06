//
//  RCDataDecoder.h
//  RCActiveRecord
//
//  Created by Ryan Copley on 2/5/14.
//  Copyright (c) 2014 Ryan Copley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCDataCoder : NSObject{
    NSMutableDictionary* dataEncoders;
    NSMutableDictionary* dataDecoders;
    
}
+(RCDataCoder*)sharedSingleton;
-(NSString*) encode:(id) obj;
-(id) decode:(NSString*) stringRepresentation toType:(Class)type;
@end