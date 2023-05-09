//
//  TreatmentsStream.swift
//  nightguard
//
//  Created by Dirk Hermanns on 14.02.21.
//  Copyright © 2021 private. All rights reserved.
//

import Foundation

// Contains all Nightscout Treatments of the last day.
class TreatmentsStream {
    
    static let singleton = TreatmentsStream()
    
    private var treatmentsCache = Dictionary<String, Treatment>()
    
    // Adds treatments fetched as json dictionaries
    public func addNewJsonTreatments(jsonTreatments : [[String: Any]]) {
        
        // loop through all treatments and check whether we have new ones
        for jsonTreatment in jsonTreatments {
            // Make sure all treatments have has "_id" "eventType" and "created_at"
            
            if let eventType = jsonTreatment["eventType"] as? String,
                let id = jsonTreatment["_id"] as? String,
                let createdAt = jsonTreatment["created_at"] as? String {
                
                // convert created at
                let timestamp = Double.fromIsoString(isoTime: createdAt)
                
                // carb and insulin values with defaults
                let carbs = jsonTreatment["carbs"] as? Int ?? 0
                let insulin = jsonTreatment["insulin"] as? Double ?? 0.0
                
                switch eventType {
                case "Carb Correction":
                    treatmentsCache[id] = CarbCorrectionTreatment.init(
                        id: id, timestamp: timestamp, carbs: carbs
                    )
                case "Meal Bolus":
                    treatmentsCache[id] = MealBolusTreatment.init(
                        id: id, timestamp: timestamp, carbs: carbs, insulin: insulin
                    )
                case "Correction Bolus":
                    treatmentsCache[id] = CorrectionBolusTreatment.init(
                        id: id, timestamp: timestamp, insulin: insulin
                    )
                case "Bolus Wizard":
                    treatmentsCache[id] = BolusWizardTreatment.init(
                        id: id, timestamp: timestamp, insulin: insulin
                    )
                default:
                    // ignore all the rest
                    continue
                }
            }
        }
        
        cleanUpOldTreatments()
    }
    
    
    public func setTreatments(_ treatments : [Treatment]) {
        treatmentsCache.removeAll() // clear the cache
        for t in treatments {
            treatmentsCache[t.id] = t
        }
    }
    
    public func todaysTreatments() -> [Treatment] {
        // return all todays treatments
        let startOfTime = TimeService.getStartOfCurrentDay()
        return treatmentsCache.values.filter { t in t.timestamp >= startOfTime }
    }
    
    public func sortedTreatments() -> [Treatment] {
        // return all treatments in a sorted array
        return treatmentsCache.values.sorted { t1, t2 in t1.timestamp > t2.timestamp}
    }
    
    ///
    /// Helper Methods
    ///
    
    private func cleanUpOldTreatments() {
        // remove any treatment older than 24 hours
        let startOfTime = TimeService.getCurrentTime() - (60 * 60 * 24) // minus 24 hours of time
        
        for treatment in treatmentsCache.values.filter({ t in t.timestamp >= startOfTime }) {
            if treatment.timestamp < startOfTime {
                treatmentsCache.removeValue(forKey: treatment.id)
            }
        }
    }
}
