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

@property (nonatomic, strong) UIAttachmentBehavior *attach;
@property (nonatomic, strong) UISnapBehavior *snap;

@property (readwrite, assign) float dxPlayer;
@property (readwrite, assign) float dxAI;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    basic setup for any game
    self.view.backgroundColor = [UIColor blackColor];
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
//    methods to start specific games
    [self startGame];
}

- (void)startGame {
    [self createBall];
    [self createPlayerPaddle];
    [self createAIPaddle];
    [self createCollisions];
    
    // Remove rotation
    self.paddleDynamicProperties = [[UIDynamicItemBehavior alloc] initWithItems:@[self.paddleView, self.paddleViewAI]];
    self.paddleDynamicProperties.allowsRotation = NO;
    
    //make heavy
    self.paddleDynamicProperties.density = 1000.0f;
    
    //make slow
    self.paddleDynamicProperties.friction = 1000;
    
    [self.animator addBehavior:self.paddleDynamicProperties];
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
    CGRect ballRect = CGRectMake(self.view.center.x, self.view.center.y, 20, 20);
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
    CGRect paddleRect = CGRectMake((self.view.frame.size.width / 2), (self.view.frame.size.height - 30), 100, 10);
    self.paddleView = [[UIView alloc] initWithFrame:paddleRect];
    self.paddleView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.paddleView];
    
    
    
    //allow user to move
    self.dxPlayer = 0;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(movePaddle:)];
    [panGesture setMinimumNumberOfTouches:1];
    [panGesture setMaximumNumberOfTouches:1];
    [self.view addGestureRecognizer:panGesture];
}

- (void)createAIPaddle {
    CGRect paddleRect = CGRectMake((self.view.frame.size.width / 2), 30, 100, 10);
    self.paddleViewAI = [[UIView alloc] initWithFrame:paddleRect];
    self.paddleViewAI.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.paddleViewAI];
    
    //make AI work
    //track location of ball
    [self addObserver:self forKeyPath:@"self.ballView.center" options:NSKeyValueObservingOptionNew context:nil];
}

-(void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *,id> *)change context:(nullable void *)context {
    if ([keyPath isEqualToString:@"self.ballView.center"]) {
        
        if (!CGRectContainsRect(self.view.frame, self.ballView.frame)) {
            [self createBall];
            [self createCollisions];
        }
        
        CGPoint location = self.ballView.center;
        
        //paddle respond to location of ball
        
        if (self.dxAI == 0) {
            self.dxAI = location.x - self.paddleViewAI.center.x;
        }
        //create offsets
        CGPoint newLocation = CGPointMake(location.x - self.dxAI, self.paddleViewAI.center.y);
        CGRect newRect = CGRectMake(newLocation.x - (self.paddleViewAI.frame.size.width / 2), self.paddleViewAI.frame.origin.y, self.paddleViewAI.frame.size.width, self.paddleViewAI.frame.size.height);
        
        
        //keep paddle inside view
        if (CGRectContainsRect(self.view.frame, newRect)) {
            //apply offsets
            
            if (self.attach != nil) {
                [self.animator removeBehavior:self.attach];
            }
            self.attach = [[UIAttachmentBehavior alloc] initWithItem:self.paddleViewAI attachedToAnchor:self.paddleViewAI.center];
            self.attach.frequency = 10;
            self.attach.damping = 1;
            [self.attach setAnchorPoint:newLocation];
            [self.animator addBehavior:self.attach];

        }
        //update animations
        [self.animator updateItemUsingCurrentState:self.paddleViewAI];
    }
}

- (void)movePaddle:(UIPanGestureRecognizer *)sender {
    if ((sender.state == UIGestureRecognizerStateBegan || sender.state ==UIGestureRecognizerStateChanged) && (sender.numberOfTouches == 1)) {
        
        CGPoint location = [sender locationInView:self.view];
        
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


    } else if (sender.state == UIGestureRecognizerStateEnded) {
        //reset offsets when dragging ends so they will be recalculated correctly
        self.dxPlayer = 0;
    }
}

@end