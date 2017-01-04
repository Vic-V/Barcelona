//
//  SegmentedViewController.m
//  TagTheBus
//
//  Created by Victor Vostriakov on 29/09/2016.
//  Copyright © 2016 Victor Vostriakov. All rights reserved.
//

#import "SegmentedViewController.h"
#import <MapKit/MapKit.h>

@interface SegmentedViewController ()
@property (weak, nonatomic) IBOutlet UIView *mapContainer;
@property (weak, nonatomic) IBOutlet UIView *tableContainer;
@property (weak, nonatomic) UITableViewController *listVC;
@property (weak, nonatomic) UIViewController *mapVC;
@end

@implementation SegmentedViewController

- (IBAction)segmentChanged:(UISegmentedControl *)sender {
    NSString *selectedTitle = [sender titleForSegmentAtIndex:sender.selectedSegmentIndex];
    BOOL isMap = [selectedTitle isEqualToString:@"Map"];
    self.tableContainer.hidden = isMap;
    self.mapContainer.hidden = !isMap;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableContainer.hidden = YES;
    self.mapContainer.hidden = NO;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Embed Map"]) {
        self.mapVC = segue.destinationViewController;
    } else
        if ([segue.identifier isEqualToString:@"Embed List"]) {
            self.listVC = segue.destinationViewController;
        }
}

@end
