//
//  Button.swift
//  Tusk
//
//  Created by Patrick Perini on 8/24/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class Button: UIButton {
    private var _preTouchAlpha: CGFloat = 0.0
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self._preTouchAlpha = self.alpha
        self.alpha = self._preTouchAlpha - 0.4
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.alpha = self._preTouchAlpha
    }
}
