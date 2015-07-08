//
//  Candidate.m
//  twending
//
//  Created by Daniel Simons on 6/3/15.
//  Copyright (c) 2015 Daniel Simons. All rights reserved.
//

#import "Candidate.h"

@implementation Candidate

@dynamic name;
@dynamic twittername;
@dynamic imageURL;
@dynamic backgroundImageURL;
@dynamic accountDescriptor;
@dynamic followersCount;
@dynamic listsCount;
@dynamic friendsCount;
@dynamic tweetsCount;
@dynamic retweetsCount;
@dynamic friend;

- (id)initWithTwittername:(NSString *)twittername {
    if ((self = [super init])) {
        self.twittername = twittername;
    }
    return self;
}

@end
