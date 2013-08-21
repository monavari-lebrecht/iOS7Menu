/**
* The MIT License (MIT)
*
* Copyright (c) <2013> <Constantin Lebrecht, constantin@monavari.de>
* Created by Constantin Lebrecht on 06/27/13.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

#import "ISMViewController.h"
#import "UIWindow+Screenshot.h"

@interface ISMViewController () {
    UIImageView     *_screenshotOfCurrentView;
    CGFloat         _screenshotTransitionStartX;
    UIImageView *   _fancyBackground;
    UITableView     *_menuView;
    BOOL            _menuIsOpen;
}
@end

typedef struct Transition {
    CGFloat x;
    CGFloat y;
    CGFloat factor;
} Transition;

static const int SENSITIVE_AREA_FOR_OPENING_MENU = 40;

@implementation ISMViewController

- (void)viewDidAppear:(BOOL)animated {
    // hide tab bar
    self.tabBar.hidden = YES;
    [self switchToViewController:0];

    // add gesture handlers to open menu
    [self addGestureRecognizerForOpeningMenu];

    [super viewDidAppear:animated];
}

- (void)initMenuViews {
    /*  menu views */
    UIWindow *window = [self getWindow];

    if (!_fancyBackground) {
        // add fancy background view
        _fancyBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fancyBackground.png"]];
        CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;

        _fancyBackground.frame = CGRectMake(
                0,
                statusBarHeight,
                window.frame.size.width,
                window.frame.size.height - statusBarHeight);
    }

    // make screenshot of current view
    if (!_screenshotOfCurrentView) {
        _screenshotOfCurrentView = [[UIImageView alloc] initWithFrame:CGRectNull];
        
        _screenshotOfCurrentView.frame = CGRectMake(
                        0,
                        0,
                        window.frame.size.width,
                        window.frame.size.height);
    }

    _screenshotOfCurrentView.image = [window screenshot:NO];

    // add table view as menu
    // instantiate menu
    if (!_menuView){
        _menuView = [[UITableView alloc] init];
        _menuView.delegate = self;
        _menuView.dataSource = self;
        _menuView.backgroundColor = [UIColor clearColor];
        _menuView.separatorStyle = UITableViewCellSeparatorStyleNone;

        CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        _menuView.frame = CGRectMake(
                MENU_OFFSET_X,
                statusBarHeight + MENU_OFFSET_Y,
                window.frame.size.width - (window.frame.size.width - TRANSITION_END_VALUE_X),
                window.frame.size.height - statusBarHeight - MENU_OFFSET_Y
        );
    }
}

- (UIWindow *)getWindow {
    return [[[UIApplication sharedApplication] delegate] window];
}

#pragma mark -
#pragma mark Opening/Closing Menu

- (void)addGestureRecognizerForOpeningMenu {
    UIWindow *window = [self getWindow];

    // add gesture recognizer
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    recognizer.delegate = self;
    [window.rootViewController.view addGestureRecognizer:recognizer];
}

- (void)addGestureRecognizerForClosingMenu {
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    recognizer.delegate = self;
    [_screenshotOfCurrentView addGestureRecognizer:recognizer];
}

- (Transition)calculateTransitionForX:(CGFloat)xValue{
    UIWindow *window = [self getWindow];

    // add helper vars for window size
    CGFloat windowWidth = window.frame.size.width;
    CGFloat windowHeight = window.frame.size.height;

    Transition transition;

    transition.x =  xValue;
    transition.factor = 1 - ((transition.x / windowWidth) * 210/ windowWidth);
    transition.y = (windowHeight - windowHeight * transition.factor) / 2.0;

    return transition;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    // get application window
    UIWindow *window = [self getWindow];

    // calculate x and y coordinates for transition on gesture point
    CGPoint translationInView = [recognizer translationInView:window];

    // handle gesture recognizer states
    switch (recognizer.state) {
        // begin
        case UIGestureRecognizerStateBegan: {
            if (!_menuIsOpen){
                [self initMenuViews];

                [window addSubview:_fancyBackground];

                // add menu as subview
                [window addSubview:_menuView];

                // add screenshot to view as placeholder
                [window addSubview:_screenshotOfCurrentView];
            }
            _screenshotTransitionStartX = _screenshotOfCurrentView.frame.origin.x;
        }   break;
            // change
        case UIGestureRecognizerStateChanged: {
            Transition transition = [self calculateTransitionForX:_screenshotTransitionStartX + translationInView.x];

            _screenshotOfCurrentView.frame = CGRectMake(
                    transition.x,
                    transition.y,
                    window.frame.size.width * transition.factor,
                    window.frame.size.height * transition.factor);
        }   break;
            // end
        case UIGestureRecognizerStateEnded: {

            if (translationInView.x > window.frame.size.width/2 - 50) {
                [self openMenu:YES];
            } else {
                [self openMenu:NO];
            }

        }   break;
        default:break;
    }
}

