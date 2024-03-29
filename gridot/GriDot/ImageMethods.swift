//
//  ImageMethods.swift
//  spriteMaker
//
//  Created by 박찬울 on 2021/09/24.
//

import UIKit

func flipImageVertically(originalImage: CGImage) -> CGImage? {
    let size = CGSize(
        width: originalImage.width,
        height: originalImage.height
    )

    guard let context = CGContext(
        data: nil,
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
       return nil
    }
    
    let flipVertical: CGAffineTransform = CGAffineTransform(
        a: 1, b: 0, c: 0, d: -1,
        tx: 0,
        ty: size.height
    )

    UIGraphicsPushContext(context)

    context.concatenate(flipVertical)
    context.draw(originalImage, in: CGRect(origin: .zero, size: size))

    UIGraphicsPopContext()

    return context.makeImage()
}

func flipImageHorizontal(originalImage: CGImage) -> CGImage? {
    let size = CGSize(
        width: originalImage.width,
        height: originalImage.height
    )

    guard let context = CGContext(
        data: nil,
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
       return nil
    }
    
    let flipHorizontal: CGAffineTransform = CGAffineTransform(
        a: 1, b: 0, c: 0, d: -1,
        tx: size.width,
        ty: 0
    )

    UIGraphicsPushContext(context)

    context.concatenate(flipHorizontal)
    context.draw(originalImage, in: CGRect(origin: .zero, size: size))

    UIGraphicsPopContext()

    return context.makeImage()
}

func flipImageVertically(originalImage: UIImage) -> UIImage {
    let tempImageView: UIImageView = UIImageView(image: originalImage)
    UIGraphicsBeginImageContext(tempImageView.frame.size)
    guard let context: CGContext = UIGraphicsGetCurrentContext() else { return originalImage }
    let flipVertical: CGAffineTransform = CGAffineTransform(
        a: 1, b: 0, c: 0, d: -1,
        tx: 0,
        ty: tempImageView.frame.size.height
    )

    context.concatenate(flipVertical)
//    tempImageView.tintColor = UIColor.white
    tempImageView.layer.render(in: context)

    guard let flippedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() else {
        return UIImage(named: "empty")!
    }
    UIGraphicsEndImageContext()

    return flippedImage
}

func flipImageHorizontal(originalImage: UIImage) -> UIImage {
    let tempImageView: UIImageView = UIImageView(image: originalImage)
    UIGraphicsBeginImageContext(tempImageView.frame.size)
    let context: CGContext = UIGraphicsGetCurrentContext()!
    let flipHorizontal: CGAffineTransform = CGAffineTransform(
        a: -1, b: 0, c: 0, d: 1,
        tx: tempImageView.frame.size.width,
        ty: 0
    )
    context.concatenate(flipHorizontal)
    tempImageView.tintColor = UIColor.black
    tempImageView.layer.render(in: context)

    let flippedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()

    return flippedImage
}

func getColorBasedOnColorBrightness(_ color: UIColor) -> UIColor {
    if (getBrightness(color) > 0.7) {
        return UIColor.darkGray
    } else {
        return UIColor.white
    }
}

func getBrightness(_ uicolor: UIColor) -> CGFloat {
    var hue: CGFloat = 0
    var sat: CGFloat = 0
    var bri: CGFloat = 0
    var alpha: CGFloat = 0
    
    uicolor.getHue(
        &hue,
        saturation: &sat,
        brightness: &bri,
        alpha: &alpha
    )
    return bri
}

func drawGridPixels(_ context: CGContext, grid: [String : [Int : [Int]]], pixelWidth: Double) {
    context.setLineWidth(0.2)
    
    for color in grid.keys {
        guard let locations = grid[color] else { return }
        for x in locations.keys {
            guard let locationX = locations[x] else { return }
            for y in locationX {
                guard let uiColor = color.uicolor else { continue }
                let xlocation = Double(x) * pixelWidth
                let ylocation = Double(y) * pixelWidth
                let rectangle = CGRect(x: xlocation, y: ylocation, width: pixelWidth, height: pixelWidth)
                
                context.setFillColor(uiColor.cgColor)
                context.setStrokeColor(uiColor.cgColor)
                context.addRect(rectangle)
                context.drawPath(using: .fillStroke)
            }
        }
    }
    context.strokePath()
}

func drawGridPixelsInt32(_ context: CGContext, _ grid: [Int], _ pixelWidth: Double) {
    context.setLineWidth(0.2)
    
    for y in 0..<16 {
        for x in 0..<16 {
            guard let index = getGridIndex(CGPoint(x: x, y: y)) else { continue }
            if (grid.count - 1 < index) { continue }
            if (grid[index] != -1) {
                guard let hex = transIntToHex(grid[index]) else { continue }
                guard let uiColor = hex.uicolor else { continue }
                context.setFillColor(uiColor.cgColor)
                context.setStrokeColor(uiColor.cgColor)
                let xlocation = Double(x) * pixelWidth
                let ylocation = Double(y) * pixelWidth
                let rectangle = CGRect(
                    x: xlocation, y: ylocation,
                    width: pixelWidth, height: pixelWidth
                )
                context.addRect(rectangle)
                context.drawPath(using: .fillStroke)
            }
        }
    }
    context.strokePath()
}

