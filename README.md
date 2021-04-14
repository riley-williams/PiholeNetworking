# PiholeNetworking

Open source networking library for interacting with Pi-hole DNS blocker instances

## Getting Started

``` swift
// Add PHInstance conformance to your existing Pi-hole model type

struct MyPiholeModel {
    var ip: String
    var port: Int
    var password: String?
}

extension MyPiholeModel: PHInstance { }
```
``` swift
// Create a shared provider object and a model instance

let provider = PHProvider()

var pihole = MyPiholeModel(ip: "192.168.1.10", port: 80, password: nil)
```
``` swift
// Make a request

let summaryCancellable = provider.getSummary(pihole)
    .sink { completion in
        // Handle failure or completion
    } receiveValue: { summary in
        print("Queries today: \(summary.queryCount)")
        print("Queries blocked today: \(summary.blockedQueryCount)")
    }
```
``` swift
// Queries today: 49216
// Queries blocked today: 3872
```

``` swift
// Many queries require authentication
pihole.password = "MyWebPassword"

// Disable the Pi-hole for 15 seconds
let disableCancellable = provider.disable(pihole, for: 15)
    .sink { completion in
        // Handle failure or completion
    } receiveValue: { state in
        print("Pi-hole is now \(state)")
    }
```
``` swift
// Pi-hole is now disabled
```
