//
//  main.m
//  ho
//
//  Created by Eddie Hillenbrand on 3/2/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HomepageObjects/HomepageObjects.h>

#define HO_BEGIN_AUTORELEASEPOOL @autoreleasepool {
#define HO_END_AUTORELEASEPOOL }

int main(int argc, const char * argv[])
{
    HO_BEGIN_AUTORELEASEPOOL

    HOConfig *config = HOConfig.new;
    NSLog(@"ho config %@", config);

    HO_END_AUTORELEASEPOOL

    return 0;
}
