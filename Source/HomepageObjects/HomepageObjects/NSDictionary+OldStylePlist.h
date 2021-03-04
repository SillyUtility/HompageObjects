//
//  NSDictionary+OldStylePlist.h
//  
//
//  Created by Eddie Hillenbrand on 3/3/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (OldStylePlist)

- (BOOL)writeOldStylePlistToURL:(NSURL *)url
    error:(NSError * _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
