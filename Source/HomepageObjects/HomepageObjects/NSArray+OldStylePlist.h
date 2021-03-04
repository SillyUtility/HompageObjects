//
//  NSArray+OldStylePlist.h
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 3/3/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (OldStylePlist)

- (BOOL)writeOldStylePlistToURL:(NSURL *)url
    error:(NSError * _Nullable *)error;
    
@end

NS_ASSUME_NONNULL_END
