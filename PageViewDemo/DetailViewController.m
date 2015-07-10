//
//  DetailViewController.m
//  twending
//
//  Created by Daniel Simons on 6/3/15.
//  Copyright (c) 2015 Daniel Simons. All rights reserved.
//

#import "DetailViewController.h"
#import "PNChart.h"
#import <Parse/Parse.h>
#import <TwitterKit/TwitterKit.h>
#import "WMGaugeView.h"
#import "Colours.h"
#import "MBProgressHUD.h"
#import "Flurry.h"
#import "DataAccess.h"
#import "CNPPopupController.h"
#import "iRate.h"
#import <iAd/iAd.h>
#import "twittertrends-Swift.h"

#define FBOX(x) [NSNumber numberWithFloat:x]


@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (strong, nonatomic) PNBarChart *barChart;
@property (strong, nonatomic) NSMutableData *chartData;
@property (weak, nonatomic) IBOutlet UIView *chartWrapperView;
@property (weak, nonatomic) IBOutlet UIView *gaugeWrapperView;
@property (strong, nonatomic) WMGaugeView *gaugeView;
@property (weak, nonatomic) IBOutlet SpringButton *popularityButton;
@property (strong, nonatomic) NSMutableArray *friendsArray;
@property (strong, nonatomic) NSMutableDictionary *friendsStatusTimeLines;
@property (strong, nonatomic) NSNumber *counter;
@property (strong, nonatomic) CNPPopupController *shareRatePickerController;
@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.canDisplayBannerAds = YES;
    self.friendsArray = [NSMutableArray array];
    self.friendsStatusTimeLines = [NSMutableDictionary dictionary];
    [Flurry logEvent:@"DetailViewController viewDidLoad"];
    
    //self.canDisplayBannerAds = YES;
    // Do any additional setup after loading the view.
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = [NSString stringWithFormat:@"@%@",self.candidate.twittername];
    
    //self.followerCount.format = @"%d%d.%d%d";
    //[self.followerCount countFrom:0. to:self.count.floatValue];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"Friends" style:UIBarButtonItemStyleBordered target:self action:@selector(addFriends)];
    self.navigationItem.rightBarButtonItem = backItem;
    self.navigationItem.title = self.candidate.name;
    [self.navigationController setTitle:self.candidate.name];
    [self.followerCount setText:[DetailViewController abbreviateNumber:self.candidate.followersCount.intValue withDecimal:100]];
    [self.listsCountLabel setText:[DetailViewController abbreviateNumber:self.candidate.listsCount.intValue withDecimal:100]];
    [self.friendsCountLabel setText:[DetailViewController abbreviateNumber:self.candidate.friendsCount.intValue withDecimal:100]];
    [self.tweetsCountLabel setText:[DetailViewController abbreviateNumber:self.candidate.tweetsCount.intValue withDecimal:100]];
    [self.retweetsCountLabel setText:[DetailViewController abbreviateNumber:self.candidate.retweetsCount.intValue withDecimal:100]];
    
    [self.avatarImageView setImage:self.backgroundImage];
    [self.avatarImageView.layer setMasksToBounds:YES];
    [self.avatarImageView.layer setCornerRadius:30.];
    
    self.barChart.delegate = self;
    
    [self configureGauge];
    
    [self.popularityButton setTitle:[NSString stringWithFormat:@"%.02f",[DetailViewController popularityScore:self.candidate]] forState:UIControlStateNormal];
    
    //[self configureView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    float popularityScore = [DetailViewController popularityScore:self.candidate];
    
    [self.gaugeView setValue:popularityScore animated:YES duration:1.6 completion:^(BOOL finished) {
        NSLog(@"gaugeView animation complete");
    }];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

