//
//  DetailViewController.h
//  twending
//
//  Created by Daniel Simons on 6/3/15.
//  Copyright (c) 2015 Daniel Simons. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UICountingLabel.h"
#import "Candidate.h"
#import "PNChart.h"
#import "CNPPopupController.h"

@interface DetailViewController : UIViewController <PNChartDelegate, CNPPopupControllerDelegate>
@property (strong, nonatomic) IBOutlet UICountingLabel *followerCount;
@property (weak, nonatomic) IBOutlet UICountingLabel *listsCountLabel;
@property (weak, nonatomic) IBOutlet UICountingLabel *friendsCountLabel;
@property (weak, nonatomic) IBOutlet UICountingLabel *tweetsCountLabel;
@property (weak, nonatomic) IBOutlet UICountingLabel *retweetsCountLabel;
@property (strong, nonatomic) Candidate *candidate;
@property (strong, nonatomic) UIImage *backgroundImage;
+(NSString *)abbreviateNumber:(int)num withDecimal:(int)dec;
+ (float)popularityScore:(Candidate *)candidate;

@end
