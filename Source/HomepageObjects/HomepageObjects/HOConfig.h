//
//  HOConfig.h
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/2/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HOConfig : NSObject

- initWithPath:(NSString *)path;

+ (instancetype)configAtPath:(NSString *)path;

- (id)objectForKeyedSubscript:(id<NSCopying>)key;
- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key;

@property (readonly) NSString *contentRoot;
@property (readonly) NSString *buildRoot;

@property (readonly) NSDictionary *dictionary;

@end

NS_ASSUME_NONNULL_END
