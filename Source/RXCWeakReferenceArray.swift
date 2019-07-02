//
//  RXCWeakReferenceArray.swift
//  RXCPageViewControllerExample
//
//  Created by ruixingchen on 7/1/19.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import Foundation

/*
 a convenience implementation for weak reference array, supports Sequence and Generic Type
*/

public class RXCWeakReferenceArray<Element>: Sequence {

    public typealias Iterator = RXCWeakReferenceArray.RXCIterator<Element>

    ///pointer array that really stores objects
    private let pointerArray:NSPointerArray

    ///cycle of operation to compact, zero or below means never
    public var compactOperationCycle:Int = 24
    private var operationCount:Int = 0

    var threadSafe:Bool = false

    private func lock() {
        objc_sync_enter(self.pointerArray)
    }

    private func unlock() {
        objc_sync_exit(self.pointerArray)
    }

    private init(option:NSPointerFunctions.Options = .weakMemory) {
        self.pointerArray = NSPointerArray(options: option)
    }

    public convenience init(option:NSPointerFunctions.Options = .weakMemory, compactCycle:Int=10) {
        self.init(option: option)
        self.compactOperationCycle = compactCycle
    }

    //MARK: - C

    public func add(_ object:Element?){
        let safe = self.threadSafe
        if safe {self.lock()}
        defer {
            if safe {self.unlock()}
        }
        if object == nil {
            self.pointerArray.addPointer(nil)
        }else{
            let pointer:UnsafeMutableRawPointer = self.pointerConvert(object as AnyObject)
            self.pointerArray.addPointer(pointer)
        }
        self.increaseOperationCount()
    }

    public func add(contenOf newElements:[Element]){
        for i in newElements {
            self.add(i)
        }
    }

    public func insert(_ object:Element?, at index:Int){
        let safe = self.threadSafe
        if safe {self.lock()}
        defer {
            if safe {self.unlock()}
        }
        if object == nil {
            self.pointerArray.insertPointer(nil, at: index)
        }else{
            let pointer:UnsafeMutableRawPointer = self.pointerConvert(object as AnyObject)
            self.pointerArray.insertPointer(pointer, at: index)
        }
        self.increaseOperationCount()
    }

    //MARK: - R

    public var count:Int {return self.pointerArray.count}

    public var isEmpty:Bool {return self.count == 0}

    public func object(at index:Int) ->Element? {
        guard let pointer:UnsafeMutableRawPointer = self.pointerArray.pointer(at: index) else {return nil}
        return Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue() as? Element
    }

    public func safeGet(at index:Int) ->Element? {
        if index < 0 || index >= self.pointerArray.count {
            return nil
        }
        return self.object(at: index)
    }

    public var first:Element? {
        return self.safeGet(at: 0)
    }

    public var last:Element? {
        return self.safeGet(at: self.count-1)
    }

    public func firstIndex(where predicate: (Element) throws ->Bool)rethrows -> Int?{
        let safe = self.threadSafe
        if safe {self.lock()}
        defer {
            if safe {self.unlock()}
        }
        do {
            for i in 0..<self.count {
                if let object = self.safeGet(at: i), try predicate(object) {
                    return i
                }
            }
        }catch {
            throw error
        }
        return nil
    }

    public func lastIndex(where predicate: (Element) throws ->Bool)rethrows -> Int?{
        let safe = self.threadSafe
        if safe {self.lock()}
        defer {
            if safe {self.unlock()}
        }
        do {
            for i in (0..<self.count).reversed() {
                if let object = self.safeGet(at: i), try predicate(object) {
                    return i
                }
            }
        }catch {
            throw error
        }
        return nil
    }