/** open menu with a transition or close it by animating screenshot to fullscreen and remove it */
- (void)openMenu:(BOOL)open {
    UIWindow *window = [self getWindow];

    // default transition is to move the view back to 0 for (fullscreen)
    Transition transition = [self calculateTransitionForX:0];

    // calculate transition if menu shall be enabled
    if (open) {
        transition = [self calculateTransitionForX:TRANSITION_END_VALUE_X];
    } else {
        [self addGestureRecognizerForOpeningMenu];
    }

    [UIView animateWithDuration:0.3f animations:^{
        _screenshotOfCurrentView.frame = CGRectMake(
                transition.x,
                transition.y,
                window.frame.size.width * transition.factor,
                window.frame.size.height * transition.factor
        );
    } completion:^(BOOL finished){
        // if view has moved to 0 and menu is closed, remove screenshot
        if (transition.x == 0) {
            // if disabled enable selection on menu again
            _menuView.allowsSelection = YES;

            [window bringSubviewToFront:window.rootViewController.view];
            _menuIsOpen = NO;
        }
        // otherwise make screenshoot gesture enabled for closing
        else {
            [self addGestureRecognizerForClosingMenu];
            _menuIsOpen = YES;
        }
    }];
}

- (void)switchToViewController:(NSUInteger)viewControllerIndex {
    UIWindow *window = [self getWindow];

    // set new root view controller using api
    self.selectedIndex = viewControllerIndex;
    
    // move 'old' screenshot out of view...
    Transition transition = [self calculateTransitionForX:TRANSITION_END_VALUE_X];

    [UIView animateWithDuration:0.2f delay:0 options:(UIViewAnimationOptions) UIViewAnimationCurveEaseOut animations:^{
        _screenshotOfCurrentView.frame = CGRectMake(
                window.frame.size.width + 1,
                transition.y,
                window.frame.size.width * transition.factor,
                window.frame.size.height * transition.factor
        );
    }                completion:^(BOOL finishedFirstAnimation) {
        // make it full screen and take a beautiful screen shot
        CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        CGFloat tabBarHeight = self.tabBar.frame.size.height;
        window.rootViewController.view.frame = CGRectMake(
                0,
                statusBarHeight,
                window.frame.size.width,
                window.frame.size.height + tabBarHeight - statusBarHeight);

        [window bringSubviewToFront:window.rootViewController.view];
        _screenshotOfCurrentView.image = [window screenshot:NO];

        [window bringSubviewToFront:_fancyBackground];
        [window bringSubviewToFront:_menuView];
        [window bringSubviewToFront:_screenshotOfCurrentView];

        // move view back in
        [UIView animateWithDuration:0.2f delay:0 options:(UIViewAnimationOptions) UIViewAnimationCurveEaseOut animations:^{
            _screenshotOfCurrentView.frame = CGRectMake(
                    transition.x,
                    transition.y,
                    window.frame.size.width * transition.factor,
                    window.frame.size.height * transition.factor
            );
        }                completion:^(BOOL finishedSecondAnimation) {
            double delayInSeconds = 0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                //code to be executed on the main queue after delay
                // close menu
                [self openMenu:NO];
            });
        }];
    }];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // count of connected view controllers
    return self.viewControllers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // iterate over all connected view controllers
    UITableViewCell *menuCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                       reuseIdentifier:@"menuCell"];
    menuCell.selectionStyle = UITableViewCellSelectionStyleNone;

    menuCell.textLabel.text = [[[self.viewControllers objectAtIndex:(NSUInteger)indexPath.row] tabBarItem] title];
    menuCell.textLabel.textColor = [UIColor whiteColor];
    
    menuCell.backgroundColor = [UIColor clearColor];

    return menuCell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // disable table for additional input
    tableView.allowsSelection = NO;

    // make new viewcontroller active
    [self switchToViewController:(NSUInteger)indexPath.row];
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    UIWindow *window = [self getWindow];

    // if menu is closed, check if pan comes from the border
    if ((!_menuIsOpen) && ([gestureRecognizer locationInView:window].x > SENSITIVE_AREA_FOR_OPENING_MENU)) {
        return NO;
    }

    return YES;
}

@end