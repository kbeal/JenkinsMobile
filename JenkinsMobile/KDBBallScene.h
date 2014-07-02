//
//  KDBBallScene.h
//  JenkinsMobile
//
//  Created by Kyle on 7/1/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "JenkinsInstance.h"

@interface KDBBallScene : SKScene

@property (strong, nonatomic) NSString *color;
@property (strong, nonatomic) SKSpriteNode *ball;
@property (strong, nonatomic) NSArray *ballFlashingFrames;

-(id)initWithSize:(CGSize)size andColor:(NSString*)color withAnimation:(BOOL)animate;

@end

