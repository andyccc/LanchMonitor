//
//  YSMonitor.h
//  LanchMonitor
//
//  Created by andyccc on 2020/8/5.
//

#import <Foundation/Foundation.h>


static CFAbsoluteTime __t1;
static CFAbsoluteTime __t2;
static CFAbsoluteTime __t3;

// gcd dispatch_benchmark 是 libdispatch(Grand Central Dispatch) 的一部分。但严肃地说，这个方法并没有被公开声明，所以我们必须要自己声明：
extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));

extern CFAbsoluteTime processStartTime(void);

extern CFAbsoluteTime processFinishLaunchingTime(void);

extern void showPreMainTime(void);

extern void showMainTime(void);

void static __attribute__((constructor)) before_main() {
    if (__t2 == 0) {
        __t2 = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970;
    }
}

/**
 通过添加环境变量可以打印出APP的启动时间分析（Edit scheme -> Run -> Arguments）
 DYLD_PRINT_STATISTICS设置为1
 如果需要更详细的信息，那就将DYLD_PRINT_STATISTICS_DETAILS设置为1
 */

NS_ASSUME_NONNULL_BEGIN

@interface YSMonitor : NSObject

@end

NS_ASSUME_NONNULL_END
