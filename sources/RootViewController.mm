#import "RootViewController.h"
#import <WebKit/WebKit.h>
#include "ENCRYPT/xorstr.hpp"

@interface RootViewController () <WKNavigationDelegate, WKUIDelegate>
@property (nonatomic, strong) WKWebView *webView;
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
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.navigationController) {
        self.navigationController.navigationBarHidden = YES;
    }

    [self setupWebKitView];
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
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.opaque = NO;
    
    if (@available(iOS 15.0, *)) {
        self.webView.scrollView.backgroundColor = [UIColor clearColor];
    }
    
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];
    
    NSString *targetURL  = [NSString stringWithUTF8String:xorstr_("https://comfy-pothos-996d0d.netlify.app/")];
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

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
}

@end