+ (float)popularityScore:(Candidate *)candidate {
    NSInteger followers = candidate.followersCount.integerValue;
    NSInteger listed = candidate.listsCount.integerValue;
    NSInteger friends = candidate.friendsCount.integerValue;
    NSInteger tweets = candidate.tweetsCount.integerValue;
    NSInteger retweets = candidate.retweetsCount.integerValue;
    
    float baseValue = ((listed * 100) + sqrt(followers) + sqrt(friends) - (tweets) + (retweets * 1000) ) / 1000;
    
    if (baseValue < 0) {
        baseValue = 0;
    }
    float finalValue = sqrt(baseValue);
    if (finalValue < 0.07) {
        finalValue = 0.07;
    }
    else if (finalValue > 99.98) {
        finalValue = 99.98;
    }
    return finalValue;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureGauge {
    self.gaugeView = [[WMGaugeView alloc] initWithFrame:CGRectMake(0, 0, 250,250.0)];
    self.gaugeView.maxValue = 100.0;
    self.gaugeView.scaleDivisions = 10;
    self.gaugeView.scaleSubdivisions = 5;
    self.gaugeView.scaleStartAngle = 30;
    self.gaugeView.scaleEndAngle = 330;
    self.gaugeView.innerBackgroundStyle = WMGaugeViewInnerBackgroundStyleGradient;
    self.gaugeView.showScaleShadow = NO;
    self.gaugeView.scaleFont = [UIFont fontWithName:@"AvenirNext-UltraLight" size:0.04];
    self.gaugeView.scalesubdivisionsAligment = WMGaugeViewSubdivisionsAlignmentCenter;
    self.gaugeView.scaleSubdivisionsWidth = 0.002;
    self.gaugeView.scaleSubdivisionsLength = 0.04;
    self.gaugeView.scaleDivisionsWidth = 0.007;
    self.gaugeView.scaleDivisionsLength = 0.07;
    self.gaugeView.needleStyle = WMGaugeViewNeedleStyle3D;
    self.gaugeView.needleWidth = 0.012;
    self.gaugeView.needleHeight = 0.4;
    self.gaugeView.needleScrewStyle = WMGaugeViewNeedleScrewStyleGradient;
    self.gaugeView.needleScrewRadius = 0.05;
    self.gaugeView.showScale = YES;
    self.gaugeView.showInnerBackground = NO;
    self.gaugeView.backgroundColor = [UIColor clearColor];
    self.gaugeView.showRangeLabels = YES;
    self.gaugeView.rangeValues = @[@20, @40, @60, @80, @100];
    self.gaugeView.rangeColors = @[[UIColor denimColor],[UIColor skyBlueColor], [UIColor successColor], [UIColor mandarinColor], [UIColor crimsonColor]];
    self.gaugeView.rangeLabels = @[@"Cold", @"Mild", @"Warm", @"Hot", @"On Fire"];
    self.gaugeView.rangeLabelsFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:.065];
    self.gaugeView.rangeLabelsWidth = .12;
    [self.gaugeWrapperView addSubview:self.gaugeView];
    
    [self.gaugeWrapperView bringSubviewToFront:self.avatarImageView];
    
}

- (void)configureView {
    PFQuery *query = [PFQuery queryWithClassName:@"FollowerCount"];
    [[query whereKey:@"twittername" equalTo:self.candidate.twittername] findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"Result %@", objects);
        
        NSMutableArray* xLabels = [NSMutableArray new];
        NSMutableArray* yValues = [NSMutableArray new];
        
        NSInteger moduloFactor = 1 + ( objects.count / 5 );
        for (PFObject *followerCount in objects) {
            if ([objects indexOfObject:followerCount] % moduloFactor == 0) {
                NSDateFormatter *format = [[NSDateFormatter alloc] init];
                if (objects.count < 130) {
                    [format setDateFormat:@"MMM dd"];
                } else {
                    [format setDateFormat:@"MMM `yy"];
                }
                NSString *xLabel = [format stringFromDate:[followerCount createdAt]];
                float yLabel = [[followerCount objectForKey:@"count"] floatValue];
                
                [xLabels addObject:xLabel];
                [yValues addObject:FBOX(yLabel)];
            }
        }
        
        self.barChart = [[PNBarChart alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH - 20, SCREEN_HEIGHT / 3)];
        
        self.barChart.backgroundColor = [UIColor clearColor];
        
        self.barChart.yLabelFormatter = ^(CGFloat yValue){
            CGFloat yValueParsed = yValue;
            return [DetailViewController abbreviateNumber:yValueParsed withDecimal:100];
        };
        self.barChart.labelMarginTop = 5.0;
        [self.barChart setXLabels:xLabels];
        self.barChart.rotateForXAxisText = true ;
        [self.barChart setYValues:yValues];
        self.barChart.strokeColor = PNFreshGreen;
        //[self.barChart setStrokeColors:@];
        // Adding gradient
        
        self.barChart.barColorGradientStart = PNFreshGreen;
        self.barChart.barBackgroundColor = PNLightGreen;
        [self.barChart strokeChart];
        
        //self.barChart.delegate = self;
        
        [self.chartWrapperView addSubview:self.barChart];
     }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

