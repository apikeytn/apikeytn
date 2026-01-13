#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import KeySystem.h

// --- CẤU HÌNH ---
#define API_URL @"http://getudidv3.2bd.net/api.php?key="
#define DELAY_STEP 2.5 

static BOOL isActivated = NO;

// --- KHAI BÁO CÁC HÀM ---
void StartSequence(void);
void Step2_FetchData(void);
void Step3_LoginPopup(void);
void Final_Success(NSString *expire, NSString *ip);
void Final_Error(NSString *title, NSString *msg);

// =================================================================
// HÀM TẠO GIAO DIỆN LOADING (BƯỚC 1 & 2)
// =================================================================
void ShowCustomLoading(NSString *statusText, void (^completion)(void)) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (!root) return;

        // 1. Khung nền kính mờ
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        blurView.frame = CGRectMake(0, 0, 180, 150);
        blurView.center = root.view.center;
        blurView.layer.cornerRadius = 20;
        blurView.clipsToBounds = YES;
        blurView.alpha = 0;
        [root.view addSubview:blurView];

        // 2. Tự động lấy Icon App
        NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
        NSString *iconName = [[[[infoPlist objectForKey:@"CFBundleIcons"] objectForKey:@"CFBundlePrimaryIcon"] objectForKey:@"CFBundleIconFiles"] lastObject];
        UIImage *appIcon = [UIImage imageNamed:iconName];
        
        UIImageView *iconImageView = [[UIImageView alloc] initWithImage:appIcon];
        iconImageView.frame = CGRectMake(65, 30, 50, 50);
        iconImageView.layer.cornerRadius = 12;
        iconImageView.clipsToBounds = YES;
        [blurView.contentView addSubview:iconImageView];

        // 3. Hiệu ứng xoay tròn Icon
        CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotation.toValue = @(M_PI * 2.0);
        rotation.duration = 1.5;
        rotation.cumulative = YES;
        rotation.repeatCount = HUGE_VALF;
        [iconImageView.layer addAnimation:rotation forKey:@"rotationAnimation"];

        // 4. Nhãn chữ thông báo
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, 180, 30)];
        loadingLabel.text = statusText;
        loadingLabel.textColor = [UIColor whiteColor];
        loadingLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        loadingLabel.textAlignment = NSTextAlignmentCenter;
        [blurView.contentView addSubview:loadingLabel];

        [UIView animateWithDuration:0.3 animations:^{ blurView.alpha = 1.0; }];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DELAY_STEP * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{ blurView.alpha = 0; } completion:^(BOOL finished) {
                [blurView removeFromSuperview];
                if (completion) completion();
            }];
        });
    });
}

// =================================================================
// QUY TRÌNH XỬ LÝ
// =================================================================

void StartSequence() {
    ShowCustomLoading(@"Đang khởi động...", ^{ Step2_FetchData(); });
}

void Step2_FetchData() {
    ShowCustomLoading(@"Đang tải dữ liệu từ máy chủ...", ^{ Step3_LoginPopup(); });
}

void Step3_LoginPopup() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Nhập Key" message:nil preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Điền Key Của Bạn Tại Đây";
            textField.textAlignment = NSTextAlignmentCenter;
        }];

        [alert addAction:[UIAlertAction actionWithTitle:@"Liên Hệ" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/your_admin"] options:@{} completionHandler:nil];
            Step3_LoginPopup();
        }]];

        [alert actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *key = alert.textFields.firstObject.text;
            
            UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"Vui lòng chờ..." message:nil preferredStyle:UIAlertControllerStyleAlert];
            [root presentViewController:loading animated:YES completion:nil];

            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", API_URL, key]];
            [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [loading dismissViewControllerAnimated:YES completion:^{
                        if (err || !data) { Final_Error(@"Lỗi", @"Không thể kết nối Server"); return; }
                        
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                        if ([json[@"status"] isEqualToString:@"success"]) {
                            Final_Success(json[@"expire"], json[@"ip"]);
                        } else {
                            NSString *errMsg = json[@"message"] ?: @"Vui lòng kiểm tra lại Key.";
                            Final_Error(@"KEY không hợp lệ", errMsg);
                        }
                    }];
                });
            }] resume];
        }];
        [root presentViewController:alert animated:YES completion:nil];
    });
}

// THÀNH CÔNG
void Final_Success(NSString *expire, NSString *ip) {
    NSString *msg = [NSString stringWithFormat:@"Hạn sử dụng : %@\nIP: %@", expire, ip];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"\nĐăng nhập thành công" message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:@"\nĐăng nhập thành công"];
    [attrTitle addAttribute:NSForegroundColorAttributeName value:[UIColor systemGreenColor] range:NSMakeRange(0, attrTitle.length)];
    [alert setValue:attrTitle forKey:@"attributedTitle"];

    [alert addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleDefault handler:nil]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    isActivated = YES;
}

// THẤT BẠI - TỰ VĂNG SAU 3 GIÂY
void Final_Error(NSString *title, NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *finalMsg = [NSString stringWithFormat:@"%@\n\n(Ứng dụng sẽ văng sau 3s)", msg];
        NSString *fullTitle = [NSString stringWithFormat:@"❌ %@", title];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:fullTitle message:finalMsg preferredStyle:UIAlertControllerStyleAlert];
        
        NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:fullTitle];
        [attrTitle addAttribute:NSForegroundColorAttributeName value:[UIColor systemRedColor] range:NSMakeRange(0, attrTitle.length)];
        [alert setValue:attrTitle forKey:@"attributedTitle"];

        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            exit(0); 
        });
    });
}

%hook UIApplication
- (void)didFinishLaunchingWithOptions:(id)arg1 {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        StartSequence();
    });
}
%end
