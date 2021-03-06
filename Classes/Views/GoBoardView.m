//
//  GoBoardView.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/5/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "GoBoardView.h"
#import "Move.h"
#import <QuartzCore/QuartzCore.h>

#define HANDICAP_MARKER_RADIUS 0.16
#define LAST_MOVE_RADIUS 0.25
#define X_MARKER_RADIUS 0.22
#define STONE_RADIUS 0.52

@interface GoBoardView ()
@property (nonatomic) float pointDistance;
@end

@implementation GoBoardView

- (int)maxX {
	return self.bounds.size.width - _marginX;
}

- (int)maxY {
	return self.bounds.size.height - _marginY;
}

- (int)minX {
	return _marginX;
}

- (int)minY {
	return _marginY;
}

- (CGPoint)pointForBoardRow:(int)row column:(int)col {
	
	float pointDelta = [self pointDistance];
	float pointX = (col - 1) * pointDelta + [self minX];
	float pointY = [self maxY] - ((row - 1) * pointDelta);
	
	// Add 0.5 so we snap to the pixel grid
	return CGPointMake(pointX + 0.5, pointY + 0.5);
}

- (CGPoint)boardPositionForPoint:(CGPoint)point {
	float pointDelta = [self pointDistance];
	float boardX = round((point.x - [self minX]) / pointDelta + 1);
	float boardY = round(([self maxY] - point.y) / pointDelta + 1);
	
	return CGPointMake(boardX, boardY);
}

- (void)drawHandicapMarker:(CGContextRef)context boardSize:(int)boardSize row:(int)row column:(int)column {
	
	CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
	
	CGPoint coords = [self pointForBoardRow:row column:column];
	CGContextBeginPath(context);
	CGContextAddArc(context, coords.x, coords.y, [self pointDistance] * HANDICAP_MARKER_RADIUS, 0, 2*3.14159, 0);
	CGContextFillPath(context);
}

- (void)drawBoardGrid:(CGContextRef)context boardSize:(int)boardSize {
	
	[[UIImage imageNamed:@"Board"] drawInRect:[self bounds]];
	
	CGContextSetLineWidth(context, 1.0);
	
	// draw all the lines on the X axis
	for(int i = 1; i <= boardSize; i++) {
		if (i == 1 || i == boardSize) {
			CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
		} else {
			CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 0.7);
		}
		CGContextBeginPath(context);
		CGPoint startPoint = [self pointForBoardRow:1 column:i];
		CGPoint endPoint = [self pointForBoardRow:boardSize column:i];
		CGContextMoveToPoint(context, startPoint.x, startPoint.y);
		CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
		CGContextStrokePath(context);
	}
	
	// draw all the lines on the Y axis
	for(int i = 1; i <= boardSize; i++) {
		if (i == 1 || i == boardSize) {
			CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
		} else {
			CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 0.7);
		}
		CGContextBeginPath(context);
		CGPoint startPoint = [self pointForBoardRow:i column:1];
		CGPoint endPoint = [self pointForBoardRow:i column:boardSize];
		CGContextMoveToPoint(context, startPoint.x, startPoint.y);
		CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
		CGContextStrokePath(context);
	}
	
	int half = (boardSize + 1) / 2;
	[self drawHandicapMarker:context boardSize:boardSize row:half column:half];
	
	if (9 <= boardSize) {
		if (13 <= boardSize) {
			[self drawHandicapMarker:context boardSize:boardSize row:4 column:4];
			[self drawHandicapMarker:context boardSize:boardSize row:4 column:(boardSize - 3)];
			[self drawHandicapMarker:context boardSize:boardSize row:(boardSize - 3) column:(boardSize - 3)];
			[self drawHandicapMarker:context boardSize:boardSize row:(boardSize - 3) column:4];
			
			if (19 <= boardSize) {
				[self drawHandicapMarker:context boardSize:boardSize row:half column:4];
				[self drawHandicapMarker:context boardSize:boardSize row:half column:(boardSize - 3)];
				[self drawHandicapMarker:context boardSize:boardSize row:4 column:half];
				[self drawHandicapMarker:context boardSize:boardSize row:(boardSize - 3) column:half];
			}
		} else {
			[self drawHandicapMarker:context boardSize:boardSize row:3 column:3];
			[self drawHandicapMarker:context boardSize:boardSize row:3 column:(boardSize - 2)];
			[self drawHandicapMarker:context boardSize:boardSize row:(boardSize - 2) column:(boardSize - 2)];
			[self drawHandicapMarker:context boardSize:boardSize row:(boardSize - 2) column:3];			
		}
	}
}

