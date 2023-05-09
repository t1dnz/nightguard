	//
//  ChartPainter.swift
//  scoutwatch
//
//  Created by Dirk Hermanns on 01.12.15.
//  Copyright © 2015 private. All rights reserved.
//

import Foundation
import UIKit
#if !os(iOS)
import WatchKit
#endif

class ChartPainter {
    
    let DARK : UIColor = UIColor.init(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
    let BLACK : UIColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1)
    let LIGHTGRAY : UIColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 0.5)
    let DARKGRAY : UIColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 0.1)
    let PURPLE = UIColor.purple
    
    let halfHour : Double = 1800
    let fullHour : Double = 3600
    
    var canvasWidth : Int = 165
    var canvasHeight : Int = 125
    // the height that can be used to paint the lines
    // this way the lines can't cross the x-axis labels
    var paintableHeight : Int = 100
    
    var maximumXValue : Double = 0
    var minimumXValue : Double = Double.infinity
    var maximumYValue : Float = 200
    var minimumYValue : Float = 40

    var size : CGSize
    
    init(canvasWidth : Int, canvasHeight : Int) {
        size = CGSize.init(width: canvasWidth, height: canvasHeight)
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.paintableHeight = canvasHeight - 30
    }
    
    /* 
     * The upper- and lowerBoundGoodValue is the gray box that will be painted in the diagram.
     * It marks the blood values that are called "good".
     * Values out of this area will cause an alarm signal to be played!
     *
     * But of cause the alarming is out of the scope of this class!
     
     * The position of the current value is returned as the second tuple element.
     * It is used to show the current value in the viewport.
     */
    func drawImage(_ days : [[BloodSugar]], maxBgValue : CGFloat, upperBoundNiceValue : Float, lowerBoundNiceValue : Float, displayDaysLegend : Bool, showYesterdaysBGValues : Bool, useContrastfulColors : Bool) -> (UIImage?, Int) {

        // we need at least one day => otherwise paint nothing
        if days.count == 1 {
            return (UIImage.emptyImage(with: CGSize(width: 0, height: 0)), 0)
        }
        // we need at least 2 values - otherwise paint nothing and return empty image!
        if justOneOrLessValuesPerDiagram(days) {
            return (UIImage.emptyImage(with: CGSize(width: 0, height: 0)), 0)
        }
        
        adjustMinMaxXYCoordinates(days, maxYDisplayValue: maxBgValue, upperBoundNiceValue: upperBoundNiceValue, lowerBoundNiceValue: lowerBoundNiceValue)
        
        // Setup our context
        let opaque = false
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let context = UIGraphicsGetCurrentContext()
        
        // this can happen if fastly switching from statistics pane to main pane
        // I think this has to do with the screen rotating
        guard let safeContext = context else {
            return (UIImage.emptyImage(with: CGSize(width: 0, height: 0)), 0)
        }
        
        // Setup complete, do drawing here
        paintNicePartArea(safeContext, upperBoundNiceValue: upperBoundNiceValue, lowerBoundNiceValue: lowerBoundNiceValue)
        
        paintFullHourText(safeContext)
     
        paintBGValueLabels(context!, upperBoundNiceValue: upperBoundNiceValue, lowerBoundNiceValue: lowerBoundNiceValue, maxBgValue: CGFloat(maximumYValue))
        
        var nrOfDay = 0
        var positionOfCurrentValue = 0
        for bloodValues in days {
            nrOfDay = nrOfDay + 1
            if nrOfDay == 2 && !showYesterdaysBGValues {
                // omit yesterdays bgvalues if the user has requested this
                continue
            }
            let (sgvs, mbgs) = extractSgvs(allValues: bloodValues)
            paintBloodValues(context!, bgValues: sgvs, foregroundColor: getColor(nrOfDay, useContrastfulColors: useContrastfulColors).cgColor, maxBgValue: maxBgValue)
            if (nrOfDay == 1) {
                paintMeteredBloodValues(context!, mbgs: mbgs, sgvs: sgvs, maxBgValue: maxBgValue)
                paintTreatments(context!, bgValues: sgvs, maxBgValue: maxBgValue)
            }
            if nrOfDay == 1 && bloodValues.count > 0 {
                positionOfCurrentValue = Int(calcXValue(bloodValues.last?.timestamp ?? 0))
            }
        }
        
        // Don't paint the Legend on the small apple watch - so there displayDaysLegend is set to false
        // And don't paint the Legend if yesterdays values shouldn't be displayed at all
        if (displayDaysLegend && showYesterdaysBGValues) {
            paintLegend(days.count, useContrastfulColors: useContrastfulColors)
        }
        
        // Drawing complete, retrieve the finished image and cleanup
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return (image, positionOfCurrentValue)
    }
    
    // Extract all sensor measured values. Remove meatered blood glucose values.
    fileprivate func extractSgvs(allValues : [BloodSugar]) -> ([BloodSugar], [BloodSugar]) {
        var sgvs : [BloodSugar] = []
        var mbgs : [BloodSugar] = []
        for value in allValues {
            if value.isMeteredBloodGlucoseValue {
                mbgs.append(value)
            } else {
                sgvs.append(value)
            }
        }
        
        return (sgvs, mbgs)
    }

    fileprivate func justOneOrLessValuesPerDiagram(_ days : [[BloodSugar]]) -> Bool {
        for bloodValues in days {
            if bloodValues.count > 1 {
                // at least one diagram will have a line, painting makes sense
                return false
            }
        }
        return true
    }
    
    // Returns a different Color for each different day
    fileprivate func getColor(_ nrOfDay : Int, useContrastfulColors : Bool) -> UIColor {
        
        if (useContrastfulColors) {
            switch nrOfDay {
                case 2: return UIColor.nightguardContrastfulD2()
                case 3: return UIColor.nightguardContrastfulD3()
                case 4: return UIColor.nightguardContrastfulD4()
                case 5: return UIColor.nightguardContrastfulD5()
                
                default: return UIColor.nightguardContrastfulD1()
            }
        }
        
        switch nrOfDay {
            case 2: return LIGHTGRAY
            case 3: return UIColor.nightguardYellow()
            case 4: return UIColor.nightguardRed()
            case 5: return UIColor.nightguardOrange()
            
            default: return UIColor.nightguardGreen()
        }
    }
    
    fileprivate func paintBloodValues(_ context : CGContext, bgValues : [BloodSugar], foregroundColor : CGColor, maxBgValue : CGFloat) {
        
        context.setStrokeColor(foregroundColor)
        context.beginPath()
        
        let maxPoints : Int = bgValues.count
        if maxPoints <= 1 {
            // at least two points are needed to paint a stroke
            return
        }
        for currentPoint in 1...maxPoints-1 {
            
            let beginBGValue = bgValues[currentPoint-1]
            let endBGValue = bgValues[currentPoint]
            
            // skip drawing lines if at least one BG value is invalid
            guard beginBGValue.isValid && endBGValue.isValid else {
                continue
            }
            
            let beginOfLineYValue = calcYValue(Float(min(CGFloat(beginBGValue.value), value2: maxBgValue)))
            let endOfLineYValue = calcYValue(Float(min(CGFloat(endBGValue.value), value2: maxBgValue)))
    
            let maxYValue = calcYValue(Float(maxBgValue))
            
            let distanceFromNow = Date().timeIntervalSince(endBGValue.date)
            if (foregroundColor == UIColor.nightguardGreen().cgColor) && (distanceFromNow < 0) {
                
//                print(endBGValue.date)
                
                // a time in future indicates a predicted value!
                let nextReadingPoint = CGPoint(x: calcXValue(bgValues[currentPoint].timestamp), y: endOfLineYValue)

                context.strokePath()

//                context.beginPath();
                
                // fading points, opacity decreases in distant future (one hour)
                let opacity = Swift.min(1, Swift.max(0, CGFloat(3600 + distanceFromNow) / 4200))
                let pointColor = PURPLE.withAlphaComponent(opacity)
                context.setFillColor(pointColor.cgColor)
                context.setStrokeColor(pointColor.cgColor)
                let rect = CGRect(origin: nextReadingPoint, size: CGSize(width: 2, height: 2))
                context.addEllipse(in: rect)
                context.drawPath(using: .fillStroke)
                context.strokePath()
            } else {
            
                useRedColorIfLineWillBeReducedToMaxYValue(
                    context, beginOfLineYValue: beginOfLineYValue, endOfLineYValue: endOfLineYValue,
                    maxYDisplayValue: maxYValue, color: foregroundColor)
                
                drawLine(context,
                         x1: calcXValue(bgValues[currentPoint-1].timestamp),
                         y1: beginOfLineYValue,
                         x2: calcXValue(bgValues[currentPoint].timestamp),
                         y2: endOfLineYValue)
            }
        }
        context.strokePath()
    }
    
    fileprivate func paintMeteredBloodValues(_ context : CGContext, mbgs : [BloodSugar], sgvs : [BloodSugar], maxBgValue : CGFloat) {
        let maxPoints : Int = mbgs.count
        if maxPoints == 0 {
            return
        }
        
        for currentValue in mbgs {
            drawMeteredValue(context,
                             meaturedValue: currentValue.value,
                             nearestBg: nearestBg(timestamp: currentValue.timestamp, bgs: sgvs),
                             x: calcXValue(currentValue.timestamp),
                             y: calcYValue(Float(min(CGFloat(currentValue.value), value2: maxBgValue))))
        }
    }

    fileprivate func paintTreatments(_ context : CGContext, bgValues : [BloodSugar], maxBgValue : CGFloat) {
        
        var treatmentNumber = 0
        for treatment in TreatmentsStream.singleton.todaysTreatments() {
            if let mealBolusTreatment = treatment as? MealBolusTreatment {
                
                drawMealBolusValue(context,
                                   carbs: mealBolusTreatment.carbs,
                                   insulin: mealBolusTreatment.insulin,
                                   x: calcXValue(Double(mealBolusTreatment.timestamp)),
                                   y: CGFloat(paintableHeight - treatmentsYOffset(treatmentNumber)))
                // toggle the odd/even marker. This is used to prevent close treatments to be painted
                // on the same position in the chart
                treatmentNumber = treatmentNumber + 1
            }
            if let correctionBolusTreatment = treatment as? CorrectionBolusTreatment {
                
                drawCorrectionBolusValue(context,
                                   insulin: correctionBolusTreatment.insulin,
                                   x: calcXValue(Double(correctionBolusTreatment.timestamp)),
                                   y: calcYValue(Float(
                                                    min(nearestBgValueYValue(timestamp: correctionBolusTreatment.timestamp, bgs: bgValues), value2: maxBgValue))))
                treatmentNumber = treatmentNumber + 1
            }
            if let bolusWizardTreatment = treatment as? BolusWizardTreatment {
                
                if bolusWizardTreatment.insulin > 0 {
                
                    drawBolusWizardValue(context, insulin: bolusWizardTreatment.insulin,
                                         x: calcXValue(Double(bolusWizardTreatment.timestamp)),
                                         y: CGFloat(paintableHeight - treatmentsYOffset(treatmentNumber)))
                    treatmentNumber = treatmentNumber + 1
                }
            }
            if let carbCorrectionTreatment = treatment as? CarbCorrectionTreatment {
                drawMealBolusValue(context,
                                   carbs: carbCorrectionTreatment.carbs,
                                   insulin: 0,
                                   x: calcXValue(Double(carbCorrectionTreatment.timestamp)),
                                   y: CGFloat(paintableHeight - treatmentsYOffset(treatmentNumber)))
                treatmentNumber = treatmentNumber + 1
            }
        }
    }
    
    // determines how low treatments like carbs should be displayed on the
    // chart. If on the apple watch, this should differ to the main ios app.
    fileprivate func treatmentsYOffset(_ treatmentNumber : Int) -> Int {
        if self.canvasHeight < 500 {
            // On the watch: use smaller fonts
            return 10 + (treatmentNumber % 5) * 20
        }
        
        return 25 + (treatmentNumber % 5) * 25
    }
    
    fileprivate func nearestBgValueYValue(timestamp : Double, bgs : [BloodSugar]) -> CGFloat {
        
        return CGFloat(nearestBg(timestamp: timestamp, bgs: bgs)?.value ?? 0)
    }
    
    fileprivate func nearestBg(timestamp : Double, bgs : [BloodSugar]) -> BloodSugar? {
        
        var nearestBg : BloodSugar?
        var closestDifference : Double = 999999999999
        
        for bg in bgs {
            if abs(bg.timestamp - timestamp) < closestDifference {
                closestDifference = abs(bg.timestamp - timestamp)
                nearestBg = bg
            }
        }
        
        return nearestBg
    }
    
    fileprivate func useRedColorIfLineWillBeReducedToMaxYValue(_ context : CGContext,
                                                           beginOfLineYValue : CGFloat, endOfLineYValue : CGFloat,
                                                           maxYDisplayValue : CGFloat, color : CGColor) {
        
        let intMaxYDisplayValue = Int(maxYDisplayValue)
        
        if Int(beginOfLineYValue) == intMaxYDisplayValue &&
            Int(endOfLineYValue) == intMaxYDisplayValue &&
            color == UIColor.nightguardGreen().cgColor {
            
            context.strokePath();
            context.beginPath();
            context.setStrokeColor(UIColor.nightguardRed().cgColor)
        } else {
            context.setStrokeColor(color)
        }
    }
    
    fileprivate func drawLine(_ context : CGContext, x1 : CGFloat, y1 : CGFloat, x2 : CGFloat, y2 : CGFloat) {
        
        context.move(to: CGPoint(x: x1, y: y1))
        context.addLine(to: CGPoint(x: x2, y: y2))
    }
    
    fileprivate func drawMeteredValue(_ context : CGContext, meaturedValue : Float,  nearestBg: BloodSugar?, x : CGFloat, y : CGFloat) {
        
        // paint the upper/lower bounds text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attrs = [NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: fontSizeForMeteredBg())!,
                     NSAttributedString.Key.paragraphStyle: paragraphStyle,
                     NSAttributedString.Key.foregroundColor: UIColor.nightguardYellow()]
        
    
        var meaturedValueString = "\(UnitsConverter.mgdlToDisplayUnits(meaturedValue.cleanValue))"
        if let nearestBgValue = nearestBg?.value {
            meaturedValueString = meaturedValueString
                + "/\(UnitsConverter.mgdlToDisplayUnits(nearestBgValue.cleanValue))"
        }
        meaturedValueString.draw(
            with: CGRect(x: CGFloat(x) - 40, y: y - 20, width: 80, height: 18),
            options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        
        context.setFillColor(UIColor.gray.cgColor)
        context.fillEllipse(in: CGRect(x: x-3, y: y-3, width: 6, height: 6))
    }

    fileprivate func drawMealBolusValue(_ context : CGContext, carbs : Int, insulin : Double, x : CGFloat, y: CGFloat) {
        
        // paint the upper/lower bounds text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attrs = [NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: fontSizeForChartSize())!,
                     NSAttributedString.Key.paragraphStyle: paragraphStyle,
                     NSAttributedString.Key.foregroundColor: UIColor.white]
        
        var carbsString = ""
        if carbs > 0 {
            carbsString = String("\(carbs)g")
            if insulin > 0 {
                carbsString = carbsString + "/"
            }
        }
        
        if insulin > 0 {
            carbsString = carbsString + "\(insulin)U"
        }
        carbsString.draw(
            with: CGRect(x: CGFloat(x), y: y + 3, width: 60, height: 18),
            options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                
        context.setFillColor(UIColor.gray.cgColor)
        context.fillEllipse(in: CGRect(x: x-3, y: y-3, width: 7, height: 7))
    }
    
    fileprivate func drawBolusWizardValue(_ context : CGContext, insulin : Double, x : CGFloat, y : CGFloat) {
        
        // paint the upper/lower bounds text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attrs = [NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: fontSizeForChartSize())!,
                     NSAttributedString.Key.paragraphStyle: paragraphStyle,
                     NSAttributedString.Key.foregroundColor: UIColor.white]
        
    
        let insulinString = String("\(insulin)U")
        insulinString.draw(
            with: CGRect(x: CGFloat(x - 15), y: y - 18, width: 40, height: 14),
            options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                
        context.setFillColor(UIColor.gray.cgColor)
        context.fillEllipse(in: CGRect(x: x-3, y: y-3, width: 7, height: 7))
    }
    
    fileprivate func drawCorrectionBolusValue(_ context : CGContext, insulin : Double, x : CGFloat, y : CGFloat) {
                        
        context.setFillColor(UIColor.nightguardYellow().cgColor)
        
        context.move(to: CGPoint(x: x + 3, y: y))
        context.addLine(to: CGPoint(x: x - 7, y: y))
        context.addLine(to: CGPoint(x: x - 2, y: y + 5))
        context.addLine(to: CGPoint(x: x + 3, y: y))
        
        context.closePath()
        context.fillPath()
    }
    
    // Paint the part between upperBound and lowerBoundValue in gray
    fileprivate func paintNicePartArea(_ context : CGContext, upperBoundNiceValue : Float, lowerBoundNiceValue : Float) {
        
        // paint the rectangle
        context.setLineWidth(2.0)
        context.setFillColor(DARK.cgColor)
        let goodPart = CGRect(origin: CGPoint.init(x: 0, y: calcYValue(upperBoundNiceValue)), size: CGSize.init(width: canvasWidth, height: Int(calcYValue(lowerBoundNiceValue) - calcYValue(upperBoundNiceValue))))
        context.fill(goodPart)
    }
    
    fileprivate func paintBGValueLabels(_ context : CGContext, upperBoundNiceValue : Float, lowerBoundNiceValue : Float, maxBgValue : CGFloat) {
        
        // paint the upper/lower bounds text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attrs = [NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: fontSizeForChartSize())!,
                     NSAttributedString.Key.paragraphStyle: paragraphStyle,
                     NSAttributedString.Key.foregroundColor: UIColor.gray]
        
        var x = 5
        while (x < canvasWidth) {
            let maxBgValueAsFloat = Float(maxBgValue)
            
            // paint the maximum BGValue Label only if it has enought space and doesn't intersect with
            // the upper bound BGValue
            if maxBgValueAsFloat > upperBoundNiceValue + 25 {
                let maxBgValueString = UnitsConverter.mgdlToDisplayUnits(maxBgValueAsFloat.cleanValue)
                maxBgValueString.draw(
                    with: CGRect(x: CGFloat(x), y: CGFloat.init(calcYValue(maxBgValueAsFloat)) + 3, width: 40, height: 14),
                    options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            }
            
            let upperBoundString = UnitsConverter.mgdlToDisplayUnits(upperBoundNiceValue.cleanValue)
            upperBoundString.draw(
                with: CGRect(x: CGFloat(x), y: CGFloat.init(calcYValue(upperBoundNiceValue)), width: 40, height: 14),
                options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            
            let lowerBoundString = UnitsConverter.mgdlToDisplayUnits(lowerBoundNiceValue.cleanValue)
            lowerBoundString.draw(
                with: CGRect(x: CGFloat(x), y: CGFloat.init(calcYValue(lowerBoundNiceValue))-15, width: 40, height: 14),
                options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            
            x = x + 200
        }
    }
    
    fileprivate func fontSizeForMeteredBg() -> CGFloat {
        if self.canvasHeight < 400 {
            // On the watch: use smaller fonts
            return 12
        }
        
        return 18
    }
    
    fileprivate func fontSizeForChartSize() -> CGFloat {
        
        if self.canvasHeight < 400 {
            // On the watch: use smaller fonts
            return 10
        }
        
        return 14
    }

    fileprivate func min(_ value1 : CGFloat, value2 : CGFloat) -> CGFloat {
        if value1 < value2 {
            return value1
        }
        return value2
    }
    
    // Paints the X-Axis Text
    fileprivate func paintFullHourText(_ context : CGContext) {
        // Draw the time
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrs = [NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: fontSizeForChartSize())!,
                     NSAttributedString.Key.paragraphStyle: paragraphStyle,
                     NSAttributedString.Key.foregroundColor: UIColor.gray]
        
        if durationIsMoreThan6Hours(minimumXValue, maxTimestamp: maximumXValue) && canvasWidth < 1920 {
            paintEverySecondHour(context, attrs: attrs)
        } else {
            paintHourTimestamps(context, attrs: attrs)
        }
    }
    
    fileprivate func paintLegend(_ nrOfNames : Int, useContrastfulColors : Bool) {
        
        let names = ["D1", "D2", "D3", "D4", "D5"]
        let namesToDisplay = Array(names.prefix(nrOfNames))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        var attrs = [NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: 14)!,
                     NSAttributedString.Key.paragraphStyle: paragraphStyle,
                     NSAttributedString.Key.foregroundColor: UIColor.gray]
        
        var i : Int = 0
        for name in namesToDisplay {
            
            i = i + 1
            attrs.updateValue(getColor(i, useContrastfulColors: useContrastfulColors), forKey: NSAttributedString.Key.foregroundColor)
            let xPosition = canvasWidth - 22 * nrOfNames + i * 20 - 20
            name.draw(with: CGRect(x: xPosition, y: 20, width: 20, height: 14),
                                options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        }
    }
    
    fileprivate func durationIsMoreThan6Hours(_ minTimestamp : Double, maxTimestamp : Double) -> Bool {
        let sixHours = Double(6 * 60 * 60 * 1000)
        return (maxTimestamp - minTimestamp) > sixHours
    }
    
    fileprivate func paintEverySecondHour(_ context : CGContext, attrs : [NSAttributedString.Key : Any]) {
        
        guard let halfHours = determineEverySecondHourBetween(minimumXValue, maxTimestamp: maximumXValue) else {
            return
        }
        
        let hourFormat = DateFormatter()
        hourFormat.timeStyle = .short
        for timestamp in halfHours {
            let hourString : String = hourFormat.string(from: Date(timeIntervalSince1970 : timestamp / 1000))
            let x = calcXValue(timestamp)
            hourString.draw(with: CGRect(x: x-25, y: CGFloat.init(canvasHeight-20), width: 50, height: 14),
                                    options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            
            context.beginPath()
            context.setStrokeColor(BLACK.cgColor)
            drawLine(context, x1: x, y1: 0, x2: x, y2: CGFloat(canvasHeight) - 20)
            context.strokePath()
        }
    }
    
    fileprivate func determineEverySecondHourBetween(_ minTimestamp : Double, maxTimestamp : Double) -> [Double]? {
        
        let minDate = Date(timeIntervalSince1970: minTimestamp / 1000)
        let maxDate = Date(timeIntervalSince1970: maxTimestamp / 1000)
        
        var currentDate = minDate
        var evenHours : [Double] = []
        var stop : Bool
        
        repeat {
            guard let nextEvenHour = getNextEvenHour(currentDate) else {
                return nil
            }
            if nextEvenHour.compare(maxDate) == .orderedAscending {
                evenHours.append(nextEvenHour.timeIntervalSince1970 * 1000)
                stop = false
            } else {
                stop = true
            }
            currentDate = nextEvenHour
        } while !stop
        
        return evenHours
    }
    
    fileprivate func paintHourTimestamps(_ context : CGContext, attrs : [NSAttributedString.Key : Any]) {
        let hours = determineHoursBetween(minimumXValue, maxTimestamp: maximumXValue)
        
        let hourFormat = DateFormatter()
        hourFormat.timeStyle = .short
        
        context.setStrokeColor(BLACK.cgColor)
        for timestamp in hours {
            let hourString : String = hourFormat.string(from: Date(timeIntervalSince1970 : timestamp / 1000))
            let x = calcXValue(timestamp)
            hourString.draw(with: CGRect(x: x-25, y: CGFloat.init(canvasHeight-20), width: 50, height: 14),
                                    options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            
            context.beginPath()
            context.setStrokeColor(BLACK.cgColor)
            drawLine(context, x1: x, y1: 0, x2: x, y2: CGFloat(canvasHeight) - 20)
            context.strokePath()
        }
    }
    
    func determineHoursBetween(_ minTimestamp : Double, maxTimestamp : Double) -> [Double] {
        
        let minDate = Date(timeIntervalSince1970: minTimestamp / 1000)
        let maxDate = Date(timeIntervalSince1970: maxTimestamp / 1000)
        
        var currentDate = minDate
        var halfHours : [Double] = []
        var stop : Bool
        
        repeat {
            let nextHour = getNextHour(currentDate);
            if nextHour.compare(maxDate) == .orderedAscending {
                halfHours.append(nextHour.timeIntervalSince1970 * 1000)
                stop = false
            } else {
                stop = true
            }
            currentDate = nextHour
        } while !stop
        
        return halfHours
    }
    
    // Returns e.g. 04:00 for 02:00 o'clock.
    fileprivate func getNextEvenHour(_ date : Date) -> Date? {
        
        let cal = Calendar.current
        
        let hour = (cal as NSCalendar).component(NSCalendar.Unit.hour, from: date)
        
        guard let currentHour = (cal as NSCalendar).date(bySettingHour: hour, minute: 0, second: 0, of: date, options: NSCalendar.Options()) else {
            return nil
        }
        var nextHour = currentHour.addingTimeInterval(
            isEven(hour + 1) ? fullHour : 2 * fullHour
        )
        
        // During daylight-savings the next hour can be the still the same
        // We need to jump to the next hour in this case
        if (cal as NSCalendar).component(NSCalendar.Unit.hour, from: nextHour) == hour {
            nextHour = currentHour.addingTimeInterval(fullHour * 2)
        }
        
        return nextHour
    }
    
    fileprivate func isEven(_ hour : Int) -> Bool {
        return hour % 2 == 0
    }
    
    fileprivate func getNextHour(_ date : Date) -> Date {
        
        let cal = Calendar.current
        
        let hour = (cal as NSCalendar).component(NSCalendar.Unit.hour, from: date)
        
        let currentHour = (cal as NSCalendar).date(bySettingHour: hour, minute: 0, second: 0, of: date, options: NSCalendar.Options())!
        var nextHour = currentHour.addingTimeInterval(fullHour)
        
        // During daylight-savings the next hour can be the still the same
        // We need to jump to the next hour in this case
        if (cal as NSCalendar).component(NSCalendar.Unit.hour, from: nextHour) == hour {
            nextHour = currentHour.addingTimeInterval(fullHour * 2)
        }
        
        return nextHour
    }
    
    func adjustMinMaxXYCoordinates(
            _ days : [[BloodSugar]],
            maxYDisplayValue : CGFloat,
            upperBoundNiceValue : Float,
            lowerBoundNiceValue : Float) {
        
        maximumXValue = -1 * Double.infinity
        minimumXValue = Double.infinity
        maximumYValue = upperBoundNiceValue
        minimumYValue = lowerBoundNiceValue
        
        (minimumXValue, maximumXValue, minimumYValue, maximumYValue) = adjustMinMax(days, maxYDisplayValue: maxYDisplayValue, minimumXValue: minimumXValue, maximumXValue: maximumXValue, minimumYValue: minimumYValue, maximumYValue: maximumYValue)
    }
    
    fileprivate func adjustMinMax(_ days : [[BloodSugar]], maxYDisplayValue: CGFloat, minimumXValue : Double, maximumXValue : Double, minimumYValue : Float, maximumYValue : Float) -> (Double, Double, Float, Float) {
        
        var newMinXValue = minimumXValue
        var newMaxXValue = maximumXValue
        
        var newMinYValue = minimumYValue
        var newMaxYValue = Float(min(CGFloat(maximumYValue), value2: maxYDisplayValue))
        
        for dayIndex in 0..<days.count {
            for bgValue in days[dayIndex] {
                
                guard bgValue.isValid else {
                    continue
                }
                
                if (dayIndex == 0) && (bgValue.date > Date()) {
                    // do not consider predicted values
                    continue
                }
                
                if bgValue.value < newMinYValue {
                    newMinYValue = bgValue.value
                }
                if bgValue.value > newMaxYValue {
                    newMaxYValue = Float(min(CGFloat(bgValue.value), value2: maxYDisplayValue))
                }
            
                if bgValue.timestamp < newMinXValue {
                    newMinXValue = bgValue.timestamp
                }
                if bgValue.timestamp > newMaxXValue {
                    newMaxXValue = bgValue.timestamp
                }
            }
        }
        
        return (newMinXValue, newMaxXValue, newMinYValue, newMaxYValue)

    }
    
    fileprivate func calcXValue(_ x : Double) -> CGFloat {
        return CGFloat.init(stretchedXValue(x));
    }
    
    func calcYValue(_ y : Float) -> CGFloat {

        var calculatedY : Float = stretchedYValue(y)
        if calculatedY > Float(Int.max) {
            calculatedY = Float(Int.max)
        }
        let mirroredY : Int = paintableHeight - Int(calculatedY)
        let cgfloat : CGFloat = CGFloat(mirroredY)
        
        return cgfloat
    }
    
    func stretchedXValue(_ x : Double) -> Double {
        var range = maximumXValue - minimumXValue
        if range == 0 {
            // prevent a division by zero
            range = 1
        }
        return (Double(canvasWidth) / Double(range)) * Double(x - minimumXValue)
    }
    
    func stretchedYValue(_ y : Float) -> Float {
        var range = maximumYValue - minimumYValue
        if range == 0 {
            // prevent a division by zero
            range = 1
        }
        return (Float(paintableHeight) / Float(range)) * (y - minimumYValue)
    }
}
