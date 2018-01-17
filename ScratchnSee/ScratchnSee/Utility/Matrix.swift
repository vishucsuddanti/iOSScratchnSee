//
// Scratch and See
//
// The project provides en effect when the user swipes the finger over one texture
// and by swiping reveals the texture underneath it. The effect can be applied for
// scratch-card action or wiping a misted glass.
//
// Copyright (C) 2012 http://moqod.com Andrew Kopanev <andrew@moqod.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
import UIKit

struct MySize {
    var x: size_t = 0
    var y: size_t = 0
}

class Matrix: NSObject {
    var vl = CChar()
    var data: [CChar]
    
    public private(set) var max = MySize()
    
    init(maxX x: size_t, maxY y: size_t) {
        self.data = [CChar].init(repeating: CChar(), count: (x*y*10))
        self.max = MySize(x: x, y: y)
        super.init()
    }
    
    convenience init(max maxCoords: MySize) {
        self.init(maxX: maxCoords.x, maxY: maxCoords.y)
    }
    
    func valueForCoordinates(x: size_t, y:size_t) -> CChar {
        let index = x + self.max.x * y
        print("index =\(index)")
        if (index >= (self.max.x * self.max.y)) {
            return 1
        } else {
            return self.data[index]
        }
    }
    
    func setCharacterValue(value: CChar, x:size_t, y:size_t) {
        let index = x + self.max.x * y
        if (index < self.max.x * self.max.y) {
            self.data[index] = value
        }
    }
    
    func fill(withValue value: CChar) {
        var temp = data
        for i in 0..<(self.max.x * self.max.y) {
            temp[i] = value + 1
        }
    }
    
    deinit {
        self.data.removeAll()
    }
    
}

