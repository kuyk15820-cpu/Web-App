#import "RootViewController.h"
#import <WebKit/WebKit.h>
#include "ENCRYPT/xorstr.hpp"

// ประกาศเพิ่มโปรโตคอล <WKURLSchemeHandler> เพื่อรับหน้าที่เป็นเว็บเซิร์ฟเวอร์จำลองในแอป
@interface RootViewController () <WKNavigationDelegate, WKUIDelegate, WKURLSchemeHandler>
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
    config.allowsInlineMediaPlayback = YES; // อนุญาตให้เล่นวิดีโอแบบฝังในหน้าแอปได้เลย
    
    // ⚙️ ลงทะเบียนโปรโตคอลเสมือนชื่อ "localpatch" เพื่อหลอกระบบความปลอดภัย WebKit ของ iOS
    [config setURLSchemeHandler:self forURLScheme:@"localpatch"];
    
    // เปิดสิทธิ์การเข้าถึงไฟล์แบบ Universal เพื่อรองรับกรณีมีสคริปต์ภายในเรียกหากัน
    [config.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
    [config setValue:@YES forKey:@"allowUniversalAccessFromFileURLs"];
    
    if (@available(iOS 13.0, *)) {
        config.defaultWebpagePreferences.allowsContentJavaScript = YES; // เปิดใช้งาน JavaScript
    }
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
    self.webView.backgroundColor = [UIColor blackColor];
    self.webView.opaque = NO;
    
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];

    // ======================================================================
    // ⚙️ ตั้งค่าตามโครงสร้างของคุณ: ช่องลิงก์ใส่ "0" และช่องไฟล์ชี้ไปที่โฟลเดอร์ Archive
    // ======================================================================
    NSString *targetURL  = [NSString stringWithUTF8String:xorstr_("0")];
    NSString *htmlName  = [NSString stringWithUTF8String:xorstr_("Archive/index")]; 
    // ======================================================================

    // ระบบตรวจสอบสวิตช์เงื่อนไขในการเลือกโหมดโหลดเว็บ
    if ([htmlName isEqualToString:@"0"]) {
        // โหมดโหลดลิงก์ URL ออนไลน์ปกติ
        NSURL *url = [NSURL URLWithString:targetURL];
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
        [self.webView loadRequest:request];
        NSLog(@"[WebKit] กำลังโหลดโหมด: ลิงก์ URL ออนไลน์");
        
    } else if ([targetURL isEqualToString:@"0"]) {
        // โหมดโหลดไฟล์ HTML ในแอปผ่านโปรโตคอลจำลอง
        NSURL *customURL = [NSURL URLWithString:@"localpatch://localhost/Archive/index.html"];
        NSURLRequest *request = [NSURLRequest requestWithURL:customURL];
        [self.webView loadRequest:request];
        NSLog(@"[WebKit-Theos] กำลังโหลดโหมด: Custom Scheme Server (Offline Patch)");
    }
}

#pragma mark - WKURLSchemeHandler (ระบบจำลองเซิร์ฟเวอร์ ยัด Headers หลอก WebKit)

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    NSURL *url = urlSchemeTask.request.URL;
    NSString *path = url.path; // เช่น "/Archive/index.html" หรือ "/Archive/abcd.js"
    
    // ค้นหาตำแหน่งไฟล์จริงภายใน Resources (.ipa)
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *fullPath = [resourcePath stringByAppendingPathComponent:path];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
        NSData *data = [NSData dataWithContentsOfFile:fullPath];
        
        // 🛠️ ตรวจสอบชนิดไฟล์ (MIME-Type) แบบระบุเอง ปลอดภัยจากปัญหาคอมไพล์ไม่ผ่านแน่นอน
        NSString *extension = [[fullPath pathExtension] lowercaseString];
        NSString *mimeType = @"text/plain"; // ค่าเริ่มต้นถ้าไม่ตรงกับอะไรเลย
        
        if ([extension isEqualToString:@"html"] || [extension isEqualToString:@"htm"]) {
            mimeType = @"text/html";
        } else if ([extension isEqualToString:@"js"]) {
            mimeType = @"application/javascript";
        } else if ([extension isEqualToString:@"css"]) {
            mimeType = @"text/css";
        } else if ([extension isEqualToString:@"png"]) {
            mimeType = @"image/png";
        } else if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
            mimeType = @"image/jpeg";
        } else if ([extension isEqualToString:@"mp4"]) {
            mimeType = @"video/mp4";
        } else if ([extension isEqualToString:@"wasm"]) {
            mimeType = @"application/wasm";
        }
        
        // 🔑 [หัวใจสำคัญ] ยัด COOP และ COEP Headers เพื่อปลดล็อกระบบความปลอดภัยให้ FFmpeg โหลดผ่าน
        NSDictionary *headers = @{
            @"Content-Type": mimeType,
            @"Content-Length": [NSString stringWithFormat:@"%lu", (unsigned long)data.length],
            @"Access-Control-Allow-Origin": @"*",
            @"Cross-Origin-Opener-Policy": @"same-origin",   
            @"Cross-Origin-Embedder-Policy": @"require-corp" 
        };
        
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headers];
        
        [urlSchemeTask didReceiveResponse:response];
        [urlSchemeTask didReceiveData:data];
        [urlSchemeTask didFinish];
        
    } else {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:404 HTTPVersion:@"HTTP/1.1" headerFields:nil];
        [urlSchemeTask didReceiveResponse:response];
        [urlSchemeTask didFinish];
    }
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    // ปล่อยว่างไว้
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
}

@end
