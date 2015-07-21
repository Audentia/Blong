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

@property (nonatomic, strong) UISnapBehavior *snap;
@property (nonatomic, strong) UIView *snapArea;

@property (nonatomic, assign) CGRect snapRect;
@property (nonatomic, assign) CGPoint snapPoint;

@property (nonatomic, strong) UIDynamicItemBehavior *ballDynamicProperties;
@property (nonatomic, strong) UIDynamicItemBehavior *paddleDynamicProperties;

@property (nonatomic, strong) UIView *paddleView;
@property (nonatomic, strong) UIView *ballView;

@property (readwrite, assign) float dx;
@property (readwrite, assign) float dy;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor blackColor];

    [self addSnapArea];
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    self.dx = 0;
    self.dy = 0;

    
    [self startGame];
    

}

- (void)startGame {
    [self createBall];
    [self createPlayerPaddle];
//    [self createAIPaddle];
    [self createCollisions];

}

- (void)createCollisions {
    // Add collisions
    self.collider = [[UICollisionBehavior alloc] initWithItems:@[self.ballView, self.paddleView]];
//    self.collider.collisionDelegate     = self.paddleView;
    [self.animator addBehavior:self.collider];
    self.collider.collisionMode = UICollisionBehaviorModeEverything;
    self.collider.translatesReferenceBoundsIntoBoundary = YES;
}

- (void)createBall {
    CGRect ballRect = CGRectMake(100, 100, 20, 20);
    self.ballView = [[UIView alloc] initWithFrame:ballRect];
    self.ballView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.ballView];
    
    // Remove rotation
    self.ballDynamicProperties = [[UIDynamicItemBehavior alloc] initWithItems:@[self.ballView]];
    self.ballDynamicProperties.allowsRotation = NO;
    [self.animator addBehavior:self.ballDynamicProperties];
    
    // Better Bounce
    self.ballDynamicProperties.elasticity = 1.0;
    self.ballDynamicProperties.friction = 0.0;
    self.ballDynamicProperties.resistance = 0.0;
    
    self.pusher = [[UIPushBehavior alloc] initWithItems:@[self.ballView]
                                                   mode:UIPushBehaviorModeInstantaneous];
    
    self.pusher.pushDirection = CGVectorMake(0.1, 0.1);
    self.pusher.active = YES;
    // Because push is instantaneous, it will only happen once
    [self.animator addBehavior:self.pusher];

}

- (void)createPlayerPaddle {
    CGRect paddleRect = CGRectMake((self.view.frame.size.width / 2), (self.view.frame.size.height - 200), 100, 10);
    self.paddleView = [[UIView alloc] initWithFrame:paddleRect];
    self.paddleView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.paddleView];
    
    // Remove rotation
    self.paddleDynamicProperties = [[UIDynamicItemBehavior alloc] initWithItems:@[self.paddleView]];
    self.paddleDynamicProperties.allowsRotation = NO;
    [self.animator addBehavior:self.paddleDynamicProperties];
    
    //make heavy
    self.paddleDynamicProperties.density = 1000.0f;
    

    
}
- (IBAction)didPanPlayerPaddle:(UIPanGestureRecognizer *)sender {
    self.panGesture = sender;
    [self.paddleView addGestureRecognizer:self.panGesture];

    if ((sender.state == UIGestureRecognizerStateBegan || sender.state ==UIGestureRecognizerStateChanged) && (sender.numberOfTouches == 1)) {
        
        //Remove any previous snap to avoid flicker if both gesture and physics are on the view at same time
        if (self.snap != nil) {
            [self.animator removeBehavior:self.snap];
        }
        CGPoint location = [sender locationInView:self.view];
        
        if (self.dx == 0) {
            self.dx = location.x - self.paddleView.center.x;
        }
        if (self.dy == 0) {
            self.dy = location.y - self.paddleView.center.y;
        }
        
        //apply offsets
        CGPoint newLocation = CGPointMake(location.x - self.dx, location.y - self.dy);
        self.paddleView.center = newLocation;

    } else if (sender.state == UIGestureRecognizerStateEnded) {
        //reset offsets when dragging ends so they will be recalculated correctly
        self.dx = 0;
        self.dy = 0;
        
        [self snapImageIntoPlace:[sender locationInView:self.view]];
    }
}

- (void)addSnapArea {
    self.snapRect = CGRectMake(self.view.center.x - 100, self.view.center.y - 100, 200, 200);
    self.snapPoint = CGPointMake(self.snapRect.size.width / 2, self.snapRect.size.height / 2);
    
    self.snapArea = [[UIView alloc] initWithFrame:self.snapRect];
    self.snapArea.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.snapArea];
}

- (void)snapImageIntoPlace:(CGPoint)touchPoint {
    if (CGRectContainsPoint(self.snapRect, touchPoint)) {
        if (self.snap != nil) {
            [self.animator removeBehavior:self.snap];
        }
        self.snap = [[UISnapBehavior alloc] initWithItem:self.paddleView snapToPoint:self.snapPoint];
        [self.animator addBehavior:self.snap];
    }
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
