//
//  MapViewController.m
//  TagTheBus
//
//  Created by Victor Vostriakov on 03/10/2016.
//  Copyright © 2016 Victor Vostriakov. All rights reserved.
//

#import "MapViewController.h"
#import "MapKit/MapKit.h"
#import "Station+Annotation.h"
#import "AppDelegate.h"
#import "HeapAnnotation.h"
#import "StationDbNotifications.h"

@interface MapViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSArray *annotations;
@property (nonatomic) MKCoordinateRegion *region;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic) MKZoomScale lastZoomScale;
@end

@implementation MapViewController

- (void)setMapView:(MKMapView *)mapView
{
    if (!_mapView) {
    _mapView = mapView;
    self.mapView.delegate = self;
    
    self.lastZoomScale = 1.0;
    
    NSArray *region = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastRegion"];
    if (!region)
        self.mapView.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(41.4035667, 2.174380), MKCoordinateSpanMake(0.01, 0.01));
    else
        self.mapView.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake([region[0] doubleValue], [region[1] doubleValue]),
                                                     MKCoordinateSpanMake([region[2] doubleValue], [region[3] doubleValue]));
    }
}

- (void)updateUI {
    if (self.context && self.mapView) {
        [self annotationsIn:self.mapView.region];
    }
}

- (void)addObserverFor:(NSString *)notificationName {
    [[NSNotificationCenter defaultCenter] addObserverForName:notificationName object:nil queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        self.context = note.userInfo[StationDbContext];
        [self updateUI];
    }];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self addObserverFor:StationDbAvailabilityNotification];
    [self addObserverFor:StationDbUpdatedNotification];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateUI];
}

