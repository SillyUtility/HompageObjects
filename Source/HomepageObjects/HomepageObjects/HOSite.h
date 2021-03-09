//
//  HOSite.h
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/1/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HOConfig;

@interface HOSite : NSObject

- initWithConfig:(HOConfig *)config;

+ (instancetype)newSiteWithTitle:(NSString *)title
    inDirectory:(NSString *)dir error:(NSError * _Nullable *)error;

@property NSString *title;
@property NSString *baseURL;
@property HOConfig *config;

+ (instancetype)siteAtPath:(NSString *)path error:(NSError * _Nullable *)error;

- (void)buildAndReturnError:(NSError * _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
