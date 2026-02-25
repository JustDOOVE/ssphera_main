import Foundation

struct GiteaTeamPullRequestsWidget: Codable, Hashable {
    let headers: [String]
    let rows: [[String]]
}

struct RedmineSelfTasksWidget: Codable, Hashable {
    let headers: [String]
    let rows: [[String]]
}

struct RedmineAnomalyWorkhoursTasksWidget: Codable, Hashable {
    let headers: [String]
    let rows: [[String]]
}

struct RedmineSelfAverageWorkhoursWidget: Codable, Hashable {
    let headers: [String]
    let rows: [[String]]
}

struct RedmineAverageWorkhoursWidget: Codable, Hashable {
    let headers: [String]
    let rows: [[String]]
}

struct RedmineLongSupportTasksWidget: Codable, Hashable {
    let headers: [String]
    let rows: [[String]]
}
