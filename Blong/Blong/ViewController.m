//
//  ViewController.m
//  Blong
//
//  Created by Douglas Hewitt on 7/13/15.
//  Copyright © 2015 Bloc. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UIPushBehavior *pusher;
@property (nonatomic, strong) UICollisionBehavior *collider;

@property (nonatomic, strong) UIDynamicItemBehavior *ballDynamicProperties;
@property (nonatomic, strong) UIDynamicItemBehavior *paddleDynamicProperties;

@property (nonatomic, strong) UIView *paddleView;
@property (nonatomic, strong) UIView *paddleViewAI;
@property (nonatomic, strong) UIView *ballView;
@property (nonatomic, assign) CGPoint ballPosition;

@property (nonatomic, strong) UIPushBehavior *pushAI;

@property (readwrite, assign) BOOL slingshotMode;
@property (nonatomic, strong) UIAttachmentBehavior *attachSlingshot;
@property (nonatomic, strong) UIPushBehavior *pushSlingshot;
@property (nonatomic, assign) CGPoint anchorSlingshot;
@property (nonatomic, assign) float dxFromAnchor;
@property (nonatomic, assign) float dyFromAnchor;
@property (nonatomic, assign) CGVector vectorFromAnchor;
@property (nonatomic, assign) CGRect slingshotZone;

@property (readwrite, assign) float dxPlayer;
@property (readwrite, assign) float dxAI;

@property (readwrite, assign) float difficultyResistance;
@property (readwrite, assign) float difficultyMagnitude;
@property (readwrite, strong) UIAlertController *difficultyMenu;

@property (readwrite, assign) int scorePlayer;
@property (readwrite, assign) int scoreAI;
@property (readwrite, strong) UILabel *scoreLabelPlayer;
@property (readwrite, strong) UILabel *scoreLabelAI;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    basic setup for any game
    self.view.backgroundColor = [UIColor blackColor];
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.slingshotZone = CGRectMake((self.view.frame.size.width / 2) - 100, (self.view.frame.size.height / 2) - 100, 200, 200);
//    methods to start specific games
    [self startGame];
}

- (void)viewDidAppear:(BOOL)animated {
    [self setDifficulty];
}

- (void)startGame {
    [self createAIPaddle];
    [self createPlayerPaddle];
    
    UIPanGestureRecognizer *panGestureSlingshot = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [panGestureSlingshot setMinimumNumberOfTouches:1];
    [panGestureSlingshot setMaximumNumberOfTouches:1];
    [self.view addGestureRecognizer:panGestureSlingshot];
    
    // Remove rotation
    self.paddleDynamicProperties = [[UIDynamicItemBehavior alloc] initWithItems:@[self.paddleView, self.paddleViewAI]];
    self.paddleDynamicProperties.allowsRotation = NO;
    
    //make heavy
    self.paddleDynamicProperties.density = 1000.0f;
    
    //make slow
    self.paddleDynamicProperties.resistance = self.difficultyResistance;
    
    [self.animator addBehavior:self.paddleDynamicProperties];
    
    //score labels
    self.scoreLabelPlayer = [[UILabel alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2)-50, self.view.frame.size.height - 200, 100, 100)];
    self.scoreLabelPlayer.text = @"0";
    self.scoreLabelPlayer.backgroundColor = [UIColor clearColor];
    self.scoreLabelPlayer.textAlignment = NSTextAlignmentCenter;
    self.scoreLabelPlayer.textColor = [UIColor whiteColor];
    
    self.scoreLabelAI = [[UILabel alloc] initWithFrame:CGRectMake((self.view.frame.size.width / 2)-50, 150, 100, 100)];
    self.scoreLabelAI.text = @"0";
    self.scoreLabelAI.backgroundColor = [UIColor clearColor];
    self.scoreLabelAI.textAlignment = NSTextAlignmentCenter;
    self.scoreLabelAI.textColor = [UIColor whiteColor];
    
    [self.view addSubview:self.scoreLabelPlayer];
    [self.view addSubview:self.scoreLabelAI];
}

- (void)slingshot {
    self.slingshotMode = YES;
   
    
    self.anchorSlingshot = self.view.center;
//    self.attachSlingshot = [[UIAttachmentBehavior alloc] initWithItem:self.ballView attachedToAnchor:self.anchorSlingshot];
//    [self.animator addBehavior:self.attachSlingshot];
}

