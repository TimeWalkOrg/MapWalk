//
//  KML ConstantWidthPolylineRenderer.m
//  MapWalk
//
//  Created by MyMac on 02/10/23.
//

#import "KMLConstantWidthPolylineRenderer.h"

@implementation KMLConstantWidthPolylineRenderer
- (void)applyStrokePropertiesToContext:(CGContextRef)context atZoomScale:(MKZoomScale)zoomScale {
    [super applyStrokePropertiesToContext:context atZoomScale:zoomScale];
    CGContextSetLineWidth(context, self.lineWidth);
}
@end
