//
//  ViewController.m
//  MapView
//
//  Created by ios 4 on 9/22/18.
//  Copyright © farshad jahanmanesh. All rights reserved.
//

#import "ViewController.h"
@import GoogleMaps;
@interface ViewController ()
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (nonatomic,strong) GMSPolyline *highliter;
@property (nonatomic,strong)NSMutableArray *arrayPolyline;
@property (nonatomic,strong)NSMutableArray *arrayPolylineHighliter;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //keep a reference to our points
    self.arrayPolyline = [[NSMutableArray alloc] init];

    //create a highlighter path
    self.highliter = [GMSPolyline new];
    self.highliter.map = self.mapView;
    
    //start and end point  (start location and end location)
    CGFloat startLat = 35.79784789999;
    CGFloat endtLat = 35.4008478;
    CGFloat startLong = 51.43404079999;
    CGFloat endLong =   51.200414;
    
    [self addRouteBetween:CLLocationCoordinate2DMake(startLat, startLong) endLocation:CLLocationCoordinate2DMake(endtLat, endLong)];
}

/**
 Add New route, please take care of animation, this function do not handle multiple route animation, but i can draw multiple line :)

 @param startLocation start point
 @param endLocation end point
 */
-(void)addRouteBetween:(CLLocationCoordinate2D) startLocation endLocation:(CLLocationCoordinate2D) endLocation{
    //create a main path
    GMSMutablePath *path = [GMSMutablePath new];
    // where is our center
    CGFloat centerPointlat = (startLocation.latitude + endLocation.latitude) / 2;
    CGFloat centerPointlong = (startLocation.longitude + endLocation.longitude) / 2;
    
    //add arc to the midPoint
    if(fabs(startLocation.longitude -  endLocation.longitude) > 0.0001){
        centerPointlong -= (startLocation.longitude -  endLocation.longitude)/1.5;
    } else {
        centerPointlat += (startLocation.latitude -  endLocation.latitude)/1.5;
    }
    
    //set two marker for start and end
    dispatch_async(dispatch_get_main_queue(), ^{
        GMSMarker *marker = [GMSMarker markerWithPosition: startLocation];
        marker.icon = [self imageWithImage: [UIImage imageNamed:@"ic_black-check-box"] convertToSize:CGSizeMake(20, 20)];
        marker.map = self.mapView;
        GMSMarker *endmarker = [GMSMarker markerWithPosition:endLocation];
        endmarker.icon = [self imageWithImage: [UIImage imageNamed:@"ic_dot-and-circle"] convertToSize:CGSizeMake(20, 20)];
        endmarker.map = self.mapView;
        
        GMSCoordinateBounds *bound = [[GMSCoordinateBounds alloc] initWithPath:path];
        [bound includingCoordinate:marker.position];
        [bound includingCoordinate:endmarker.position];
        
        //move camera to show our line
        [self.mapView animateWithCameraUpdate:[GMSCameraUpdate fitBounds:bound]];
    });
    
    //we want to draw our line by 100 point, some mathematic to draw points, space between 2 point
    CGFloat tDelta = 1.0/100;
    
    for (double t = 0;  t <= 1.01; t+=tDelta) {
        
        //this is our weight
        CGFloat weight = (1.0-t);
        CGFloat weight1 = pow(t, 2);
        
        //YNew = YStart+Yc+YEnd, we use weight to add points between Start Center And End;
        CGFloat lon = pow(weight,2) * startLocation.longitude
        + 2 * weight * t * centerPointlong
        + weight1 * endLocation.longitude;
        
        //XNew = XStart+Xc+XEnd, we use weight to add points between Start Center And End;
        CGFloat lat = pow(weight,2) * startLocation.latitude
        + 2 * weight * t * centerPointlat
        + weight1 * endLocation.latitude;
        
        //add this point to the path and keep a reference for highlighter
        [self.arrayPolyline addObject:@[ [NSNumber numberWithFloat:lat], [NSNumber numberWithFloat:lon]]];
        [path addCoordinate:CLLocationCoordinate2DMake(lat, lon)];
    }
    
    
    //the line is composite of 100 point, add some style to our line
    GMSPolyline *line = [GMSPolyline polylineWithPath:path];
    line.strokeColor = [UIColor.blackColor colorWithAlphaComponent:0.4];
    line.strokeWidth = 4.0;
    line.map = self.mapView;
    
    //create a loop that animate and highlight our line
    __block int i = 0;
    [NSTimer scheduledTimerWithTimeInterval:0.015 repeats:true block:^(NSTimer * _Nonnull timer) {
        NSInteger count = 20;
        NSInteger skip = i-20;
        if (i < 20){
            skip = 0;
            count = i;
        }
        if(skip+20 >= self.arrayPolyline.count){
            count = self.arrayPolyline.count - skip;
        }
        if (skip == self.arrayPolyline.count) {
            i = 0;
        }
        self.arrayPolylineHighliter = [[self.arrayPolyline subarrayWithRange:NSMakeRange(skip, count)] copy];
        i += 1;
        //draw that path
        [self animatePath];
    }];
}





/**
 draw the animated path
 */
-(void)animatePath {
    GMSMutablePath *path = [GMSMutablePath new];
    for (NSArray *point in self.arrayPolylineHighliter) {
        [path addCoordinate:CLLocationCoordinate2DMake( [point[0] floatValue], [point[1] floatValue])];
    }
    self.highliter.strokeColor = UIColor.blackColor ;
    self.highliter.strokeWidth = 4.0;
    self.highliter.path = path;
}

/**
 resize our marker images
 
 @param image the image
 @param size new size
 @return resized image
 */
- (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}
@end
