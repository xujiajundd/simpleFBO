//
//  MainViewController.h
//  simpleFBO
//
//  Created by 徐家骏 on 16/10/17.
//
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface MainViewController : UIViewController

@property (weak, nonatomic) IBOutlet GLKView *glkView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;


@end
