//
//  StopAlarmIntent.swift
//  Todoo
//
//  Created by Fabrizio Petrozzi on 7/11/25.
//
import AppIntents
import AlarmKit

struct StopAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Alarm"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Alarm ID")
    var alarmIDString: String

    init() {
        self.alarmIDString = ""
    }

    init(alarmIDString: String) {
        self.alarmIDString = alarmIDString
    }

    func perform() async throws -> some IntentResult {
        guard let alarmID = UUID(uuidString: alarmIDString) else {
            return .result()
        }
        try await AlarmManager.shared.stop(id: alarmID)
        return .result()
    }
}
