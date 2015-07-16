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
@property (nonatomic) UIAttachmentBehavior *attachmentBehavior;

@property (nonatomic, assign) CGRect originalBounds;
@property (nonatomic, assign) CGPoint originalCenter;

@property (nonatomic, strong) UIDynamicItemBehavior *ballDynamicProperties;
@property (nonatomic, strong) UIDynamicItemBehavior *paddleDynamicProperties;

@property (nonatomic, strong) UIView *paddleView;
@property (nonatomic, strong) UIView *ballView;


@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.view.backgroundColor = [UIColor blackColor];
    
    self.originalBounds = self.paddleView.bounds;
    self.originalCenter = self.paddleView.center;

    
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
    
    //let user move
  

    
}

- (IBAction) handleAttachmentGesture:(UIPanGestureRecognizer*)gesture
{
    CGPoint location = [gesture locationInView:self.view];
    CGPoint boxLocation = [gesture locationInView:self.paddleView];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:{
            NSLog(@"you touch started position %@",NSStringFromCGPoint(location));
            NSLog(@"location in paddle started is %@",NSStringFromCGPoint(boxLocation));
            
            // 1
//            [self.animator removeAllBehaviors];
            
            // 2
            UIOffset centerOffset = UIOffsetMake(boxLocation.x - CGRectGetMidX(self.paddleView.bounds),
                                                 boxLocation.y - CGRectGetMidY(self.paddleView.bounds));
            self.attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.paddleView
                                                                offsetFromCenter:centerOffset
                                                                attachedToAnchor:location];
            // 3
            self.paddleView.center = self.attachmentBehavior.anchorPoint;
//            self.blueSquare.center = location;
            
            // 4
            [self.animator addBehavior:self.attachmentBehavior];
            

            
            break;
        }
        case UIGestureRecognizerStateEnded: {
            NSLog(@"you touch ended position %@",NSStringFromCGPoint(location));
            NSLog(@"location in paddle ended is %@",NSStringFromCGPoint(boxLocation));
            
            break;
        }
        default: {
            [self.attachmentBehavior setAnchorPoint:[gesture locationInView:self.view]];
            self.paddleView.center = self.attachmentBehavior.anchorPoint;
            [self.animator updateItemUsingCurrentState:self.paddleView];

        }
            break;
    }
}

- (void)resetDemo
{
    [self.animator removeAllBehaviors];
    
    [UIView animateWithDuration:0.45 animations:^{
        self.paddleView.bounds = self.originalBounds;
        self.paddleView.center = self.originalCenter;
        self.paddleView.transform = CGAffineTransformIdentity;
    }];
}

//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    
//    UITouch *touch = [touches anyObject];
//    
//    // If the touch was in the placardView, move the placardView to its location
//    if ([touch view] == self.paddleView) {
//        CGPoint location = [touch locationInView:self.view];
//        self.paddleView.center = location;
//    }
//}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
