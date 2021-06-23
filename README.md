# PiholeNetworking
[![Swift](https://github.com/riley-williams/PiholeNetworking/actions/workflows/swift.yml/badge.svg)](https://github.com/riley-williams/PiholeNetworking/actions/workflows/swift.yml) [![codecov](https://codecov.io/gh/riley-williams/PiholeNetworking/branch/main/graph/badge.svg?token=F04LYNUK5V)](https://codecov.io/gh/riley-williams/PiholeNetworking)

Open source networking library for interacting with Pi-hole DNS blocker instances

If you'd rather use Combine, check out 0.3.0

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

let summary = try await provider.getSummary(pihole)
    
print("Queries today: \(summary.queryCount)")
print("Queries blocked today: \(summary.blockedQueryCount)")

// Queries today: 49216
// Queries blocked today: 3872
```

``` swift
// Many queries require authentication
pihole.password = "MyWebPassword"

// Disable the Pi-hole for 15 seconds
let state = try await provider.disable(pihole, for: 15)

print("Pi-hole is now \(state)")

// Pi-hole is now disabled
```
