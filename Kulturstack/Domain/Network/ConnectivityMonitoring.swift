import Observation

@MainActor
protocol ConnectivityMonitoring: AnyObject, Observable {
    var isOnline: Bool { get }
}
