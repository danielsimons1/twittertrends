//
//  Candidate.h
//  twending
//
//  Created by Daniel Simons on 6/3/15.
//  Copyright (c) 2015 Daniel Simons. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Candidate : NSManagedObject

@property (nonatomic, retain) NSString *twittername;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *imageURL;
@property (nonatomic, retain) NSString *backgroundImageURL;
@property (nonatomic, retain) NSString *accountDescriptor;
@property (nonatomic, retain) NSNumber *followersCount;
@property (nonatomic, retain) NSNumber *listsCount;
@property (nonatomic, retain) NSNumber *friendsCount;
@property (nonatomic, retain) NSNumber *tweetsCount;
@property (nonatomic, retain) NSNumber *retweetsCount;
@property (nonatomic, retain) NSNumber *friend;

- (id)initWithTwittername:(NSString*)twittername;

@end
