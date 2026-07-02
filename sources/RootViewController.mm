#import "RootViewController.h"
#import <WebKit/WebKit.h>
#include "ENCRYPT/xorstr.hpp"

@interface RootViewController () <WKNavigationDelegate, WKUIDelegate>
@property (nonatomic, strong) WKWebView *webView;
// เพิ่ม Property สำหรับจัดการ Loading View ตามที่ต้องการ
@property (nonatomic, strong) UIView *loadingContainerView; 
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@end

@implementation RootViewController

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait; 
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    if (self.navigationController) {
        self.navigationController.navigationBarHidden = YES;
    }

    [self setupWebKitView];
    [self setupLoadingView]; // เรียกฟังก์ชันสร้าง Loading UI ที่เพิ่มเข้ามา
}

- (void)setupWebKitView {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = YES;
    
    [config.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
    [config setValue:@YES forKey:@"allowUniversalAccessFromFileURLs"];
    
    if (@available(iOS 13.0, *)) {
        config.defaultWebpagePreferences.allowsContentJavaScript = YES; 
    }
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    self.webView.backgroundColor = [UIColor blackColor];
    self.webView.opaque = NO;
    
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];
    
    NSString *targetURL  = [NSString stringWithUTF8String:xorstr_("https://kuyk15820-cpu.github.io/Upload/")];
    NSString *htmlName  = [NSString stringWithUTF8String:xorstr_("0")]; 

    if ([htmlName isEqualToString:@"0"]) {

        NSURL *url = [NSURL URLWithString:targetURL];
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
        [self.webView loadRequest:request];
        NSLog(@"[WebKit] กำลังโหลดโหมด: ลิงก์ URL ออนไลน์");
        
    } else if ([targetURL isEqualToString:@"0"]) {

        NSString *htmlPath = [[NSBundle mainBundle] pathForResource:htmlName ofType:@"html"];
        if (htmlPath) {
            NSURL *fileURL = [NSURL fileURLWithPath:htmlPath];

            NSURL *readAccessURL = [fileURL URLByDeletingLastPathComponent];
            [self.webView loadFileURL:fileURL allowingReadAccessToURL:readAccessURL];
            NSLog(@"[WebKit] กำลังโหลดโหมด: Local HTML (%@.html + JS)", htmlName);
        } else {
            NSLog(@"[WebKit Error] ไม่พบไฟล์ %@.html ในโฟลเดอร์แอป", htmlName);
        }
    }
}

// ฟังก์ชันสร้าง UI สำหรับหน้าต่าง Loading (สไตล์ App Store HUD)
- (void)setupLoadingView {
    // สร้างกล่องสี่เหลี่ยมสีเทาดำโปร่งแสง มุมมน
    self.loadingContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 110, 110)];
    self.loadingContainerView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.85];
    self.loadingContainerView.layer.cornerRadius = 14;
    self.loadingContainerView.center = self.view.center;
    self.loadingContainerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.loadingContainerView.alpha = 0.0; // ซ่อนไว้ก่อนในตอนแรก
    
    // สร้างตัวหมุน Loading (Activity Indicator)
    if (@available(iOS 13.0, *)) {
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
        self.activityIndicator.color = [UIColor whiteColor];
    } else {
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    self.activityIndicator.center = CGPointMake(self.loadingContainerView.bounds.size.width / 2, 40);
    [self.loadingContainerView addSubview:self.activityIndicator];
    
    // สร้างข้อความ "กำลังโหลด" ด้านล่างตัวหมุน
    UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 75, self.loadingContainerView.bounds.size.width - 10, 20)];
    loadingLabel.text = @"กำลังโหลด";
    loadingLabel.textColor = [UIColor whiteColor];
    loadingLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    loadingLabel.textAlignment = NSTextAlignmentCenter;
    [self.loadingContainerView addSubview:loadingLabel];
    
    // นำกล่อง Loading ไปใส่ในหน้า View หลัก (เหนือ WebView)
    [self.view addSubview:self.loadingContainerView];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {    
    // เริ่มทำงานตัวหมุนและค่อยๆ เฟดแสดง Loading Container ขึ้นมา
    [self.activityIndicator startAnimating];
    [UIView animateWithDuration:0.25 animations:^{
        self.loadingContainerView.alpha = 1.0;
    }];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // ค่อยๆ เฟดซ่อน Loading Container ลงไปเมื่อเว็บโหลดเสร็จสิ้น
    [UIView animateWithDuration:0.25 animations:^{
        self.loadingContainerView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.activityIndicator stopAnimating];
    }];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    // ค่อยๆ เฟดซ่อน Loading Container ลงไปเมื่อการโหลดล้มเหลว/ตัดการทำงานเพื่อไม่ให้ค้างบังหน้าจอ
    [UIView animateWithDuration:0.25 animations:^{
        self.loadingContainerView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.activityIndicator stopAnimating];
    }];
}

@end
