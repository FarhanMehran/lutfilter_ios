//
//  ViewController.swift
//  LUTFilters
//
//  Created by Muhammad  Farhan Akram on 19/09/2024.
//

import UIKit
import CoreImage


class ViewController: UIViewController {
    
    var originalImageView: UIImageView?
    var filteredImageView: UIImageView?
    var originalImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the dummy image "Apple" from assets
        if let inputImage = UIImage(named: "Apple") {
            self.originalImage = inputImage
            displayOriginalImage(inputImage)
            addApplyFilterButton()
        } else {
            print("Failed to load the image from assets.")
        }
    }
    
    func displayOriginalImage(_ image: UIImage) {
        originalImageView?.removeFromSuperview() // Remove old image view if any
        
        let imageView = UIImageView(image: image)
        imageView.frame = self.view.bounds
        imageView.contentMode = .scaleAspectFit
        self.view.addSubview(imageView)
        self.originalImageView = imageView
    }
    
    func addApplyFilterButton() {
        let button = UIButton(type: .system)
        button.setTitle("Apply LUT Filter", for: .normal)
        button.addTarget(self, action: #selector(applyFilterButtonTapped), for: .touchUpInside)
        button.frame = CGRect(x: 0, y: self.view.frame.height - 50, width: self.view.frame.width, height: 50)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        self.view.addSubview(button)
    }
    
    @objc func applyFilterButtonTapped() {
        guard let inputImage = originalImage else {
            print("Original image not found.")
            return
        }
        
        print("Attempting to apply LUT filter...")
        if let filteredImage = applyLUTFilter(to: inputImage, withCubeFile: "PRESET_Fujicolor_SuperHR100") {
            print("LUT filter applied successfully.")
            filteredImageView?.removeFromSuperview() // Remove old filtered image view if any
            displayFilteredImage(filteredImage)
        } else {
            print("Failed to apply LUT filter.")
        }
    }
    
    func displayFilteredImage(_ image: UIImage) {
        let imageView = UIImageView(image: image)
        imageView.frame = self.view.bounds
        imageView.contentMode = .scaleAspectFit
        self.view.addSubview(imageView)
        self.filteredImageView = imageView
    }
    
    func applyLUTFilter(to inputImage: UIImage, withCubeFile fileName: String) -> UIImage? {
        guard let lutData = loadLUTFromCubeFile(fileName: fileName) else {
            print("Failed to load LUT file.")
            return nil
        }
        
        guard let ciImage = CIImage(image: inputImage),
              let filter = CIFilter(name: "CIColorCube") else {
            print("Failed to create CIColorCube filter.")
            return nil
        }
        
        let size = lutData.size
        let data = lutData.cubeData
        
        filter.setValue(size, forKey: "inputCubeDimension")
        filter.setValue(data, forKey: "inputCubeData")
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        print("Applying LUT filter with size \(size)...")
        
        if let outputImage = filter.outputImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                print("Successfully created CGImage from filtered CIImage.")
                return UIImage(cgImage: cgImage)
            } else {
                print("Failed to create CGImage.")
            }
        } else {
            print("Failed to get output image from filter.")
        }
        
        return nil
    }
    
    func loadLUTFromCubeFile(fileName: String) -> (cubeData: Data, size: NSNumber)? {
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "cube") else {
            print("File not found: \(fileName).cube")
            return nil
        }
        
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            var lutSize: Int = 0
            var cubeValues: [Float] = []
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }
                
                let components = trimmedLine.components(separatedBy: .whitespaces)
                
                // Debug print to check which line is being processed
                print("Processing line: \(trimmedLine)")
                
                if components.count == 2 && components[0] == "LUT_3D_SIZE" {
                    if let size = Int(components[1]) {
                        lutSize = size
                        print("Parsed LUT_3D_SIZE: \(lutSize)")
                    }
                } else if components.count == 3, let r = Float(components[0]), let g = Float(components[1]), let b = Float(components[2]) {
                    cubeValues.append(contentsOf: [r, g, b])
                }
            }
            
            // Ensure LUT size was found
            if lutSize == 0 {
                print("LUT size is zero. Something went wrong when parsing the file.")
                return nil
            }
            
            let floatSize = lutSize * lutSize * lutSize * 4
            var lutData = [Float](repeating: 0, count: floatSize)
            
            for i in 0..<(lutSize * lutSize * lutSize) {
                lutData[i * 4 + 0] = cubeValues[i * 3 + 0]
                lutData[i * 4 + 1] = cubeValues[i * 3 + 1]
                lutData[i * 4 + 2] = cubeValues[i * 3 + 2]
                lutData[i * 4 + 3] = 1.0
            }
            
            let data = Data(buffer: UnsafeBufferPointer(start: &lutData, count: lutData.count))
            return (data, NSNumber(value: lutSize))
        } catch {
            print("Error reading LUT file: \(error)")
            return nil
        }
    }
}