- (void)panGesture:(UIPanGestureRecognizer *)sender {
    if ((sender.state == UIGestureRecognizerStateBegan || sender.state ==UIGestureRecognizerStateChanged) && (sender.numberOfTouches == 1)) {
        
        CGPoint location = [sender locationInView:self.view];
        
        if (!self.slingshotMode) {

        
            if (self.dxPlayer == 0) {
                self.dxPlayer = location.x - self.paddleView.center.x;
            }
            
            //create offsets
            CGPoint newLocation = CGPointMake(location.x - self.dxPlayer, self.paddleView.center.y);
            CGRect newRect = CGRectMake(newLocation.x - (self.paddleView.frame.size.width / 2), self.paddleView.frame.origin.y, self.paddleView.frame.size.width, self.paddleView.frame.size.height);
            
            //keep paddle inside view
            if (CGRectContainsRect(self.view.frame, newRect)) {
                //apply offsets
                self.paddleView.center = newLocation;
            }
            //update animations
            [self.animator updateItemUsingCurrentState:self.paddleView];
        }
        if (self.slingshotMode) {
            if (CGRectContainsRect(self.slingshotZone, self.ballView.frame)) {
                self.ballView.center = location;
                
            } else {
                float dx = 0.0;
                float dy = 0.0;
                float halfOfViewX = self.view.frame.size.width / 2;
                float halfOfViewY = self.view.frame.size.height / 2;
                float halfOfZoneX = self.slingshotZone.size.width / 2;
                float halfOfZoneY = self.slingshotZone.size.height / 2;
                
                if (location.x <= halfOfViewX - halfOfZoneX) {
                    dx = -(halfOfViewX - halfOfZoneX - location.x);
                }
                if (location.x >= halfOfViewX + halfOfZoneX) {
                    dx = location.x - halfOfViewX - halfOfZoneX;
                }
                
                if (location.y <= halfOfViewY - halfOfZoneY) {
                    dy = -(halfOfViewY - halfOfZoneY - location.y);
                }
                if (location.y >= halfOfViewY + halfOfZoneY) {
                    dy = location.y - halfOfViewY - halfOfZoneY;
                }
                
                NSLog(@"dx is %f dy is %f", dx, dy);
                
                self.ballView.center = CGPointMake(location.x - dx, location.y - dy);
            }
            self.dxFromAnchor = self.anchorSlingshot.x - self.ballView.center.x;
            self.dyFromAnchor = self.anchorSlingshot.y - self.ballView.center.y;
            self.vectorFromAnchor = CGVectorMake(self.dxFromAnchor / 500, self.dyFromAnchor / 500);
            
            [self.animator updateItemUsingCurrentState:self.ballView];
        }
    }
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (!self.slingshotMode) {
            //reset offsets when dragging ends so they will be recalculated correctly
            self.dxPlayer = 0;
        }
        if (self.slingshotMode) {
            if (self.pushSlingshot != nil) {
                [self.animator removeBehavior:self.pushSlingshot];
            }
//            [self.animator removeBehavior:self.attachSlingshot];
            self.pushSlingshot = [[UIPushBehavior alloc] initWithItems:@[self.ballView] mode:UIPushBehaviorModeInstantaneous];
            [self.pushSlingshot setPushDirection:self.vectorFromAnchor];
            [self.animator addBehavior:self.pushSlingshot];
            [self.animator updateItemUsingCurrentState:self.ballView];
            
            //make sure vector resets
            self.dxFromAnchor = 0;
            self.dyFromAnchor = 0;
            self.vectorFromAnchor = CGVectorMake(0, 0);
            self.slingshotMode = NO;
        }
    }
}


- (void)setDifficulty {
    self.difficultyMenu = [UIAlertController alertControllerWithTitle:@"Difficulty Settings" message:@"Choose a Difficulty" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *easy = [UIAlertAction actionWithTitle:@"Easy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * __nonnull action) {
        self.difficultyMagnitude = 5;
        self.difficultyResistance = .5;
        [self dismissViewControllerAnimated:YES completion:nil];
        [self createBall];
        [self sendBall];

    }];
    UIAlertAction *medium = [UIAlertAction actionWithTitle:@"Medium" style:UIAlertActionStyleDefault handler:^(UIAlertAction * __nonnull action) {
        self.difficultyMagnitude = 7;
        self.difficultyResistance = .5;
        [self.difficultyMenu dismissViewControllerAnimated:YES completion:nil];
        [self createBall];
        [self sendBall];
    }];
    
    [self.difficultyMenu addAction:easy];
    [self.difficultyMenu addAction:medium];
    self.difficultyMenu.view.backgroundColor = [UIColor whiteColor];
    [self presentViewController:self.difficultyMenu animated:YES completion:nil];
}

- (void)createCollisions {
    self.collider = [[UICollisionBehavior alloc] initWithItems:@[self.ballView, self.paddleView, self.paddleViewAI]];
//    self.collider.collisionDelegate = self.paddleView;
    self.collider.collisionMode = UICollisionBehaviorModeEverything;
    [self.collider addBoundaryWithIdentifier:@"left" fromPoint:CGPointMake(0, 0) toPoint:CGPointMake(0, self.view.frame.size.height)];
    [self.collider addBoundaryWithIdentifier:@"right" fromPoint:CGPointMake(self.view.frame.size.width, 0) toPoint:CGPointMake(self.view.frame.size.width, self.view.frame.size.height)];
    [self.animator addBehavior:self.collider];
}

- (void)createBall {
    CGRect ballRect = CGRectMake(self.view.center.x - 10, self.view.center.y - 10, 20, 20);
    self.ballView = [[UIView alloc] initWithFrame:ballRect];
    self.ballView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.ballView];
    
