//
//  Point.h
//  OscilloscopePatch
//
//  Created by KIMURA Hiroaki on 06/05/29.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GraphPoint : NSObject {
	
	struct timeval tval;
	//float tval;
	float value;

}

- (id)initWithValue:(float)_value time:(struct timeval)_tval;
- (float)value;
- (struct timeval)timeValue;

@end
