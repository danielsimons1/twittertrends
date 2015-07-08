//
//  FriendsDetailViewController.h
//  twittertrends
//
//  Created by Daniel Simons on 6/10/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PNChart.h"
#import "DataAccess.h"
#import "CNPPopupController.h"

@interface FriendsDetailViewController : UIViewController <PNChartDelegate, CNPPopupControllerDelegate>
@property (strong, nonatomic) IBOutlet UICountingLabel *followerCount;
@property (weak, nonatomic) IBOutlet UICountingLabel *listsCountLabel;
@property (weak, nonatomic) IBOutlet UICountingLabel *friendsCountLabel;
@property (weak, nonatomic) IBOutlet UICountingLabel *tweetsCountLabel;
@property (weak, nonatomic) IBOutlet UICountingLabel *retweetsCountLabel;
@property (strong, nonatomic) Candidate *candidate;
@property (strong, nonatomic) UIImage *backgroundImage;
@end