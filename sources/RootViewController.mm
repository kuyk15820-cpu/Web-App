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
    
    self.view.backgroundColor = [UIColor blackColor];
    
    if (self.navigationController) {
        self.navigationController.navigationBarHidden = YES;
    }

    [self setupWebKitView];
}

- (void)setupWebKitView {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = YES;
    
    // 🔒 สำคัญมาก: เปิดสิทธิ์เต็มระบบเพื่อให้ HTML สามารถโหลดไฟล์สคริปต์ abcd.js ในแอปมาทำงานร่วมกันได้
    [config.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
    [config setValue:@YES forKey:@"allowUniversalAccessFromFileURLs"];
    
    if (@available(iOS 13.0, *)) {
        config.defaultWebpagePreferences.allowsContentJavaScript = YES; // เปิดการทำงาน JavaScript
    }
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    self.webView.backgroundColor = [UIColor blackColor];
    self.webView.opaque = NO;
    
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];

    // ======================================================================
    // ⚙️ ตั้งค่าตามที่คุณเลือก: ช่องลิงก์ใส่ "0" และช่องไฟล์ใส่ชื่อ "index"
    // ======================================================================
    NSString *targetURL  = [NSString stringWithUTF8String:xorstr_("0")];
    NSString *htmlName  = [NSString stringWithUTF8String:xorstr_("index")]; 
    // ======================================================================

    // ระบบตรวจสอบสวิตช์เงื่อนไข
    if ([htmlName isEqualToString:@"0"]) {
        // โหมดโหลดลิงก์ URL ออนไลน์
        NSURL *url = [NSURL URLWithString:targetURL];
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
        [self.webView loadRequest:request];
        NSLog(@"[WebKit] กำลังโหลดโหมด: ลิงก์ URL ออนไลน์");
        
    } else if ([targetURL isEqualToString:@"0"]) {
        // โหมดโหลดไฟล์ HTML ในแอป (จับคู่กับไฟล์ abcd.js ในโฟลเดอร์เดียวกัน)
        NSString *htmlPath = [[NSBundle mainBundle] pathForResource:htmlName ofType:@"html"];
        if (htmlPath) {
            NSURL *fileURL = [NSURL fileURLWithPath:htmlPath];
            // บังคับสิทธิ์ให้อ่านไฟล์ร่วมกันใน Resources (ทำให้เรียก abcd.js เจอ)
            NSURL *readAccessURL = [fileURL URLByDeletingLastPathComponent];
            [self.webView loadFileURL:fileURL allowingReadAccessToURL:readAccessURL];
            NSLog(@"[WebKit] กำลังโหลดโหมด: Local HTML (%@.html + JS)", htmlName);
        } else {
            NSLog(@"[WebKit Error] ไม่พบไฟล์ %@.html ในโฟลเดอร์แอป", htmlName);
        }
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
}

@end
