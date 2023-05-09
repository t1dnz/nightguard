//
//  HistoryViewController.swift
//  nightguard
//
//  Created by Graham Jenson on 8/05/23.
//  Copyright © 2023 private. All rights reserved.
//

import UIKit

class HistoryViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tappy")
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TreatmentsStream.singleton.sortedTreatments().count
    }
    
    func timeAgoDisplay(_ ts: Double) -> String {
        let date = Date(timeIntervalSince1970 : ts / 1000)
        
        if #available(iOS 13.0, *) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: date, relativeTo: Date()).padding(toLength:14,withPad:" ",startingAt:0)
        }
        
        let formatter  = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
//    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 100.0
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UITableViewCell
        let treatments = TreatmentsStream.singleton.sortedTreatments()
        if !treatments.indices.contains(indexPath.row)  {
            cell.textLabel?.text = "unknown"
            return cell
        }
        
        
        let treatment = treatments[indexPath.row]
        
        let datelabel = "\(timeAgoDisplay(treatment.timestamp))"
        
        if let mealBolusTreatment = treatment as? MealBolusTreatment {
            cell.textLabel?.text =  "\(datelabel) -- \(mealBolusTreatment.insulin)u for \(mealBolusTreatment.carbs)g "
        }
        
        if let correctionBolusTreatment = treatment as? CorrectionBolusTreatment {
            cell.textLabel?.text = "\(datelabel) -- \(correctionBolusTreatment.insulin)u Bolus"
        }
        
        if let bolusWizardTreatment = treatment as? BolusWizardTreatment {
            cell.textLabel?.text = "\(datelabel) -- \(bolusWizardTreatment.insulin)u Bolus"
        }
        
        if let carbCorrectionTreatment = treatment as? CarbCorrectionTreatment {
            cell.textLabel?.text = "\(datelabel) -- \(carbCorrectionTreatment.carbs)g Carbs"
        }
        
        return cell
    }
    
}


