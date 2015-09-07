//
//  UIImageView+AFNetworking.swift
//
//  Created by Pham Hoang Le on 23/2/15.
//  Copyright (c) 2015 Pham Hoang Le. All rights reserved.
//

import UIKit

@objc public protocol AFImageCacheProtocol:class{
    func cachedImageForRequest(request:NSURLRequest) -> UIImage?
    func cacheImage(image:UIImage, forRequest request:NSURLRequest);
}

extension UIImageView {
    private struct AssociatedKeys {
        static var SharedImageCache = "SharedImageCache"
        static var RequestImageOperation = "RequestImageOperation"
        static var URLRequestImage = "UrlRequestImage"
    }
    
    public class func setSharedImageCache(cache:AFImageCacheProtocol?) {
        objc_setAssociatedObject(self, &AssociatedKeys.SharedImageCache, cache, .OBJC_ASSOCIATION_RETAIN)
    }
    
    public class func sharedImageCache() -> AFImageCacheProtocol {
        struct Static {
            static var token : dispatch_once_t = 0
            static var defaultImageCache:AFImageCache?
        }
        
        dispatch_once(&Static.token, { () -> Void in
            Static.defaultImageCache = AFImageCache()
            NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidReceiveMemoryWarningNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (NSNotification) -> Void in
                Static.defaultImageCache!.removeAllObjects()
            }
        })
        return objc_getAssociatedObject(self, &AssociatedKeys.SharedImageCache) as? AFImageCacheProtocol ?? Static.defaultImageCache!
    }
    
    private class func af_sharedImageRequestOperationQueue() -> NSOperationQueue {
        struct Static {
            static var token:dispatch_once_t = 0
            static var queue:NSOperationQueue?
        }
        
        dispatch_once(&Static.token, { () -> Void in
            Static.queue = NSOperationQueue()
            Static.queue!.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
        })
        return Static.queue!
    }
    
    private var af_requestImageOperation:(operation:NSOperation?, request: NSURLRequest?) {
        get {
            let operation:NSOperation? = objc_getAssociatedObject(self, &AssociatedKeys.RequestImageOperation) as? NSOperation
            let request:NSURLRequest? = objc_getAssociatedObject(self, &AssociatedKeys.URLRequestImage) as? NSURLRequest
            return (operation, request)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.RequestImageOperation, newValue.operation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, &AssociatedKeys.URLRequestImage, newValue.request, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func setImageWithUrl(url:NSURL, placeHolderImage:UIImage? = nil) {
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        self.setImageWithUrlRequest(request, placeHolderImage: placeHolderImage, success: nil, failure: nil)
    }
    
    public func setImageWithUrlRequest(request:NSURLRequest, placeHolderImage:UIImage? = nil,
		success:((request:NSURLRequest?, response:NSURLResponse?, image:UIImage, fromCache:Bool) -> Void)?,
        failure:((request:NSURLRequest?, response:NSURLResponse?, error:NSError) -> Void)?)
    {
        self.cancelImageRequestOperation()
        
        if let cachedImage = UIImageView.sharedImageCache().cachedImageForRequest(request) {
            if success != nil {
				success!(request: nil, response:nil, image: cachedImage, fromCache:true)
            }
            else {
                self.image = cachedImage
            }
            
            return
        }
        
        if placeHolderImage != nil {
            self.image = placeHolderImage
        }
        
        self.af_requestImageOperation = (NSBlockOperation(block: { () -> Void in
            var response:NSURLResponse?
            do {
                let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if request.URL!.isEqual(self.af_requestImageOperation.request?.URL) {
                        let image:UIImage? = UIImage(data: data)
                        if image != nil {
                            if success != nil {
                                success!(request: request, response: response, image: image!, fromCache:false)
                            }
                            else {
                                self.image = image!
                            }
                            UIImageView.sharedImageCache().cacheImage(image!, forRequest: request)
                        }
                        
                        self.af_requestImageOperation = (nil, nil)
                    }
                })
            }
            catch {
                if failure != nil {
                    failure!(request: request, response:response, error: error as NSError)
                }
            }
        }), request: request)
        
        UIImageView.af_sharedImageRequestOperationQueue().addOperation(self.af_requestImageOperation.operation!)
    }
    
    private func cancelImageRequestOperation() {
        self.af_requestImageOperation.operation?.cancel()
        self.af_requestImageOperation = (nil, nil)
    }
}

func AFImageCacheKeyFromURLRequest(request:NSURLRequest) -> String {
    return request.URL!.absoluteString
}

class AFImageCache: NSCache, AFImageCacheProtocol {
    func cachedImageForRequest(request: NSURLRequest) -> UIImage? {
        switch request.cachePolicy {
        case NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
        NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData:
            return nil
        default:
            break
        }
        
        return self.objectForKey(AFImageCacheKeyFromURLRequest(request)) as? UIImage
    }
    
    func cacheImage(image: UIImage, forRequest request: NSURLRequest) {
        self.setObject(image, forKey: AFImageCacheKeyFromURLRequest(request))
    }
}

