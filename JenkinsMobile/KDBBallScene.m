//
//  KDBBallScene.m
//  JenkinsMobile
//
//  Created by Kyle on 7/1/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "KDBBallScene.h"

@implementation KDBBallScene
    

-(id)initWithSize:(CGSize)size andColor:(NSString*)color withAnimation:(BOOL)animate
{
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        self.color=color;
        
        self.backgroundColor = [SKColor whiteColor];
        
        NSMutableArray *flashFrames = [NSMutableArray array];
        SKTextureAtlas *ballAnimatedAtlas = [SKTextureAtlas atlasNamed:@"balls"];
        
        for (int i=1; i<=8; i++) {
            NSString *textureName = [NSString stringWithFormat:@"%@%d",self.color, i];
            SKTexture *temp = [ballAnimatedAtlas textureNamed:textureName];
            [flashFrames addObject:temp];
        }
        _ballFlashingFrames = flashFrames;
        
        SKTexture *temp = _ballFlashingFrames[0];
        _ball = [SKSpriteNode spriteNodeWithTexture:temp];
        _ball.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        [self addChild:_ball];
        
        if (animate) { [self flashingBall]; }
        
    }
    return self;
}

-(id)initWithSize:(CGSize)size
{
    return [self initWithSize:size andColor:@"blue" withAnimation:NO];
}

-(void)flashingBall
{
    //This is our general runAction method to make our bear walk.
    [_ball runAction:[SKAction repeatActionForever:
                      [SKAction animateWithTextures:_ballFlashingFrames
                                       timePerFrame:0.2f
                                             resize:NO
                                            restore:YES]] withKey:@"flashingBall"];
    return;
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
