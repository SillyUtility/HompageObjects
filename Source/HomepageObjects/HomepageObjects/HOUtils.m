//
//  HOUtils.m
//  HomepageObjects
//
//  Created by Eddie Hillenbrand on 4/1/21.
//  Copyright © 2021 Silly Utility LLC. All rights reserved.
//

#import "HOUtils.h"

void log_indent(NSUInteger level, const char *fmt, const char *arg)
{
    while (level--)
        fprintf(stderr, "  ");
    fprintf(stderr, fmt, arg);
}
