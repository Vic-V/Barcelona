//
//  Station+Annotation.m
//  TagTheBus
//
//  Created by Victor Vostriakov on 29/09/2016.
//  Copyright © 2016 Victor Vostriakov. All rights reserved.
//

#import "Station+Annotation.h"

@implementation Station (Annotation)
- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [self.latitude doubleValue];
    coordinate.longitude = [self.longitude doubleValue];
    return coordinate;
}
@end
