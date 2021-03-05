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

int command_new(int argc, const char **argv);
int subcommand_new_site(int argc, const char **argv);
void subcommand_new_page(const char **argv);
void subcommand_new_post(const char **argv);

void command_serve(const char **argv);
void command_build(const char **argv);
void command_publish(const char **argv);

void usage()
{
    fprintf(stderr, "usage: ho [command] [subcommand] [arguments...]\n");
    fprintf(stderr, "\tho new site \"Silly Utility\" silly-www\n");
    fprintf(stderr, "\tho new page \"The End of the Web\"\n");
    fprintf(stderr, "\tho new post \"How to write a blog post\"\n");
    fprintf(stderr, "\tho serve\n");
    fprintf(stderr, "\tho build\n");
    fprintf(stderr, "\tho publish\n");
    exit(1);
}

int main(int argc, const char **argv)
{
    HO_BEGIN_AUTORELEASEPOOL

    const char *command;

    if (argc < 2)
        usage();

    command = argv[1];

    if (strcmp(command, "new") == 0)
        return command_new(argc - 2, argv + 2);

    HO_END_AUTORELEASEPOOL

    return 0;
}

int command_new(int argc, const char **argv)
{
    const char *subcmd;

    if (argc < 1) {
        fprintf(stderr, "`new' requires type and argument\n");
        return 1;
    }

    subcmd = argv[0];

    if (strcmp(subcmd, "site") == 0)
        return subcommand_new_site(argc - 1, argv + 1);

    return 1;
}

int subcommand_new_site(int argc, const char **argv)
{
    char *sitename, *sitedir = NULL;
    NSString *siteName, *siteDir;
    NSError *err;
    HOSite *site;

    if (argc < 1) {
        fprintf(stderr, "`new site' requires \"site name\"\n");
        return 1;
    }

    sitename = strdup(argv[0]);

    if (argc == 1) {
        fprintf(stderr, "using current directory as site root\n");
        sitedir = getcwd(sitedir, MAXPATHLEN);
    } else {
        sitedir = strdup(argv[1]);
    }

    fprintf(stderr, "site root is %s\n", sitedir);

    siteName = @(sitename);
    siteDir = @(sitedir);
    site = [HOSite newSiteWithTitle:siteName inDirectory:siteDir error:&err];
    if (err) {
        NSLog(@"site err %@", err);
        return 1;
    }

    return 1;
}