- (MKZoomScale)zoomScale {
    return self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    MKCoordinateRegion reg = self.mapView.region;
    [self annotationsIn:reg];
    [[NSUserDefaults standardUserDefaults] setObject:@[ @(reg.center.latitude), @(reg.center.longitude),
                                                        @(reg.span.latitudeDelta), @(reg.span.longitudeDelta)]
                                                        forKey:@"lastRegion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


BOOL CoordinateInRegion(CLLocationCoordinate2D coordinate,  MKCoordinateRegion region) {
    return
    coordinate.latitude >= region.center.latitude - region.span.latitudeDelta/2.0 &&
    coordinate.latitude <= region.center.latitude + region.span.latitudeDelta/2.0 &&
    coordinate.longitude >= region.center.longitude - region.span.longitudeDelta/2.0 &&
    coordinate.longitude <= region.center.longitude + region.span.longitudeDelta/2.0;
}

- (BOOL)is:(Station*)station inHeap:(NSArray *)oldHeap {
    for ( id<MKAnnotation> annotation in oldHeap) {
        if ( [annotation isKindOfClass:[HeapAnnotation class]] ) {
            MKCoordinateRegion region = ((HeapAnnotation *)annotation).region;
            CLLocationCoordinate2D coordinate = station.coordinate;
            if (CoordinateInRegion(coordinate, region))
                return YES;
        } else
            if ( [annotation isKindOfClass:[Station class]] &&
                station == annotation )
                return YES;
    }
    return NO;
}

// zoom in/out removeAnnotations:self.mapView.annotations !!!
// only for sliding
// #define nLat 8
// #define nLon 8
// #define nStations 100
- (void)annotationsIn:(MKCoordinateRegion)region
{
    int nLon = (int) (self.view.bounds.size.width / 64);
    int nLat = (int) (self.view.bounds.size.height / 64);
    int nStations = nLon*nLat*2;
    
    float zoomRation = [self zoomScale]/ self.lastZoomScale;
    BOOL isZoomed = zoomRation > 1.1 || zoomRation < 0.9;
    self.lastZoomScale = [self zoomScale];
    
    // keeping Station and HeapAnnotation inside the region
    NSMutableArray *annotationsToRemove = [NSMutableArray array];
    NSMutableArray *annotationsToKeep = [NSMutableArray array];
    for ( id<MKAnnotation> annotation in self.mapView.annotations) {
        if (CoordinateInRegion(annotation.coordinate, region) &&
            (!isZoomed || [annotation isKindOfClass:[Station class]]))  // HeapAnnotations will be excluded
            [annotationsToKeep addObject:annotation];
        else
            [annotationsToRemove addObject:annotation];
    }
    
    [self.mapView removeAnnotations:annotationsToRemove];
    
    [self.context performBlock:^{
        NSArray *stations = [Station inRegion:(MKCoordinateRegion)region inContext:self.context];
        if (stations.count < nStations) {
            [self.mapView addAnnotations:stations];     // ??????
        } else
        {
            double minLatitude = region.center.latitude - region.span.latitudeDelta/2.0;
            double minLongitude = region.center.longitude - region.span.longitudeDelta/2.0;
            double latitudeDelta = region.span.latitudeDelta / nLat;
            double longitudeDelta = region.span.longitudeDelta / nLon;
            int grid[nLat][nLon];
            int stations2D[nLat][nLon];
            for(int lat = 0; lat < nLat; lat++)
                for(int lon = 0; lon < nLon; lon++) {
                    grid[lat][lon] = 0;
                    stations2D[lat][lon] = 0;
                }
            for(Station *s in stations)
                if (![self is:s inHeap:annotationsToKeep])
                {
                    double lat = [s.latitude doubleValue];
                    double lon = [s.longitude doubleValue];
                    int iLat = floor((lat-minLatitude)/latitudeDelta);
                    int iLon = floor((lon-minLongitude)/longitudeDelta);
                    if (!grid[iLat][iLon]) {
                        stations2D[iLat][iLon] = (int)[stations indexOfObject:s] ;
                    }
                    grid[iLat][iLon] ++;
                }
            NSMutableArray *annotations = [NSMutableArray array];
            for(int lat = 0; lat < nLat; lat++)
                for(int lon = 0; lon < nLon; lon++) {
                    if(grid[lat][lon] == 1) {
                        [annotations addObject:stations[stations2D[lat][lon]]];
                    } else if (grid[lat][lon] > 1) {
                        HeapAnnotation *ha = [[HeapAnnotation alloc] init];
                        ha.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(minLatitude + (lat+0.5)*latitudeDelta, minLongitude + (lon+0.5)*longitudeDelta),
                                                           MKCoordinateSpanMake(latitudeDelta, longitudeDelta));
                        ha.numberOfPins = grid[lat][lon];
                        [annotations addObject:ha];
                    }
                }
            [self.mapView addAnnotations:annotations];
        }
        // [self.mapView showAnnotations:self.annotations animated:YES];
    }];
}

- (UIButton *)disclosureButton {
    UIButton *button = [[UIButton alloc] init];
    [button setBackgroundImage:[UIImage imageNamed:@"disclosureN.png"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"disclosureH.png"] forState:UIControlStateHighlighted];
    [button sizeToFit];
    return button;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    if ([annotation isKindOfClass:[HeapAnnotation class]]) {
        MKAnnotationView *aView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"heap annotation"];
        if (!aView) {
            aView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"heap annotation"];
            aView.canShowCallout= YES;
            aView.image = [UIImage imageNamed:@"3pins.png"];
            aView.rightCalloutAccessoryView = [self disclosureButton];
        }
        aView.annotation = annotation;
        return aView;
    }
    
    Station *station =(Station *)annotation;
    int pinColor = [station.transportID integerValue] % 3; // 0, 1, 2
    NSString *identifier = [NSString stringWithFormat:@"standart pin #%d", pinColor];
    MKPinAnnotationView *aView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (!aView) {
        aView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        aView.canShowCallout= YES;
        aView.pinColor = pinColor;
        aView.rightCalloutAccessoryView = [self disclosureButton];
    }
    aView.annotation = annotation;
    return aView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(nonnull MKAnnotationView *)view calloutAccessoryControlTapped:(nonnull UIControl *)control
{
    if ([view.annotation isKindOfClass:[HeapAnnotation class]]) {
        HeapAnnotation *ha  = view.annotation;
        self.mapView.region = ha.region;
    }
}

@end
