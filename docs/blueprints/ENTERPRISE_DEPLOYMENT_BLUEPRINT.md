# LaundryPro UAE — Enterprise Topology & Deployment Blueprint

> **Version:** 2.0.0 | **Authoritative Infrastructure Blueprint**

---

## 1. Supported Deployment Topologies

LaundryPro UAE accommodates three distinct enterprise operational topologies:

---

### Topology A: Standalone Boutique Store (All-in-One POS)
For independent single-workstation dry cleaners and laundromats:

```mermaid
graph TD
    subgraph "Single All-in-One Touch PC"
        Flutter["Flutter POS Client UI"]
        LocalAPI["Local PHP API (localhost:8080)"]
        LocalDB[("Local MariaDB / SQLite")]
        Daemon["Sync Daemon (Background Worker)"]
    end
    
    Cloud[("LaundryPro Cloud Gateway<br/>(Central Multi-Tenant)")]
    Printer["80mm Thermal Printer + Cash Drawer"]

    Flutter -->|HTTP Loopback| LocalAPI
    LocalAPI --> LocalDB
    Daemon -->|Reads Outbox| LocalDB
    Daemon -.->|HTTPS Delta Sync (Every 60s)| Cloud
    Flutter -->|USB / ESC-POS| Printer
```

---

### Topology B: Multi-Terminal Branch (Store LAN Server)
For busy retail branches with 2–5 front-desk cashiers and a back-office manager:

```mermaid
graph TD
    subgraph "Branch Local Area Network (LAN)"
        Term1["POS Terminal 1 (Cashier Intake)"]
        Term2["POS Terminal 2 (Collection & Checkout)"]
        Term3["Manager Desktop / Tablet"]
        
        Server["Dedicated In-Store Server<br/>(Host: 192.168.1.100)"]
        ServerDB[("Local MariaDB Engine")]
        ServerDaemon["Background Sync Daemon"]
    end
    
    Cloud[("LaundryPro Cloud Gateway")]

    Term1 -->|LAN HTTP| Server
    Term2 -->|LAN HTTP| Server
    Term3 -->|LAN HTTP| Server
    Server --> ServerDB
    ServerDaemon --> ServerDB
    ServerDaemon -.->|WAN HTTPS (Auto-Reconnect)| Cloud
```

---

### Topology C: Hub-and-Spoke Franchise with Central Processing Plant
For large laundry chains with retail pickup outlets and an industrial laundry processing factory:

```mermaid
graph TD
    subgraph "Retail Outlet 1 (Al Barsha)"
        Branch1["Branch 1 Local Node"]
    end
    
    subgraph "Retail Outlet 2 (Jumeirah)"
        Branch2["Branch 2 Local Node"]
    end

    subgraph "Central Industrial Laundry Plant (Al Quoz)"
        PlantServer["Plant Central Node"]
        Sorter["Bulk Sorter & Tag Verification"]
        Washer["Tunnel Washers & Industrial Dryers"]
        Packer["Automated Poly-Bagger & Racks"]
    end
    
    Cloud[("LaundryPro Cloud API Gateway")]

    Branch1 -->|Digital Challan Dispatch| PlantServer
    Branch2 -->|Digital Challan Dispatch| PlantServer
    
    Sorter --> PlantServer
    Packer --> PlantServer
    
    Branch1 -.->|Sync Push/Pull| Cloud
    Branch2 -.->|Sync Push/Pull| Cloud
    PlantServer -.->|Sync Push/Pull| Cloud
```

---

## 2. Network & Bandwidth Specifications

- **Offline Operational Buffer**: Local MariaDB can store **> 1,000,000 orders** offline indefinitely on a standard 256GB SSD without degradation.
- **Bandwidth Consumption**: An individual delta sync batch of 50 orders consumes **< 15 KB** of compressed JSON data.
- **Latency Tolerance**: The POS UI operates with 0ms network latency because all user actions execute against the local workstation database.
