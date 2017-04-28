//
//  ViewController.swift
//  SampleProject
//
//  Created by Pham Hoang Le on 3/11/16.
//  Copyright © 2016 Pham Hoang Le. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let imageView = UIImageView(frame: view.bounds)
        imageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        view.addSubview(imageView)
        
        let url = NSURL(string: "https://s-media-cache-ak0.pinimg.com/564x/a2/b8/e4/a2b8e40d4175b0a7c3e903e913d54cfc.jpg")
        imageView.setImageWithUrl(url!)
    }
}