+(NSString *)abbreviateNumber:(int)num withDecimal:(int)dec {
    
    if (num < 1000) {
        return [NSString stringWithFormat:@"%i",num];
    }
    
    NSString *abbrevNum;
    float number = (float)num;
    
    NSArray *abbrev = @[@"K", @"M", @"B"];
    
    for (int i = abbrev.count - 1; i >= 0; i--) {
        
        // Convert array index to "1000", "1000000", etc
        int size = pow(10,(i+1)*3);
        
        if(size <= number) {
            // Here, we multiply by decPlaces, round, and then divide by decPlaces.
            // This gives us nice rounding to a particular decimal place.
            number = round(number*dec/size)/dec;
            
            NSString *numberString = [self floatToString:number];
            
            // Add the letter for the abbreviation
            abbrevNum = [NSString stringWithFormat:@"%@%@", numberString, [abbrev objectAtIndex:i]];
            
            NSLog(@"%@", abbrevNum);
            
        }
        
    }
    
    
    return abbrevNum;
}

+(NSString *) floatToString:(float) val {
    
    NSString *ret = [NSString stringWithFormat:@"%.1f", val];
    unichar c = [ret characterAtIndex:[ret length] - 1];
    
    while (c == 48 || c == 46) { // 0 or .
        ret = [ret substringToIndex:[ret length] - 1];
        c = [ret characterAtIndex:[ret length] - 1];
    }
    
    return ret;
}

- (void)addFriends {
    [Flurry logEvent:@"DetailViewController addFriends"];
    
    [self retrieveFriendsFromTwitter:@"-1"];
    
}

- (void)retrieveFriendsFromTwitter:(NSString *)cursor {
    if (!self.friendsArray || self.friendsArray.count < 1) {
    NSString *statusesShowEndpoint = @"https://api.twitter.com/1.1/friends/list.json";
    NSDictionary *params = @{@"screen_name" : self.candidate.twittername,@"cursor" : cursor, @"count" : @"200"};
        NSError *clientError;
        NSURLRequest *request = [[[Twitter sharedInstance] APIClient]
                                 URLRequestWithMethod:@"GET"
                                 URL:statusesShowEndpoint
                                 parameters:params
                                 error:&clientError];
        self.counter = [NSNumber numberWithInteger:0];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        if (request) {
            [[[Twitter sharedInstance] APIClient]
             sendTwitterRequest:request
             completion:^(NSURLResponse *response,
                          NSData *data,
                          NSError *connectionError) {
                 if (data) {
                     
                     NSError *jsonError;
                     NSMutableDictionary *json = [NSJSONSerialization
                                           JSONObjectWithData:data
                                           options:0
                                           error:&jsonError];
                     NSMutableArray *friendsArray = json[@"users"];
                     
                     self.friendsArray = friendsArray;
                     // handle the response data e.g.
                     
                     //[self handleFriendsListResponse:self.friendsArray];
                     [self handleFriendsResponse:self.friendsArray];
                 }
                 else {
                     NSLog(@"Error: %@", connectionError);
                     [MBProgressHUD hideHUDForView:self.view animated:YES];
                     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"The request cannot be completed at this time." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                     [alertView show];
                 }
             }];
        }
        else {
            NSLog(@"Error: %@", clientError);
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Twitter Error" message:@"The request to Twitter cannot be completed at this time." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alertView show];
        }
    } else {
        [self handleFriendsResponse:self.friendsArray];
    }
}

- (void)handleFriendsResponse:(NSArray *)friendsArray {
    for (NSDictionary *friend in friendsArray) {
        [[DataAccess sharedInstance] saveOrUpdateCandidate:friend withRetweets:0 isFriend:YES];
    }
    [self didFinishFriendLoad];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}



