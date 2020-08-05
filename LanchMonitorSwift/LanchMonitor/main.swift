//
//  main.swift
//  LanchMonitor
//
//  Created by andyccc on 2021/8/5.
//

import Foundation
import UIKit

var preMainTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

//UIApplicationMain(CommandLine.argc, UnsafeMutablePointer(CommandLine.unsafeArgv), nil, NSStringFromClass(AppDelegate.self))


class MyApplication: UIApplication {
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        print("Event sent:\(event)")
    }
}

UIApplicationMain(CommandLine.argc, UnsafeMutablePointer(CommandLine.unsafeArgv), NSStringFromClass(MyApplication.self), NSStringFromClass(AppDelegate.self))

/*
 UIApplicationMain(<#T##argc: Int32##Int32#>, <#T##argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>##UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>#>, <#T##principalClassName: String?##String?#>, <#T##delegateClassName: String?##String?#>)
 
 
 这里延伸出来的32位
 
 1        0
 2        1
 3      2
 8      3
 16      4
 32       5
 64       6
 128       7
 256       8
 521       9
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