- (CGLayerRef)newLayerWithImage:(UIImage *)image context:(CGContextRef)context {
    float scale = [self contentScaleFactor];
    CGRect bounds = CGRectMake(0, 0, image.size.width * scale, image.size.height * scale);
    CGLayerRef layer = CGLayerCreateWithContext(context, bounds.size, NULL);
    CGContextRef layerContext = CGLayerGetContext(layer);
    CGContextScaleCTM(layerContext, 1.0, -1.0);
    CGContextTranslateCTM(layerContext, 0.0, -bounds.size.height);
    CGContextDrawImage(layerContext, CGRectMake(0, 0, bounds.size.width, bounds.size.height), image.CGImage);
    return layer;
}

- (void)drawStonesUsingLayer:(CGContextRef)context {
	NSArray *moves = [self.board moves];
	float stoneRadius = [self pointDistance] * STONE_RADIUS;
	UIImage *blackStoneImage = [UIImage imageNamed:@"Black"];
    UIImage *whiteStoneImage = [UIImage imageNamed:@"White"];

    CGLayerRef blackStone = [self newLayerWithImage:blackStoneImage context:context];
    CGLayerRef whiteStone = [self newLayerWithImage:whiteStoneImage context:context];
        
	for (Move *move in moves) {
		if ([move moveType] == kMoveTypeMove) {
            CGPoint coords = [self pointForBoardRow:[move row] column:[move col]];
			
			CGRect stoneRect = CGRectMake(coords.x - stoneRadius, coords.y - stoneRadius, stoneRadius * 2, stoneRadius * 2);

			if ([move player] == kMovePlayerBlack) {
                CGContextDrawLayerInRect(context, stoneRect, blackStone);
			} else {
                CGContextDrawLayerInRect(context, stoneRect, whiteStone);
			}
		}
	}
    
    CGLayerRelease(blackStone);
    CGLayerRelease(whiteStone);
}

- (void)drawLastMoveIndicator:(CGContextRef)context {
	Move *move = [self.board currentMove];
	
	if (!move || ([move moveType] != kMoveTypeMove)) {
		return;
	}
	
	CGContextSetLineWidth(context, 2.0);
	
	if ([move player] == kMovePlayerBlack) {
		CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	} else {
		CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
	}	
	
	CGPoint coords = [self pointForBoardRow:[move row] column:[move col]];
	CGContextBeginPath(context);
	CGContextAddArc(context, coords.x, coords.y, [self pointDistance] * LAST_MOVE_RADIUS, 0, 2*3.14159, 0);
	CGContextStrokePath(context);
}

- (void)drawTerritory:(CGContextRef)context {
	NSArray *territory = [self.board territory];
	CGContextSetLineWidth(context, 2.0);
	
	for (Move *move in territory) {
		if ([move player] == kMovePlayerBlack) {
			CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.3);
		} else if ([move player] == kMovePlayerWhite) {
			CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 0.3);
		} else {
			CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 0.6);
		}
		
		CGPoint coords = [self pointForBoardRow:[move row] column:[move col]];
		CGContextBeginPath(context);
		
		CGContextAddRect(context, CGRectMake(coords.x - [self pointDistance] * 0.5, coords.y - [self pointDistance] * 0.5, [self pointDistance], [self pointDistance]));
		CGContextFillPath(context);
	}
}

- (void)markDeadStones:(CGContextRef)context {
	NSArray *deadStones = [self.board deadStones];
	CGContextSetLineWidth(context, 2.0);
	
	for (Move *move in deadStones) {
		if ([move player] == kMovePlayerBlack) {
			CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
		} else {
			CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
		}	
		
		CGPoint coords = [self pointForBoardRow:[move row] column:[move col]];
		CGContextBeginPath(context);
		CGContextMoveToPoint(context, coords.x - [self pointDistance] * X_MARKER_RADIUS, coords.y - [self pointDistance] * X_MARKER_RADIUS);
		CGContextAddLineToPoint(context, coords.x + [self pointDistance] * X_MARKER_RADIUS, coords.y + [self pointDistance] * X_MARKER_RADIUS);
		CGContextMoveToPoint(context, coords.x + [self pointDistance] * X_MARKER_RADIUS, coords.y - [self pointDistance] * X_MARKER_RADIUS);
		CGContextAddLineToPoint(context, coords.x - [self pointDistance] * X_MARKER_RADIUS, coords.y + [self pointDistance] * X_MARKER_RADIUS);
		CGContextStrokePath(context);
	}
}

