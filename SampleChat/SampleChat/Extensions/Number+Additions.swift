//
//  Extensions.swift
//  SampleChat
//
//  Created by David on 05.06.2024.
//

import UIKit
import ConnectyCube

extension Int32 {
    /// returns Integer equivalent of this instance.
    /// created as a shorthand to avoid casting to Int.
    func asInt() -> Int {
        return Int(self)
    }
}

extension Int32 {
    /// converts this Integer to KotlinInt
    func asXPInt() -> KotlinInt {
        return KotlinInt(integerLiteral: Int(self))
    }
}

extension Int32 {
    /// converts this Integer to KotlinInt
    func asXPLong() -> KotlinLong {
        return KotlinLong(integerLiteral: Int(self))
    }
}

extension Int {
    /// converts this Integer to KotlinInt
    func asXPLong() -> KotlinLong {
        return KotlinLong(integerLiteral: Int(self))
    }
}

extension NSMutableArray {
    func asXPIntArray() -> [KotlinInt] {
        return self as! [KotlinInt]
    }
}

extension Array where Element == Int {
    /// Returns true if at least one element matches the given predicate.
    func any(_ array: [Int]) -> Bool {
        return self.contains{ array.contains($0)}
    }
}
