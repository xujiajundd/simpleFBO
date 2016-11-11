//
//  MainViewController.m
//  simpleFBO
//
//  Created by 徐家骏 on 16/10/17.
//
//

#import "MainViewController.h"
#import "GLRender.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    GLRender *glRender = [[GLRender alloc] init];
    UIImage *sourceImage = [UIImage imageNamed:@"ziyan.jpg"];
    self.imageView.image = [glRender renderImage:sourceImage];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
