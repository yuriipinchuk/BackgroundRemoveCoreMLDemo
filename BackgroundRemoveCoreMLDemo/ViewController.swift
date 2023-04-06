//
//  ViewController.swift
//  BackgroundRemoveCoreMLDemo
//
//  Created by Yurii Pinchuk on 4/5/23.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {

    let inputImage = UIImage(named: "test1")!
    
    @IBOutlet weak var ivResult: UIImageView!
    @IBOutlet weak var ivOrg: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ivOrg.image = UIImage(named: "test1")
    }

    @IBAction func onRemoveTap(_ sender: Any) {
        runVisionRequest()
    }
        
    func runVisionRequest() {
            
            guard let model = try? VNCoreMLModel(for: DeepLabV3(configuration: .init()).model)
            else { return }
            
            let request = VNCoreMLRequest(model: model, completionHandler: visionRequestDidComplete)
            request.imageCropAndScaleOption = .scaleFill
            DispatchQueue.global().async {

                let handler = VNImageRequestHandler(cgImage: self.inputImage.cgImage!, options: [:])
                
                do {
                    try handler.perform([request])
                }catch {
                    print(error)
                }
            }
        }
        
    func maskInputImage(_ outputImage: UIImage){
            let bgImage = UIImage.imageFromColor(color: .orange, size: self.inputImage.size, scale: self.inputImage.scale)!

            let beginImage = CIImage(cgImage: inputImage.cgImage!)
            let background = CIImage(cgImage: bgImage.cgImage!)
            let mask = CIImage(cgImage: outputImage.cgImage!)

            if let compositeImage = CIFilter(name: "CIBlendWithMask", parameters: [
                                            kCIInputImageKey: beginImage,
                                            kCIInputBackgroundImageKey:background,
                                            kCIInputMaskImageKey:mask])?.outputImage
            {


                let ciContext = CIContext(options: nil)

                let filteredImageRef = ciContext.createCGImage(compositeImage, from: compositeImage.extent)

                self.ivResult.image = UIImage(cgImage: filteredImageRef!)
                
            }
        }

        func visionRequestDidComplete(request: VNRequest, error: Error?) {
                DispatchQueue.main.async {
                    if let observations = request.results as? [VNCoreMLFeatureValueObservation],
                        let segmentationmap = observations.first?.featureValue.multiArrayValue {
                        
                        let segmentationMask = segmentationmap.image(min: 0, max: 1)

                        let imgMask = segmentationMask!.resizedImage(for: self.inputImage.size)!
                        self.maskInputImage(imgMask)
                    }
                }
        }
}

extension UIImage {
    class func imageFromColor(color: UIColor, size: CGSize=CGSize(width: 1, height: 1), scale: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func resizedImage(for size: CGSize) -> UIImage? {
            let image = self.cgImage
            print(size)
            let context = CGContext(data: nil,
                                    width: Int(size.width),
                                    height: Int(size.height),
                                    bitsPerComponent: image!.bitsPerComponent,
                                    bytesPerRow: Int(size.width),
                                    space: image?.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
                                    bitmapInfo: image!.bitmapInfo.rawValue)
            context?.interpolationQuality = .high
            context?.draw(image!, in: CGRect(origin: .zero, size: size))

            guard let scaledImage = context?.makeImage() else { return nil }

            return UIImage(cgImage: scaledImage)
    }
    
}
