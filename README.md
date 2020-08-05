# LanchMonitor

app启动时间计算

-

#### 按照不同的阶段
* dyld
* 减少动态库、合并一些动态库（定期清理不必要的动态库）
* 减少Objc类、分类的数量、减少Selector数量（定期清理不必要的类、分类）
* 减少C++虚函数数量
* Swift尽量使用struct

#### runtime
*  用+initialize方法和dispatch_once取代所有的__attribute__((constructor))、C++静态构造器、ObjC的+load

#### main
* 在不影响用户体验的前提下，尽可能将一些操作延迟，不要全部都放在finishLaunching方法中
* 按需加载

-

App 启动时间, 直接影响用户对 app 的第一体验和判断. 如果启动时间过长, 不单用户体验会下降, 还有可能会触发苹果的 watch dog 机制而 kill 掉 App, 所以 App 启动时间优化也十分重要

启动时间分为两部分

一: main 函数执行之前的加载时间主要是系统的动态链接库和可执行文件的加载时间  
二: main 函数开始到 application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 执行结束前的时间

一: 计算 main 函数以前消耗的时间 (pre-main)
-------------------------------

在 Edit Scheme 中添加配置中 Run/Arguments/Environment Variables 添加 Name 为 DYLD_PRINT_STATISTICS,Value 值为 YES

```
Total pre-main time: 263.84 milliseconds (100.0%)
         dylib loading time: 156.06 milliseconds (59.1%)
        rebase/binding time:   9.52 milliseconds (3.6%)
            ObjC setup time:  13.14 milliseconds (4.9%)
           initializer time:  85.11 milliseconds (32.2%)
           slowest intializers :
             libSystem.B.dylib :   4.11 milliseconds (1.5%)
   libBacktraceRecording.dylib :   6.86 milliseconds (2.6%)
    libMainThreadChecker.dylib :  36.43 milliseconds (13.8%)
                     MJRefresh :  28.19 milliseconds (10.6%)
                          PSMC :   6.54 milliseconds (2.4%)
```

main 函数启动之前耗时，对于一般的小型 APP 来说，影响微乎其微，但对于大型 APP(动态库超过 50 或二进制文件超过 30MB) 来说，就会变得很明显  
一般来说 main() 函数之前耗时 不宜超过 400 毫秒，之前与之后整体时间不宜超过 20 秒，如果超过 20 秒，系统会关闭进程，无法启动 APP

二: main 函数花费的时间
---------------

main 函数以后花费的时间主要是从 main 函数开始到 application:didFinishLaunchingWithOptions: 之间的时间, 方法如下:

OC 计算 main 函数花费时间
-----------------

main.m 中

```
#include <stdio.h>
/**
 typedef double CFTimeInterval;
 typedef CFTimeInterval CFAbsoluteTime;
 */
CFAbsoluteTime appStartLaunchTime;
CGFloat appMainFloatLaunchTime;
int main(int argc, char * argv[]) {
    @autoreleasepool {
        
        // 准确的double
        appStartLaunchTime = CFAbsoluteTimeGetCurrent();
       
        
        
        
        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
        /*
         @property(readonly) NSTimeInterval timeIntervalSince1970;
         typedef double NSTimeInterval;*/
        // 返回是double类型但是我接收的时候强制变为了CGFloat精度低
        appMainFloatLaunchTime =  [dat timeIntervalSince1970];

        

        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
```

AppDelegate.m

```
#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
// main.m中定义的变量
extern CFAbsoluteTime appStartLaunchTime;
extern double appMainFloatLaunchTime;

implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    [self mp3Handle];

    NSLog(@"app启动时间%f",CFAbsoluteTimeGetCurrent() - appStartLaunchTime);
   NSLog(@"didFinishLaunchingWithOptions\n");
    NSDate *dat = [NSDate dateWithTimeIntervalSinceNow:0];
    CGFloat floatCurrentTimeInterval = [dat timeIntervalSince1970];
    NSLog(@"app FLoat启动时间%f", floatCurrentTimeInterval - appMainFloatLaunchTime);
    return YES;
}
```

打印结果为

```
2020-05-29 07:32:47.171263+0800 OCTestFirst[2235:54880] app启动时间0.522912
2020-05-29 07:32:47.171375+0800 OCTestFirst[2235:54880] didFinishLaunchingWithOptions
2020-05-29 07:32:47.171480+0800 OCTestFirst[2235:54880] app FLoat启动时间0.523144
```

所以不是 double 类型的 appMainFloatLaunchTime 精度就差了些, 如果我把 appMainFloatLaunchTime 的类型由 CGFloat 改为 double 类型结果为

```
2020-05-29 07:39:10.328183+0800 OCTestFirst[2323:58298] app启动时间0.498283
2020-05-29 07:39:10.328278+0800 OCTestFirst[2323:58298] didFinishLaunchingWithOptions
2020-05-29 07:39:10.328453+0800 OCTestFirst[2323:58298] app FLoat启动时间0.498579
```

