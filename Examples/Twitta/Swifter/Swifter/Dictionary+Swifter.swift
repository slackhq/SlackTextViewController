//
//  Dictionary+Swifter.swift
//  Swifter
//
//  Copyright (c) 2014 Matt Donnelly.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

extension Dictionary {

    func filter(predicate: Element -> Bool) -> Dictionary {
        var filteredDictionary = Dictionary()

        for (key, value) in self {
            if predicate(key, value) {
                filteredDictionary[key] = value
            }
        }

        return filteredDictionary
    }

    func queryStringWithEncoding() -> String {
        var parts = [String]()

        for (key, value) in self {
            let keyString: String = "\(key)"
            let valueString: String = "\(value)"
            let query: String = "\(keyString)=\(valueString)"
            parts.append(query)
        }

        return join("&", parts)
    }

    func urlEncodedQueryStringWithEncoding(encoding: NSStringEncoding) -> String {
        var parts = [String]()

        for (key, value) in self {
            let keyString: String = "\(key)".urlEncodedStringWithEncoding(encoding)
            let valueString: String = "\(value)".urlEncodedStringWithEncoding(encoding)
            let query: String = "\(keyString)=\(valueString)"
            parts.append(query)
        }

        return join("&", parts)
    }
    
}

infix operator +| {}
func +| <K,V>(left: Dictionary<K,V>, right: Dictionary<K,V>) -> Dictionary<K,V> {
    var map = Dictionary<K,V>()
    for (k, v) in left {
        map[k] = v
    }
    for (k, v) in right {
        map[k] = v
    }
    return map
}
