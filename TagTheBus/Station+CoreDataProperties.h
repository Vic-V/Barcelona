//
//  Station+CoreDataProperties.h
//  TagTheBus
//
//  Created by Victor Vostriakov on 07/10/2016.
//  Copyright © 2016 Victor Vostriakov. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Station.h"
#import "Photo.h"


NS_ASSUME_NONNULL_BEGIN

@interface Station (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *latitude;
@property (nullable, nonatomic, retain) NSNumber *longitude;
@property (nullable, nonatomic, retain) NSString *subtitle;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSNumber *transportID;
@property (nullable, nonatomic, retain) NSNumber *stationID;
@property (nullable, nonatomic, retain) NSSet<Photo *> *photos;

@end

@interface Station (CoreDataGeneratedAccessors)

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet<Photo *> *)values;
- (void)removePhotos:(NSSet<Photo *> *)values;

@end

NS_ASSUME_NONNULL_END
