//
//  PickerTool.swift
//  spriteMaker
//
//  Created by 박찬울 on 2021/04/28.
//

import UIKit

class PickerTool {
    var canvas: Canvas!
    var grid: Grid!
    
    init(_ canvas: Canvas) {
        self.canvas = canvas
        self.grid = canvas.grid
    }
    
    func drawPicker(_ context: CGContext) {
        let pixelSize = canvas.onePixelLength! * 1.5
        let posX = canvas.moveTouchPosition.x
        let posY = canvas.moveTouchPosition.y
        let posGrid = canvas.transPosition(canvas.moveTouchPosition)
        var curColor = canvas.grid.findColorSelected(x: posGrid["x"]!, y: posGrid["y"]!)
        curColor = curColor == "none" ? "#555555" : curColor
        
        var rectangle: CGRect!
        let centerX: CGFloat = posX - (20 + pixelSize / 2)
        let centerY: CGFloat = posY - (20 + pixelSize / 2)
        var rectPosX: CGFloat = centerX - (pixelSize * 2)
        var rectPosY: CGFloat = centerY - (pixelSize * 2)
        var posGridX = posGrid["x"]! - 2
        var posGridY = posGrid["y"]! - 2
        var countX = 0
        var countY = 0
        
        let corner: [String: [Int]] = [
            "0": [0, 4],
            "4": [0, 4]
        ]
        
        func isCorner() -> Bool {
            guard let cornerX = corner[String(countX)] else { return false }
            return cornerX.firstIndex(of: countY) != nil
        }
        
        while countY < 5 {
            while countX < 5 {
                if isCorner() == false {
                    var fillColor = canvas.grid.findColorSelected(x: posGridX, y: posGridY)
                    fillColor = fillColor == "none" ? "#555555" : fillColor
                    context.setFillColor(fillColor.uicolor!.cgColor)
                    rectangle = CGRect(x: rectPosX, y: rectPosY, width: pixelSize, height: pixelSize)
                    context.addRect(rectangle)
                    context.drawPath(using: .fillStroke)
                }
                rectPosX += pixelSize
                countX += 1
                posGridX += 1
            }
            countY += 1
            posGridY += 1
            rectPosY += pixelSize
            // init
            countX = 0
            posGridX = posGrid["x"]! - 2
            rectPosX = centerX - (pixelSize * 2)
        }
        
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(canvas.onePixelLength / 5)
        context.setFillColor(curColor.uicolor!.cgColor)
        rectangle = CGRect(x: centerX, y: centerY, width: pixelSize, height: pixelSize)
        context.addRect(rectangle)
        context.drawPath(using: .fillStroke)

        // draw colored outline
        context.setStrokeColor(curColor.uicolor!.cgColor)
        context.setLineWidth(canvas.onePixelLength / 1)
        context.addArc(
            center: CGPoint(x: posX - 20, y: posY - 20),
            radius: pixelSize * 2.6,
            startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true
        )
        context.strokePath()
        
        // draw outline
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(canvas.onePixelLength / 3)
        context.addArc(
            center: CGPoint(x: posX - 20, y: posY - 20),
            radius: pixelSize * 2.3,
            startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true
        )
        context.strokePath()
    }
}

extension PickerTool {
    func touchesBegan(_ pixelPosition: [String: Int]) {
    }
    
    func touchesBeganOnDraw(_ context: CGContext) {
        drawPicker(context)
    }
    
    func touchesMoved(_ context: CGContext) {
        drawPicker(context)
    }
    
    func touchesEnded(_ context: CGContext) {
        let endPosition = canvas.transPosition(canvas.moveTouchPosition)
        let removedColor = grid.findColorSelected(x: endPosition["x"]!, y: endPosition["y"]!)
        if (removedColor != "none") {
            canvas.selectedColor = removedColor.uicolor
            canvas.drawingVC.colorPaletteVM.selectedColorIndex = -1
            canvas.drawingVC.colorPickerToolBar.selectedColor = removedColor.uicolor
            canvas.drawingVC.colorPickerToolBar.updateColorBasedCanvasForThreeSection(true)
        }
    }
}


