//
//  NSFileManager+HOAdditons.h
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/5/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (HOAdditons)

- (BOOL)isEmptyDirectoryAtPath:(NSString *)dir;

@end

NS_ASSUME_NONNULL_END