    public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        let safe = self.threadSafe
        if safe {self.lock()}
        defer {
            if safe {self.unlock()}
        }
        do {
            for i in 0..<self.count {
                if let object = self.safeGet(at: i), try predicate(object) {
                    return object
                }
            }
        }catch {
            throw error
        }
        return nil
    }

    public func last(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        let safe = self.threadSafe
        if safe {self.lock()}
        defer {
            if safe {self.unlock()}
        }
        do {
            for i in (0..<self.count).reversed() {
                if let object = self.safeGet(at: i), try predicate(object) {
                    return object
                }
            }
        }catch {
            throw error
        }
        return nil
    }

    //O(n) 😂
    public __consuming func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
        let safe = self.threadSafe
        if safe {self.lock()}
        defer {
            if safe {self.unlock()}
        }
        var filtered:[Element] = []
        do {
            for i in 0..<self.count {
                if let object = self.safeGet(at: i), try isIncluded(object) {
                    filtered.append(object)
                }
            }
        }catch {
            throw error
        }
        return filtered
    }

    ///O(n) 😂
    public func contains(where predicate: (Element) throws -> Bool) rethrows -> Bool {
        let safe = self.threadSafe
        if safe {self.lock()}
        defer {
            if safe {self.unlock()}
        }
        do {
            for i in 0..<self.count {
                if let object = self.safeGet(at: i), try predicate(object) {
                    return true
                }
            }
        }catch {
            throw error
        }
        return false
    }

    ///only compare pointer address
    public func contains(_ element:Element)->Bool {
        let safe = self.threadSafe
        if safe {self.lock()}
        defer {
            if safe {self.unlock()}
        }
        for i in 0..<self.count {
            if let object = self.safeGet(at: i) {
                return (object as AnyObject) === (element as AnyObject)
            }
        }
        return false
    }

    //MARK: - U
    public func replace(at index:Int, with object:Element?) {
        let safe = self.threadSafe
        if safe {self.lock()}
        defer {
            if safe {self.unlock()}
        }
        if object == nil {
            self.pointerArray.replacePointer(at: index, withPointer: nil)
        }else{
            let pointer:UnsafeMutableRawPointer = self.pointerConvert(object as AnyObject)
            self.pointerArray.replacePointer(at: index, withPointer: pointer)
        }
        self.increaseOperationCount()
    }

    //MARK: - D

    public func removeAll(where predicate:(Element)->Bool){
        let safe = self.threadSafe
        if safe {self.lock()}
        defer {
            if safe {self.unlock()}
        }
        for i in 0..<self.count {
            if let object = self.safeGet(at: i), predicate(object) {
                self.remove(at: i)
            }
        }
    }

    public func removeAll(){
        self.removeAll(where: {_ in return true})
    }

    public func remove(at index:Int) {
        let safe = self.threadSafe
        if safe {self.lock()}
        defer {
            if safe {self.unlock()}
        }
        self.pointerArray.removePointer(at: index)
        self.increaseOperationCount()
    }

    //MARK: - Other

    public func compact(){
        let safe = self.threadSafe
        if safe {self.lock()}
        defer {
            if safe {self.unlock()}
        }
        #if (DEBUG || debug)
        let countBefore:Int = self.count
        #endif
        self.pointerArray.addPointer(nil)
        self.pointerArray.compact()
        #if (DEBUG || debug)
        print("RXCWeakReferenceArray: compact complete, before:\(countBefore), after:\(self.count)")
        #endif
    }

    public subscript(index:Int)->Element? {
        get {
            return self.safeGet(at: index)
        }
        set {
            self.replace(at: index, with: newValue)
        }
    }

    ///increase and compact if needed
    private func increaseOperationCount(){
        if compactOperationCycle > 0 {
            self.operationCount += 1
            if self.operationCount > self.compactOperationCycle {
                self.compact()
                self.operationCount = 0
            }
        }
    }

    ///convert an AnyObject to pointer
    private func pointerConvert(_ object:AnyObject)->UnsafeMutableRawPointer{
        return Unmanaged.passUnretained(object).toOpaque()
    }

    //MARK: - Sequence

    public func makeIterator() -> RXCWeakReferenceArray.RXCIterator<Element> {
        return RXCWeakReferenceArray.RXCIterator(self)
    }

}

public extension RXCWeakReferenceArray {

    struct RXCIterator<IT>: IteratorProtocol {

        public typealias Element = IT

        private var index:Int = 0
        private let array:RXCWeakReferenceArray<IT>

        init(_ array:RXCWeakReferenceArray<IT>) {
            self.array = array
        }

        ///look from current to end
        ///weak array may contains nil, so we have to look to the end
        public mutating func next() -> Element? {
            let object:Element? = self.array.safeGet(at: index)
            if object == nil && index < self.array.count {
                index += 1
                return next()
            } else {
                index += 1
                return object
            }
        }

    }

}