- (void)updatePlayerInfo {
	[self.blackName setText:[self.board name:kMovePlayerBlack]];
	[self.whiteName setText:[self.board name:kMovePlayerWhite]];
	
	self.blackCaptures.text = [NSString stringWithFormat:@"+%d", [self.board captures:kMovePlayerBlack]];	
	self.whiteCaptures.text = [NSString stringWithFormat:@"+%d", [self.board captures:kMovePlayerWhite]];	
    [self.delegate showStatusMessage:[self statusMessage]];

}

- (NSString *)generateScoreMessage {
    if (![self.board gameEnded]) {
        return nil;
    }
    
    float score = [self.board score];
    NSString *message;
    
    if (score > 0) {
        message = [NSString stringWithFormat:@"Score: B+%.1f", [self.board score]];
    } else if (score < 0) {
        message = [NSString stringWithFormat:@"Score: W+%.1f", -1.0 * [self.board score]];
    } else {
        message = @"Touch groups to mark them as dead";
    }
    return message;
}

- (NSString *)generatePassMessage {
    NSString *message;
    
    if ([self.board currentMove].moveType == kMoveTypePass) {
        if ([self.board currentMove].player == kMovePlayerBlack) {
            message = @"B Pass";
        } else {
            message = @"W Pass";
        }
    }
    return message;
}

- (NSString *)generateResignMessage {
    NSString *message;
    
    if ([self.board currentMove].moveType == kMoveTypeResign) {
        if ([self.board currentMove].player == kMovePlayerBlack) {
            message = @"B Resign";
        } else {
            message = @"W Resign";
        }
    }
    return message;
}

- (NSString *)statusMessage {
    
    NSString *statusMessage;
    statusMessage = [self generateScoreMessage];
    
    if (!statusMessage) {
        statusMessage = [self generatePassMessage];
    }
    
    if (!statusMessage) {
        statusMessage = [self generateResignMessage];
    }
    
    if (!statusMessage) {
        statusMessage = self.board.comment;
    }
    
    return statusMessage;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSAssert(self.board, @"The board went away.");
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 0.6;
    self.layer.shadowRadius = 9.0;
    CGPathRef shadowPath = CGPathCreateWithRect(self.bounds, NULL);
    self.layer.shadowPath = shadowPath;
    CGPathRelease(shadowPath);
    self.layer.shadowOffset = CGSizeMake(0.0, 4.0);
}

- (void)drawRect:(CGRect)rect {
    // Make sure the board view doesn't go away. This should never happen!
    NSAssert(self.board, @"The board went away.");
    NSAssert(self.blackName, @"Lost the reference to blackName.");
    NSAssert(self.blackCaptures, @"Lost the reference to blackCaptures.");
	// in order to get a nice square board with good margins,
	// we need to make a guess first, then calculate the actual margins based on the
	// point distance we calculate. The reason these are different are due to rounding 
	// errors when we snap the board distance to device pixels.
	_marginX = 50;
	self.pointDistance = 2 * round((float)([self maxX] - [self minX]) / (self.board.size - 1) / 2.0);
	_marginX = (self.bounds.size.width - (self.pointDistance * (self.board.size - 1))) / 2.0;
	_marginY = (self.bounds.size.height - (self.pointDistance * (self.board.size - 1))) / 2.0;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	// Drawing code
	[self drawBoardGrid:context boardSize:[[self board] size]];
    [self drawStonesUsingLayer:context];
    
	if ([self.board gameEnded]) {
		[self markDeadStones:context];
		[self drawTerritory:context];
	} else {
		[self drawLastMoveIndicator:context];
	}
	[self updatePlayerInfo];
}

- (bool)playStoneAtPoint:(CGPoint)point {
	CGPoint boardPoint = [self boardPositionForPoint:point];
	return [self.board playStoneAtRow:(int)boardPoint.y column:(int)boardPoint.x];
}

- (bool)markDeadStonesAtPoint:(CGPoint)point {
	CGPoint boardPoint = [self boardPositionForPoint:point];
	return [self.board markDeadStonesAtRow:(int)boardPoint.y column:(int)boardPoint.x];
}

@end