//    Remove rotation
    self.ballDynamicProperties = [[UIDynamicItemBehavior alloc] initWithItems:@[self.ballView]];
    self.ballDynamicProperties.allowsRotation = NO;
    [self.animator addBehavior:self.ballDynamicProperties];
    
//    Proper bounce that won't gain energy
    self.ballDynamicProperties.elasticity = 1.0;
    self.ballDynamicProperties.friction = 0.0;
    self.ballDynamicProperties.resistance = 0.0;
    
    [self createCollisions];
}

- (void)sendBall {
    //    Start the ball
    self.pusher = [[UIPushBehavior alloc] initWithItems:@[self.ballView]
                                                   mode:UIPushBehaviorModeInstantaneous];
    int uniqueStartInt = arc4random_uniform(4);
    //    want to make random numbers so long as the sum equals the same magnitude in the equation v = sqr(x^2 + y^2)
    switch (uniqueStartInt) {
        case 0:
            self.pusher.pushDirection = CGVectorMake(0.1, 0.1);
            break;
        case 1:
            self.pusher.pushDirection = CGVectorMake(0.2, 0.05);
            break;
        case 2:
            self.pusher.pushDirection = CGVectorMake(0.05, 0.2);
            break;
        case 3:
            self.pusher.pushDirection = CGVectorMake(-0.1, -0.1);
            break;
            
        default:
            break;
    }
    
    self.pusher.active = YES;
    //    Because push is instantaneous, it will only happen once
    [self.animator addBehavior:self.pusher];
}

- (void)createPlayerPaddle {
    CGRect paddleRect = CGRectMake((self.view.frame.size.width / 2) - 50, (self.view.frame.size.height - 30), 100, 10);
    self.paddleView = [[UIView alloc] initWithFrame:paddleRect];
    self.paddleView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.paddleView];
    
    
    
    //allow user to move
    self.dxPlayer = 0;
}

- (void)createAIPaddle {
    CGRect paddleRect = CGRectMake((self.view.frame.size.width / 2) - 50, 30, 100, 10);
    self.paddleViewAI = [[UIView alloc] initWithFrame:paddleRect];
    self.paddleViewAI.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.paddleViewAI];
    
    //make AI work
    //track location of ball
    [self addObserver:self forKeyPath:@"self.ballView.center" options:NSKeyValueObservingOptionNew context:nil];
}

-(void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *,id> *)change context:(nullable void *)context {
    if ([keyPath isEqualToString:@"self.ballView.center"]) {
        
        
        //track score
        if (self.ballView.center.y < self.paddleViewAI.center.y) {
            [self removeObserver:self forKeyPath:@"self.ballView.center"];
            self.scorePlayer++;
            NSString *scorePlayerString = [NSString stringWithFormat:@"%d", self.scorePlayer];
            self.scoreLabelPlayer.text = scorePlayerString;
            [self createBall];
            [self sendBall];
            [self addObserver:self forKeyPath:@"self.ballView.center" options:NSKeyValueObservingOptionNew context:nil];
        }
        
        if (self.ballView.center.y > self.paddleView.center.y) {
            [self removeObserver:self forKeyPath:@"self.ballView.center"];
            self.scoreAI++;
            NSString *scoreAIString = [NSString stringWithFormat:@"%d", self.scoreAI];
            self.scoreLabelAI.text = scoreAIString;
            [self createBall];
            [self slingshot];
            [self addObserver:self forKeyPath:@"self.ballView.center" options:NSKeyValueObservingOptionNew context:nil];

       }
        
        CGPoint location = self.ballView.center;
        
        //paddle respond to location of ball
        
        if (self.dxAI == 0) {
            self.dxAI = location.x - self.paddleViewAI.center.x;
        }
        //create offsets
        CGPoint newLocation = CGPointMake(location.x - self.dxAI, self.paddleViewAI.center.y);
        CGRect newRect = CGRectMake(newLocation.x - (self.paddleViewAI.frame.size.width / 2), self.paddleViewAI.frame.origin.y, self.paddleViewAI.frame.size.width, self.paddleViewAI.frame.size.height);
        
        if (self.pushAI != nil) {
            [self.animator removeBehavior:self.pushAI];
        }
        //keep paddle inside view
        if (CGRectContainsRect(self.view.frame, newRect)) {
            //apply offsets
            self.pushAI = [[UIPushBehavior alloc] initWithItems:@[self.paddleViewAI] mode:UIPushBehaviorModeInstantaneous];
            if (self.paddleViewAI.center.x < self.ballView.center.x) {
                [self.pushAI setAngle:0 magnitude:self.difficultyMagnitude];
                [self.animator addBehavior:self.pushAI];
            }
            if (self.paddleViewAI.center.x > self.ballView.center.x) {
                [self.pushAI setAngle:M_PI magnitude:self.difficultyMagnitude];
                [self.animator addBehavior:self.pushAI];
            }

        }
        //update animations
        [self.animator updateItemUsingCurrentState:self.paddleViewAI];
    }
}



@end