func transImageToGrid(image: UIImage, start: CGPoint, _ widthOfPixel: Int? = 1, _ numsOfPixel: Int? = 16) -> [Int] {
    let grid = Grid()
    let width = widthOfPixel!
    
    let centerPos = (width - (Int(image.cgImage!.width) % width)) / 2
    let x = Int(start.x)
    let y = Int(start.y)
    
    for j in 0..<numsOfPixel! {
        for i in 0..<numsOfPixel! {
            let x = centerPos + (i * width) + (x * numsOfPixel!)
            let y = centerPos + (j * width) + (y * numsOfPixel!)
            if (x > Int(image.cgImage!.width)) { continue }
            if (y > Int(image.cgImage!.height)) { continue }
            
            guard let color = image.getPixelColor(pos: CGPoint(x: x, y: y)) else { return [] }
            
            if (color.cgColor.alpha != 0) {
                grid.addLocation(color.hexa!, CGPoint(x: i, y: j))
            }
        }
    }
    return grid.data
}

extension UIImage {
    convenience init? (url: URL) {
        if let data = try? Data(contentsOf: url) {
            self.init(data: data)
        } else {
            return nil
        }
    }
    
    func transImageToGrid(start: CGPoint, _ widthOfPixel: Double? = 1, _ numsOfPixel: Int? = 16) -> [Int] {
        let grid = Grid()
        let width = Int(widthOfPixel!) - 1
        let x = Int(start.x), y = Int(start.y);
        
        for i in 0..<numsOfPixel! {
            for j in 0..<numsOfPixel! {
                let colorX = (i * width) + (x * numsOfPixel!)
                let colorY = (j * width) + (y * numsOfPixel!)
                if (self.size.width < CGFloat(colorX) || self.size.height < CGFloat(colorY)) { continue }
                guard let color = self.getPixelColor(pos: CGPoint(x: colorX, y: colorY)) else { continue }
                if (color.cgColor.alpha != 0) {
                    grid.addLocation(color.hexa!, CGPoint(x: i, y: j))
                }
            }
        }
        return grid.data
    }
    
    func getPixelColor(pos: CGPoint) -> UIColor? {
        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelInfo: Int = ((Int(self.cgImage!.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let dataLength = CFDataGetLength(pixelData)
        if pixelInfo + 3 >= dataLength { return nil }
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255)
    
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    func rerenderImage() -> UIImage {
        let imageSize = CGSize(width: self.cgImage!.width, height: self.cgImage!.height)
        let flipedImage = flipImageVertically(originalImage: self.cgImage!)
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let renderedImage = renderer.image { context in
            context.cgContext.draw(
                flipedImage!,
                in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        }
        return renderedImage
    }
    
    func resize(newWidth: CGFloat) -> UIImage {
        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        let size = CGSize(width: newWidth, height: newHeight)
        let render = UIGraphicsImageRenderer(size: size)
        let renderImage = render.image { context in self.draw(in: CGRect(origin: .zero, size: size)) }
        print("화면 배율: \(UIScreen.main.scale)")
        // 배수
        print("origin: \(self), resize: \(renderImage)")
        return renderImage
    }

    
    func downSample2(size: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage {
        let imageSourceOption = [kCGImageSourceShouldCache: false] as CFDictionary
        let data = self.pngData()! as CFData
        let imageSource = CGImageSourceCreateWithData(data, imageSourceOption)!
        let maxPixel = max(size.width, size.height) * scale
        let downSampleOptions = [ kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceShouldCacheImmediately: true, kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceThumbnailMaxPixelSize: maxPixel ] as CFDictionary
        let downSampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downSampleOptions)!
        let newImage = UIImage(cgImage: downSampledImage)
//        printDataSize(newImage)
        return newImage
    }
    
    func imageByApplyingClippingBezierPath(_ path: UIBezierPath) -> UIImage {
        // Mask image using path
        let maskedImage = imageByApplyingMaskingBezierPath(path)
        
        // Crop image to frame of path
        let croppedImage = UIImage(cgImage: maskedImage.cgImage!.cropping(to: path.bounds)!)
        return croppedImage
    }
    
    func imageByApplyingMaskingBezierPath(_ path: UIBezierPath) -> UIImage {
        let size = CGSize(width: 200, height: 200)
        // Define graphic context (canvas) to paint on
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        
        // Set the clipping mask
        path.addClip()
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        // Restore previous drawing context
        context.restoreGState()
        UIGraphicsEndImageContext()
        
        return maskedImage
    }
}
