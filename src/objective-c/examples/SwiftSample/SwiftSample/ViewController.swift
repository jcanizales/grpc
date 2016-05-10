//
//  ViewController.swift
//  SwiftSample
//
//  Created by Jorge Canizalez Diaz on 5/9/16.
//  Copyright © 2016 gRPC. All rights reserved.
//

import UIKit

import GRPCClient
import RxSwift

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    NSLog("Hi from Swift!")

    var call = GRPCCall.init(host: "grpc-test.sandbox.googleapis.com",
                             path: "grpc.testing.TestService/EmptyCall",
                             requestsWriter: GRXWriter.init(container: []))
    call.startWithWriteable(GRXWriteable.init(singleHandler: { (response, error) in
      if let response = response {
        print(response)
      } else {
        print(error)
      }
    }))

    var observable : Observable<String> = Observable.empty()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

