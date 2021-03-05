//
//  HOSite.h
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/1/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HOSite : NSObject

+ newSiteWithTitle:(NSString *)title
    inDirectory:(NSString *)dir error:(NSError * _Nullable *)error;

@property NSString *title;
@property NSString *baseURL;

@end

NS_ASSUME_NONNULL_END
