//
//  UIImageView+AFNetworking.swift
//
//  Created by Pham Hoang Le on 23/2/15.
//  Copyright (c) 2015 Pham Hoang Le. All rights reserved.
//

import UIKit

@objc public protocol AFImageCacheProtocol:class{
    func cachedImageForRequest(_ request:URLRequest) -> UIImage?
    func cacheImage(_ image:UIImage, forRequest request:URLRequest);
}

extension UIImageView {
    fileprivate struct AssociatedKeys {
        static var SharedImageCache = "SharedImageCache"
        static var RequestImageOperation = "RequestImageOperation"
        static var URLRequestImage = "UrlRequestImage"
    }
    
    public class func setSharedImageCache(_ cache:AFImageCacheProtocol?) {
        objc_setAssociatedObject(self, &AssociatedKeys.SharedImageCache, cache, .OBJC_ASSOCIATION_RETAIN)
    }
    
    public class func sharedImageCache() -> AFImageCacheProtocol {
        struct Static {
            static var defaultImageCache:AFImageCache? = {
                NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil, queue: OperationQueue.main) { (NSNotification) -> Void in
                    Static.defaultImageCache!.removeAllObjects()
                }
                return AFImageCache()
            }()
        }
        
        return objc_getAssociatedObject(self, &AssociatedKeys.SharedImageCache) as? AFImageCacheProtocol ?? Static.defaultImageCache!
    }
    
    fileprivate class func af_sharedImageRequestOperationQueue() -> OperationQueue {
        struct Static {
            static var queue:OperationQueue? = {
                let queue = OperationQueue()
                queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
                return queue
            }()
        }
        
        return Static.queue!
    }
    
    fileprivate var af_requestImageOperation:(operation:Operation?, request: URLRequest?) {
        get {
            let operation:Operation? = objc_getAssociatedObject(self, &AssociatedKeys.RequestImageOperation) as? Operation
            let request:URLRequest? = objc_getAssociatedObject(self, &AssociatedKeys.URLRequestImage) as? URLRequest
            return (operation, request)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.RequestImageOperation, newValue.operation, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, &AssociatedKeys.URLRequestImage, newValue.request, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func setImageWithUrl(_ url:URL, placeHolderImage:UIImage? = nil) {
        let request:NSMutableURLRequest = NSMutableURLRequest(url: url)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        self.setImageWithUrlRequest(request as URLRequest, placeHolderImage: placeHolderImage, success: nil, failure: nil)
    }
    
    public func setImageWithUrlRequest(_ request:URLRequest, placeHolderImage:UIImage? = nil,
		success:((_ request:URLRequest?, _ response:URLResponse?, _ image:UIImage, _ fromCache:Bool) -> Void)?,
        failure:((_ request:URLRequest?, _ response:URLResponse?, _ error:NSError) -> Void)?)
    {
        self.cancelImageRequestOperation()
        
        if let cachedImage = UIImageView.sharedImageCache().cachedImageForRequest(request) {
            if success != nil {
				success!(nil, nil, cachedImage, true)
            }
            else {
                self.image = cachedImage
            }
            
            return
        }
        
        if placeHolderImage != nil {
            self.image = placeHolderImage
        }
        
        self.af_requestImageOperation = (BlockOperation(block: { () -> Void in
            var response:URLResponse?
            do {
                let data = try NSURLConnection.sendSynchronousRequest(request, returning: &response)
                DispatchQueue.main.async(execute: { () -> Void in
                    if request.url! == self.af_requestImageOperation.request?.url {
                        let image:UIImage? = UIImage(data: data)
                        if image != nil {
                            if success != nil {
                                success!(request, response, image!, false)
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
                    failure!(request, response, error as NSError)
                }
            }
        }), request: request)
        
        UIImageView.af_sharedImageRequestOperationQueue().addOperation(self.af_requestImageOperation.operation!)
    }
    
    fileprivate func cancelImageRequestOperation() {
        self.af_requestImageOperation.operation?.cancel()
        self.af_requestImageOperation = (nil, nil)
    }
}

func AFImageCacheKeyFromURLRequest(_ request:URLRequest) -> String {
    return request.url!.absoluteString
}

class AFImageCache: NSCache<AnyObject, AnyObject>, AFImageCacheProtocol {
    func cachedImageForRequest(_ request: URLRequest) -> UIImage? {
        switch request.cachePolicy {
        case NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData,
        NSURLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData:
            return nil
        default:
            break
        }
        
        return self.object(forKey: AFImageCacheKeyFromURLRequest(request) as AnyObject) as? UIImage
    }
    
    func cacheImage(_ image: UIImage, forRequest request: URLRequest) {
        self.setObject(image, forKey: AFImageCacheKeyFromURLRequest(request) as AnyObject)
    }
}

