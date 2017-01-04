//
//  HeapAnnotation.h
//  TagTheBus
//
//  Created by Victor Vostriakov on 02/10/2016.
//  Copyright © 2016 Victor Vostriakov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface HeapAnnotation : NSObject  <MKAnnotation>
@property MKCoordinateRegion region;
@property (nonatomic) int numberOfPins;
@end
