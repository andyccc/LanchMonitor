//
//  YSMonitor.m
//  LanchMonitor
//
//  Created by andyccc on 2020/8/5.
//

#import "YSMonitor.h"
#import <mach/mach.h>
#import <sys/sysctl.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

BOOL processInfoForPID(int pid, struct kinfo_proc *procInfo) {
    int cmd[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
    size_t size = sizeof(*procInfo);
    return sysctl(cmd, sizeof(cmd)/sizeof(*cmd), procInfo, &size, NULL, 0) == 0;
}

CFAbsoluteTime processStartTime(void) {
    if (__t1 == 0) {
        struct kinfo_proc kProcInfo;
        if (processInfoForPID([[NSProcessInfo processInfo] processIdentifier], &kProcInfo)) {
            __t1 = kProcInfo.kp_proc.p_un.__p_starttime.tv_sec * 1000.0 + kProcInfo.kp_proc.p_un.__p_starttime.tv_usec / 1000.0;
        } else {
            NSLog(@"无法取得进程的信息");
        }
    }
    return __t1;
}

CFAbsoluteTime processFinishLaunchingTime(void) {
    if (__t3 == 0) {
        __t3 = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970;
    }
    return __t3;
}

void showPreMainTime(void) {
    CFAbsoluteTime time  = __t2 * 1000.0 - __t1;
    NSLog(@"preMainTime： %f", time);
}

void showMainTime(void) {
    CFAbsoluteTime time  = __t3 * 1000.0 - __t2 * 1000.0;
    NSLog(@"mainTime： %f", time);
}

#define KMonitorType 3

@interface CATransaction (Private)

+ (void)addCommitHandler:(void(^)(void))block forPhase:(int)phase;

@end

@implementation YSMonitor

+ (void)load {
    
#if KMonitorType == 1
    {
        for (int i = 0; i < 6; i++) {
            [CATransaction addCommitHandler:^{
                [YSMonitor printWithDesc:[NSString stringWithFormat:@"CATransaction 方案:%d ", i]];
            } forPhase:i];
        }
    }
#elif KMonitorType == 2
    
    {
        //注册block
        CFRunLoopRef mainRunloop = [[NSRunLoop mainRunLoop] getCFRunLoop];
        CFRunLoopPerformBlock(mainRunloop,NSDefaultRunLoopMode,^(){
            [self printWithDesc:@"AMP 方案：CFRunLoopPerformBlock"];
        });
    }
    
    {
        //注册kCFRunLoopBeforeTimers回调
        CFRunLoopRef mainRunloop = [[NSRunLoop mainRunLoop] getCFRunLoop];
        CFRunLoopActivity activities = kCFRunLoopAllActivities;
        CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, activities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
            if (activity == kCFRunLoopBeforeTimers) {
                [self printWithDesc:@"AMP 方案：runloop beforetimers launch"];
                CFRunLoopRemoveObserver(mainRunloop, observer, kCFRunLoopCommonModes);
            }
        });
        CFRunLoopAddObserver(mainRunloop, observer, kCFRunLoopCommonModes);
    }
#elif KMonitorType == 3
    
    {
        Class aClass = NSClassFromString(@"BSXPCServiceConnectionMessageReply");
        Class class = aClass;
        SEL originalSelector = NSSelectorFromString(@"send");
        SEL swizzledSelector = @selector(send1);
        
        Method originalMethod = class_getInstanceMethod(aClass, originalSelector);
        Method swizzledMethod = class_getInstanceMethod([YSMonitor class], swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    }
    
#endif
}

- (void)send1 {
    // 延迟 3 秒进行测试
    // [NSThread sleepForTimeInterval:20];
    [self send1];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [YSMonitor printWithDesc:@"IPC 方案：首屏渲染物料已经提交给渲染进程"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [YSMonitor printWithDesc:@"IPC 方案：首屏渲染已经完成"];
        });
    });
}

+ (void)printWithDesc:(NSString *)desc {
    static NSTimeInterval processStartTime = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        processStartTime = [self processStartTime];
    });
    NSTimeInterval stamp = [[NSDate date] timeIntervalSince1970];
    NSLog(@"%@=%@",desc, @(stamp * 1000.0 - processStartTime));
}

+ (BOOL)processInfoWithPID:(int)pid proInfo:(struct kinfo_proc*)procInfo {
    int cmd[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
    size_t size = sizeof(*procInfo);
    return sysctl(cmd, sizeof(cmd)/sizeof(*cmd), procInfo, &size, NULL, 0) == 0;
}

//获得进程开始的时间 (iOS App启动开始的时间)
+ (NSTimeInterval)processStartTime {
    struct kinfo_proc kinfo;
    
    if ([self processInfoWithPID:[[NSProcessInfo processInfo] processIdentifier] proInfo:&kinfo]) {
        return kinfo.kp_proc.p_un.__p_starttime.tv_sec * 1000.0 + kinfo.kp_proc.p_un.__p_starttime.tv_usec / 1000.0;
    } else {
        NSAssert(NO, @"无法取得进程的信息");
        return 0;
    }
}

@end
