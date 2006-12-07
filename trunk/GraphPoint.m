//
//  GraphPoint.m
//  OscilloscopePatch
//
//  Created by KIMURA Hiroaki on 06/05/29.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "GraphPoint.h"


@implementation GraphPoint

- (id)initWithValue:(float)_value time:(struct timeval)_tval{
	value = _value;
	tval = _tval;
	
	return self;
}
- (float) value {
	return value;
}
- (struct timeval)timeValue{
	return tval;
}


@end
