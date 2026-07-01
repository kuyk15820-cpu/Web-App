#import "RootViewController.h"
#import <WebKit/WebKit.h>
#include "ENCRYPT/xorstr.hpp"
#import <MobileCoreServices/MobileCoreServices.h> // จำเป็นต้องใช้เพื่อดึงคลาสสำหรับเช็กประเภทไฟล์ (MIME-Type)

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
        // โหมดโหลดไฟล์ HTML ในแอป (จับคู่กับไฟล์ abcd.js ที่แตกไฟล์จาก zip ลง layout/Resources/)
        // เปลี่ยนมาสั่งโหลดผ่านโปรโตคอล "localpatch://" เพื่อยัด Headers ปลดล็อกความปลอดภัยให้กับ FFmpeg Engine
        NSURL *customURL = [NSURL URLWithString:@"localpatch://localhost/Archive/index.html"];
        NSURLRequest *request = [NSURLRequest requestWithURL:customURL];
        [self.webView loadRequest:request];
        NSLog(@"[WebKit-Theos] กำลังโหลดโหมด: Custom Scheme Server (Offline Patch)");
    }
}

#pragma mark - WKURLSchemeHandler (ระบบจำลองเซิร์ฟเวอร์ ยัด Headers หลอก WebKit)

// ฟังก์ชันนี้จะดักสัญญาณทุกครั้งที่หน้าเว็บเรียกหาไฟล์ (เช่น เรียก index.html หรือ abcd.js)
- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    NSURL *url = urlSchemeTask.request.URL;
    NSString *path = url.path; // จะได้ค่าพาธไฟล์ เช่น "/Archive/index.html" หรือ "/Archive/abcd.js"
    
    // ค้นหาตำแหน่งไฟล์จริงภายใน Main Bundle ของแอป ที่มาจากโฟลเดอร์ layout/Resources ของ Theos
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString *fullPath = [resourcePath stringByAppendingPathComponent:path];
    
    // ตรวจสอบว่ามีไฟล์อยู่จริงในเครื่องทราสหรือไม่
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
        NSData *data = [NSData dataWithContentsOfFile:fullPath];
        
        // ค้นหาและตั้งค่า MIME-Type (เช่น text/html, application/javascript) ตามนามสกุลไฟล์โดยอัตโนมัติ
        NSString *extension = [fullPath pathExtension];
        NSString *mimeType = @"text/plain";
        CFStringRef uti = UTTypeCreateInferenceFromExtension((__bridge CFStringRef)extension);
        if (uti) {
            NSString *registeredType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
            if (registeredType) mimeType = registeredType;
            CFRelease(uti);
        }
        
        // 🔑 [หัวใจสำคัญ] ยัด COOP และ COEP Headers เพื่อปลดล็อกให้สคริปต์ออนไลน์สร้าง SharedArrayBuffer สำเร็จ
        NSDictionary *headers = @{
            @"Content-Type": mimeType,
            @"Content-Length": [NSString stringWithFormat:@"%lu", (unsigned long)data.length],
            @"Access-Control-Allow-Origin": @"*",
            @"Cross-Origin-Opener-Policy": @"same-origin",   // 👈 ปลดล็อกบราวเซอร์บล็อกเอนจิน
            @"Cross-Origin-Embedder-Policy": @"require-corp" // 👈 ปลดล็อกบราวเซอร์บล็อกเอนจิน
        };
        
        // ประกอบ Response ส่งกลับไปให้หน้าเว็บประมวลผลต่อ
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headers];
        
        [urlSchemeTask didReceiveResponse:response];
        [urlSchemeTask didReceiveData:data];
        [urlSchemeTask didFinish];
        
    } else {
        // หากไม่พบไฟล์ ส่งสถานะ 404 กลับไป
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:404 HTTPVersion:@"HTTP/1.1" headerFields:nil];
        [urlSchemeTask didReceiveResponse:response];
        [urlSchemeTask didFinish];
    }
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    // ปล่อยว่างไว้ ไม่จำเป็นต้องประมวลผลเมื่อสิ้นสุดคำสั่งส่งไฟล์
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
}

@end
