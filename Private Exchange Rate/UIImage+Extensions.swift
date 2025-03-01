//
//  UIImage+Extensions.swift
//  Private Exchange Rate
//
//  Created on behalf of Dmitriy Portenko
//

import UIKit

// Helper extension to create shadow image
extension UIImage {
    static func shadow(with size: CGSize, radius: CGFloat, color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setShadow(offset: .zero, blur: radius, color: color.cgColor)
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
} 