所以从 date 中获取的 timeInterval 还是没有 CFAbsoluteTime 精度高

Swift 计算 main 函数花费时间
--------------------

由于 Swift 中没有 main.swift 这个文件  
[苹果官网解释](https://developer.apple.com/swift/blog/?id=7)  
In Xcode, Mac templates default to including a “main.swift” file, but for iOS apps the default for new iOS project templates is to add @UIApplicationMain to a regular Swift file. This causes the compiler to synthesize a main entry point for your iOS app, and eliminates the need for a “main.swift” file

也就是说，通过添加 @UIApplicationMain 标志的方式，帮我们添加了 mian 函数了。所以如果是我们需要在 mian 函数中做一些其它操作的话，需要我们自己来创建 main.swift 文件，这个也是苹果允许的

注释掉 AppDelegate 类中的 @UIApplicationMain 标志；  
自行创建 main.swift(注意: main 一定要小写, 不能写成 Main 否则报错) 文件，并添加程序入口, 代码如下:

```
var appStartLaunchTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

UIApplicationMain(CommandLine.argc, UnsafeMutableRawPointer(CommandLine.unsafeArgv).bindMemory(to: UnsafeMutablePointer<Int8>.self,capacity: Int(CommandLine.argc)), nil, NSStringFromClass(AppDelegate.self))

/*
UIApplicationMain(<#T##argc: Int32##Int32#>, <#T##argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>##UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>#>, <#T##principalClassName: String?##String?#>, <#T##delegateClassName: String?##String?#>)


这里延伸出来的32位

1        0
2        1
3	  2
8	  3
16	  4
32	   5
64	   6
128	   7
256	   8
521	   9
1024   10
计算机中的整数分为两类：不带符号位的整数（unsigned integer，也称为无符号整数），此类整数一定是正整数；带符号位的整数（signed integer），此类整数可以表示正整数，又可以表示负整数。
无符号整数常用于表示地址、索引等正整数，它们可以是8位、16位、32位、64位甚至更多。8个二进制表示的正整数其取值范围是0~255（-1），16位二进制位表示的正整数其取值范围是0~65535（-1），32位二进制位表示的正整数其取值范围是0~-1。
有符号和无符号的差别
int是有符号的，unsigned是无符号的。
它们所占的字节数其实是一样的，但是有符号的需要安排一个位置来表达我这个数值的符号，因此说它能表示的绝对值就要比无符号的少一半。举个例子，我们有一个1个 [1]  字节的整数（虽然这种类型不存在），那么无符号的就是这样：00000000～11111111 这个就是无符号的范围。
一个字节是8位， 有符号的数，因为第一个位要用来表示符号，那么就只剩下7个位置可以用来表示数了0000000～1111111因为有符号，所以还可以表示范围：-1111 111 ～ +1111 111。

/ In the following example, the constant `y` is successfully created from
    /// `x`, an `Int` instance with a value of `100`. Because the `Int8` type
    /// can represent `127` at maximum, the attempt to create `z` with a value
    /// of `1000` results in a runtime error.
    ///
    ///     let x = 100
    ///     let y = Int8(x)
    ///     // y == 100
    ///     let z = Int8(x * 10)
    ///     // Error: Not enough bits to represent the given value




/ Any fractional part of the value passed as `source` is removed, rounding
    /// the value toward zero.
    ///   Int32
    ///     let x = Int(21.5)
    ///     // x == 21
    ///     let y = Int(-21.5)
    ///     // y == -21
    ///
    /// If `source` is outside the bounds of this type after rounding toward
    /// zero, a runtime error may occur.
    ///       UInt32
    ///     let z = UInt(-21.5)
    ///     // Error: ...the result would be less than UInt.min
    ///
    /// - Parameter source: A floating-point value to convert to an integer.
    ///   `source` must be representable in this type after rounding toward


*/
```

![](https://img-blog.csdnimg.cn/20200529081252948.png)  
然后在 AppDelegate 中编写如下代码:

```
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      // Override point for customization after application launch.
      // APP启动时间耗时，从mian函数开始到didFinishLaunchingWithOptions方法结束
      DispatchQueue.main.async {
          print("APP启动时间耗时，从mian函数开始到didFinishLaunchingWithOptions方法：\(CFAbsoluteTimeGetCurrent() - appStartLaunchTime)。")
      }
      return true
  }
```

优化的目标  
启动过程分为四个部分：  
1 main() 函数之前  
2 main() 函数之后至 applicationWillFinishLaunching 完成  
3 App 完成所有本地数据的加载并将相应的信息展示给用户  
4 App 完成所有联网数据的加载并将相应的信息展示给用户  
1+2 一起决定了我们需要用户等待多久才能出现一个主视图  
1+2+3 决定了用户视觉上的等待出现有用信息所需要的时长。  
1+2+3+4 决定了我们需要多少时间才能让我们需要展示给用户的所有信息全部出现。

1 main() 函数之前

耗时部分:  
动态库加载  
指针定位  
类初始化 load  
其他初始化

测试过程: Before 两个星期之前的版本 ,After 两个星期之后的版本

Before  
Total pre-main time: 263.84 milliseconds (100.0%)  
dylib loading time: 156.06 milliseconds (59.1%)  
rebase/binding time: 9.52 milliseconds (3.6%)  
ObjC setup time: 13.14 milliseconds (4.9%)  
initializer time: 85.11 milliseconds (32.2%)  
slowest intializers :  
libSystem.B.dylib : 4.11 milliseconds (1.5%)  
libBacktraceRecording.dylib : 6.86 milliseconds (2.6%)  
libMainThreadChecker.dylib : 36.43 milliseconds (13.8%)  
MJRefresh : 28.19 milliseconds (10.6%)  
PSMC : 6.54 milliseconds (2.4%)

After  
Total pre-main time: 271.30 milliseconds (100.0%)  
dylib loading time: 160.96 milliseconds (59.3%)  
rebase/binding time: 9.08 milliseconds (3.3%)  
ObjC setup time: 15.05 milliseconds (5.5%)  
initializer time: 86.20 milliseconds (31.7%)  
slowest intializers :  
libSystem.B.dylib : 4.45 milliseconds (1.6%)  
libBacktraceRecording.dylib : 6.83 milliseconds (2.5%)  
libMainThreadChecker.dylib : 36.85 milliseconds (13.5%)  
MJRefresh : 26.04 milliseconds (9.5%)  
PSMC : 8.70 milliseconds (3.2%)

App 启动时间

After 和 Before  
Link Binary 不同的是: 多了 libxml2.tbd 支持 html 标签树的动态库

Embed Pods 不同的是: After:SwiftyBeaver, 与 Before:RxSwift

After Compile Source 394 Before Compile Source 332

在 pre-main 阶段 真机比较主线程耗时相差不多  
说明下:  
main 函数启动之前耗时，对于一般的小型 APP 来说，影响微乎其微，但对于大型 APP(动态库超过 50 或二进制文件超过 30MB) 来说，就会变得很明显  
一般来说 main() 函数之前耗时 不宜超过 400 毫秒，之前与之后整体时间不宜超过 20 秒，如果超过 20 秒，系统会关闭进程，无法启动 APP

main 函数之前经历的递归加载 dyld 动态链接库到 runtime 加载每个类的 load(不管你是否用到都会加载, 所以要删除程序中没有用的的类)  
如果用模拟器测试这块比较耗时, 毕竟模拟器与真机各方面性能都不同  
所以 pre-main 这阶段不必优化

2 main() 函数之后至 applicationWillFinishLaunching 完成

同等条件下冷启动 到 didFinished 方法开始  
APP 启动时间耗时，从 mian 函数开始到 didFinishLaunchingWithOptions 方法：1.0658990144729614。

同等条件下冷启动开始到 didFinished 方法结束  
APP 启动时间耗时，从 mian 函数开始到 didFinishLaunchingWithOptions 方法：2.2800480127334595。

同等条件下冷启动 到 didFinished 调用的某些方法进行异步操作  
APP 启动时间耗时，从 mian 函数开始到 didFinishLaunchingWithOptions 方法：1.1382160186767578。

总结 异步调用方法对于耗时效果还是可见的  
优化 applicationWillFinishLaunching（将不需要马上在此方法中执行的代码延后执行）  
优化 rootViewController 加载（适当将某一级的 childViewController 或 subviews 延后加载）

main() 被调用之后，didFinishLaunchingWithOptions 阶段，App 会进行必要的初始化操作，而 viewDidAppear 执行结束之前则是做了首页内容的加载和显示。  
关于 App 的初始化，除了统计、日志这种须要在 App 一启动就配置的事件，有一些配置也可以考虑延迟加载  
延迟执行部分业务逻辑和 UI 配置；  
 延迟加载 / 懒加载部分视图；  
 避免首屏加载时大量的本地 / 网络数据读取；(这里大量网络数据要请求等待显示, 希望后端接口返回快些)

异步操作不影响耗时

3, 4 所以耗时处理主要看  
优化 applicationWillFinishLaunching（将不需要马上在此方法中执行的代码延后执行）  
优化 rootViewController 加载（适当将某一级的 childViewController 或 subviews 延后加载）

#### 总结一下
APP的启动由dyld主导，将可执行文件加载到内存，顺便加载所有依赖的动态库
并由runtime负责加载成objc定义的结构
所有初始化工作结束后，dyld就会调用main函数
接下来就是UIApplicationMain函数，AppDelegate的application:didFinishLaunchingWithOptions:方法