- (IBAction)didPressShareButton:(id)sender {
    [Flurry logEvent:@"pressed share button"];
    
    NSString *primaryText = [NSString stringWithFormat:@"Check out @%@'s social trends. Powered by Unofficial Calculators http://itunes.apple.com/app/id1004194486",self.candidate.twittername];
    UIGraphicsBeginImageContext(self.view.bounds.size);
    
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[viewImage, primaryText] applicationActivities:nil];
    
    activityVC.excludedActivityTypes = @[UIActivityTypePostToVimeo, UIActivityTypePostToWeibo];
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)didFinishFriendLoad {
    [self performSegueWithIdentifier:@"friendsList" sender:self.candidate];
}

- (IBAction)didPressLogout:(id)sender {
    [TwitterKit logOut];
    [self dismissViewControllerAnimated:YES completion:nil];
    [[DataAccess sharedInstance] logout];
}

- (IBAction)didPressShareTwitter:(id)sender {
    [Flurry logEvent:@"pressed rate or share button"];
    [self displayShareOrRatePicker];
}

- (void)displayShareOrRatePicker {
    CNPPopupButtonItem *twitter = [CNPPopupButtonItem defaultButtonItemWithTitle:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Share on Facebook"] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}] backgroundColor:[UIColor denimColor]];
    CNPPopupButtonItem *facebook = [CNPPopupButtonItem defaultButtonItemWithTitle:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Share on Twitter"] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}] backgroundColor:[UIColor skyBlueColor]];
    
    CNPPopupButtonItem *rateApp = [CNPPopupButtonItem defaultButtonItemWithTitle:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Rate the app"] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}] backgroundColor:[UIColor successColor]];
    
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    self.shareRatePickerController = [[CNPPopupController alloc] initWithTitle:[[NSAttributedString alloc] initWithString:@"Share Twitter Score" attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:24], NSParagraphStyleAttributeName : paragraphStyle, NSForegroundColorAttributeName : [UIColor mandarinColor]}] contents:nil buttonItems:@[twitter, facebook, rateApp] destructiveButtonItem:nil];
    
    
    CNPPopupTheme *theme = [CNPPopupTheme defaultTheme];
    [theme setShouldDismissOnBackgroundTouch:YES];
    [theme setMaskType:CNPPopupMaskTypeDimmed];
    [theme setPopupStyle:CNPPopupStyleCentered];
    
    [self.shareRatePickerController setTheme:theme];
    [self.shareRatePickerController setDelegate:self];
    [self.shareRatePickerController presentPopupControllerAnimated:YES];
}

- (void)popupController:(CNPPopupController *)controller didDismissWithButtonTitle:(NSString *)title {
    if ([title isEqualToString:@"Share on Twitter"]) {
        [Flurry logEvent:@"pressed Share on Twitter"];
        SLComposeViewController *tweetSheet = [SLComposeViewController
                                               composeViewControllerForServiceType:SLServiceTypeTwitter];
        UIGraphicsBeginImageContext(self.gaugeWrapperView.bounds.size);
        
        [self.gaugeWrapperView.layer renderInContext:UIGraphicsGetCurrentContext()];
        
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        [tweetSheet addImage:viewImage];
        [tweetSheet setInitialText:@"Check out this Twitter Score http://itunes.apple.com/app/id1004557203"];
        
        [self presentViewController:tweetSheet animated:YES completion:nil];
    } else if ([title isEqualToString:@"Share on Facebook"]) {
        [Flurry logEvent:@"pressed Share on Facebook"];
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        UIGraphicsBeginImageContext(self.gaugeWrapperView.bounds.size);
        
        [self.gaugeWrapperView.layer renderInContext:UIGraphicsGetCurrentContext()];
        
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        [controller addImage:viewImage];
        [controller setInitialText:@"Check out this Twitter Score http://itunes.apple.com/app/id1004557203"];
        [self presentViewController:controller animated:YES completion:Nil];
        
    } else if ([title isEqualToString:@"Rate the app"]) {
        [Flurry logEvent:@"pressed Rate the app"];
        [[UIApplication sharedApplication] openURL:[iRate sharedInstance].ratingsURL];
    }
}

@end
