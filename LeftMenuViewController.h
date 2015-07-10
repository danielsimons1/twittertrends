//
//  LeftMenuViewController.h
//  caprate
//
//  Created by Daniel Simons on 6/28/15.
//  Copyright (c) 2015 Daniel Simons. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RESideMenu.h"

@interface LeftMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RESideMenuDelegate>

@property (strong, readwrite, nonatomic) UITableView *tableView;

@end
