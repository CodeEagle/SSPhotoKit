//
//  ViewController.swift
//  SSPhotoKit
//
//  Created by CodeEagle on 07/23/2015.
//  Copyright (c) 2015 CodeEagle. All rights reserved.
//

import UIKit
class ViewController: UIViewController {
    let photoKit = SSPhotoKit()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        photoKit.maximumNumberOfSelection = 4
        photoKit.showPickerIn(self, done: { (results) -> () in
            debugPrint(results.count)
        })
    }
}

