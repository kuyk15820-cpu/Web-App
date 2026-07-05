#import "RootViewController.h"
#import <WebKit/WebKit.h>
#include "ENCRYPT/xorstr.hpp"
#import "DODoubleHelixIndicator.h" // 1. นำเข้า Header ของ Indicator

@interface RootViewController () <WKNavigationDelegate, WKUIDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) DODoubleHelixIndicator *loadingIndicator; // 2. เพิ่ม Property สำหรับจัดการ Indicator
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
    [self setupLoadingIndicator]; // 3. เรียกใช้ฟังก์ชันตั้งค่า Indicator
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

// 4. ฟังก์ชันสร้างและจัดตำแหน่ง Indicator ไว้กลางหน้าจอ
- (void)setupLoadingIndicator {
    self.loadingIndicator = [[DODoubleHelixIndicator alloc] init];
    
    // ตั้งให้อยู่กึ่งกลางหน้าจอพอดี
    self.loadingIndicator.center = self.view.center;
    self.loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // ซ่อนไว้ก่อนในตอนแรก (จะเปิดใช้ตอนเริ่มโหลดเว็บ)
    self.loadingIndicator.hidden = YES;
    
    // นำไปใส่ไว้บนสุดของ View (ทับบน WebView)
    [self.view addSubview:self.loadingIndicator];
}

#pragma mark - WKNavigationDelegate

// 5. เมื่อเว็บเริ่มโหลด -> แสดง Indicator
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {    
    self.loadingIndicator.hidden = NO;
    NSLog(@"[WebKit] เริ่มโหลดหน้าเว็บ - แสดงอินดิเคเตอร์");
}

// 6. เมื่อเว็บโหลดเสร็จ -> ซ่อน Indicator
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.loadingIndicator.hidden = YES;
    NSLog(@"[WebKit] โหลดหน้าเว็บเสร็จสิ้น - ซ่อนอินดิเคเตอร์");
}

// 7. เผื่อกรณีโหลดไม่สำเร็จ หรือเกิดข้อผิดพลาด -> ก็ต้องซ่อน Indicator เช่นกัน
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation hospitality:(NSError *)error {
    self.loadingIndicator.hidden = YES;
    NSLog(@"[WebKit Error] โหลดหน้าเว็บล้มเหลว: %@", error.localizedDescription);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    self.loadingIndicator.hidden = YES;
    NSLog(@"[WebKit Error] โหลดหน้าเว็บล้มเหลวระหว่างดำเนินการ: %@", error.localizedDescription);
}

@end
