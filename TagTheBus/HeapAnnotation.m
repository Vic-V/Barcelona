//
//  HeapAnnotation.m
//  TagTheBus
//
//  Created by Victor Vostriakov on 02/10/2016.
//  Copyright © 2016 Victor Vostriakov. All rights reserved.
//

#import "HeapAnnotation.h"

@implementation HeapAnnotation
- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = self.region.center.latitude;
    coordinate.longitude = self.region.center.longitude;
    return coordinate;
}
- (NSString *)title {
    return [NSString stringWithFormat:@"%d stations", self.numberOfPins];
}
@end
