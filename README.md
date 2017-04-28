# Swift-UIImageView-AFNetworking
Swift version of UIImageView+AFNetworking. 

This is the Swift version of UIImageView+AFNetworking from the famous AFNetworking library. 
Just drop the file into your project and you can start using it !

<h2><b>Note</b></h2>
This file doesn't use anything from AFNetworking or Alamofire. There's no need to use those libraries in your project. I name it this way because it's inspired by the Objc version from AFNetworking

<h2><b>Usage</b></h2>

```objc
public func setImageWithUrl(url:NSURL, placeHolderImage:UIImage? = nil);

public func setImageWithUrlRequest(request:NSURLRequest, placeHolderImage:UIImage? = nil,
        success:((request:NSURLRequest?, response:NSURLResponse?, image:UIImage) -> Void)?,
        failure:((request:NSURLRequest?, response:NSURLResponse?, error:NSError) -> Void)?)
```

