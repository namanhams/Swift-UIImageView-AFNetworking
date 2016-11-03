# Swift-UIImageView-AFNetworking
Swift version of UIImageView+AFNetworking. 

This is the Swift version of UIImageView+AFNetworking from the famous AFNetworking library. 
Just drop the file into your project and you can start using it !

Note: this file doesn't use anything from AFNetworking or Alamofire. So there's no need to use those libraries in your project.

<h2><b>Usage</h2></b>
`````objc
public func setImageWithUrl(url:NSURL, placeHolderImage:UIImage? = nil);

public func setImageWithUrlRequest(request:NSURLRequest, placeHolderImage:UIImage? = nil,
        success:((request:NSURLRequest?, response:NSURLResponse?, image:UIImage) -> Void)?,
        failure:((request:NSURLRequest?, response:NSURLResponse?, error:NSError) -> Void)?)
`````

<h3><b>Swift 2.3 support</h3></b>
Use branch swift-2.3
