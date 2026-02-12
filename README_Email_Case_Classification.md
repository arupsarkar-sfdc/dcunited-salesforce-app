# Email Case Classification - Business Logic Flow

## Overview

This document describes the automated email-to-case classification system that leverages **Salesforce Data Cloud**, **Platform Events**, and **AI/LLM** to intelligently classify incoming customer emails and update the associated Case records.

---

## Architecture Diagram

```mermaid
flowchart TD
    subgraph Customer["🔵 CUSTOMER INTERACTION"]
        A[📧 Customer Sends Email]
    end

    subgraph Salesforce["🟢 SALESFORCE CORE"]
        B[EmailMessage Record Created]
        C[Case Record Linked]
    end

    subgraph DataCloud["🟣 DATA CLOUD"]
        D[ssot__EmailMessage__dlm<br/>Data Model Object]
        E[Vector Similarity Search<br/>relevantResults generated]
        F[Data Cloud Action:<br/>Email_Case_Classification]
    end

    subgraph PlatformEvent["🟠 PLATFORM EVENT"]
        G[DataObjectDataChgEvent<br/>Published on INSERT]
    end

    subgraph ApexProcessing["🔴 APEX PROCESSING"]
        H[Trigger:<br/>DataObjectDataChgEventHandler]
        I[Queueable:<br/>DataCloudDataChangeEventQueueable]
        J[Controller:<br/>DataCloudDataChangeEventController]
    end

    subgraph LLM["🟡 AI/LLM PROCESSING"]
        K[GenerateSearchContextInvocable]
        L[Salesforce Models API<br/>Claude Opus]
    end

    subgraph Output["🟢 CASE UPDATE"]
        M[Extract ssot__CaseId__c]
        N[Update Case Record<br/>• Description with AI Context<br/>• Intent Category<br/>• Keywords]
        O[Future: Route to Owner<br/>based on Intent]
    end

    subgraph Logging["⚪ DEBUG LOGGING"]
        P[Debug_Log__c Records]
    end

    A --> B
    B --> C
    B --> D
    D --> E
    E --> F
    F --> G
    G --> H
    H -->|"Enqueue to avoid<br/>callout restrictions"| I
    I --> J
    J --> K
    K --> L
    L -->|"Returns JSON:<br/>search_context<br/>keywords<br/>intent_category"| K
    K --> M
    M --> N
    N -.->|"Production Extension"| O
    J --> P

    style A fill:#2196F3,color:#fff
    style B fill:#4CAF50,color:#fff
    style C fill:#4CAF50,color:#fff
    style D fill:#9C27B0,color:#fff
    style E fill:#9C27B0,color:#fff
    style F fill:#9C27B0,color:#fff
    style G fill:#FF9800,color:#fff
    style H fill:#F44336,color:#fff
    style I fill:#F44336,color:#fff
    style J fill:#F44336,color:#fff
    style K fill:#FFEB3B,color:#000
    style L fill:#FFEB3B,color:#000
    style M fill:#4CAF50,color:#fff
    style N fill:#4CAF50,color:#fff
    style O fill:#4CAF50,color:#fff,stroke-dasharray: 5 5
    style P fill:#9E9E9E,color:#fff
```

---

## Color Legend

| Color | Component Type | Description |
|-------|---------------|-------------|
| 🔵 **Blue** | Customer Interaction | External customer touchpoint |
| 🟢 **Green** | Salesforce Core / Output | Standard Salesforce objects and final Case updates |
| 🟣 **Purple** | Data Cloud | Data Model Objects, Vector Search, Data Actions |
| 🟠 **Orange** | Platform Events | Asynchronous event-driven messaging |
| 🔴 **Red** | Apex Processing | Trigger, Queueable, and Controller logic |
| 🟡 **Yellow** | AI/LLM | Intelligent context generation using Models API |
| ⚪ **Gray** | Logging | Debug and audit trail |

---

## Component Details

### 1. Trigger Layer
**File:** `DataObjectDataChgEventHandler.trigger`

```apex
trigger DataObjectDataChgEventHandler on DataObjectDataChgEvent (after insert) {
    System.enqueueJob(new DataCloudDataChangeEventQueueable(Trigger.new));
}
```

- Listens for `DataObjectDataChgEvent` platform events
- Immediately enqueues processing to avoid callout restrictions in trigger context

---

### 2. Queueable Layer
**File:** `DataCloudDataChangeEventQueueable.cls`

- Implements `Queueable` and `Database.AllowsCallouts`
- Enables HTTP callouts (required for LLM API calls)
- Delegates to controller for actual processing

---

### 3. Controller Layer
**File:** `DataCloudDataChangeEventController.cls`

**Responsibilities:**
1. **Extract Event Metadata:** EventType, EventUuid, ActionDeveloperName, etc.
2. **Parse Payload:** Deserialize `PayloadCurrentValue` JSON
3. **Extract Case Link:** Get `ssot__CaseId__c` for Case update
4. **Call LLM Service:** Generate search context, keywords, and intent category
5. **Update Case Record:** Append AI-generated context to Case description
6. **Debug Logging:** Create `Debug_Log__c` records for audit trail

---

### 4. LLM Invocable
**File:** `GenerateSearchContextInvocable.cls`

**Input Fields:**
| Field | Source from Payload |
|-------|---------------------|
| `caseSubject` | `ssot__Subject__c` |
| `caseDescription` | `ssot__EmailMessageText__c` |
| `caseName` | `ssot__Name__c` |
| `caseComments` | Derived from metadata hints |

**Output Fields:**
| Field | Description |
|-------|-------------|
| `searchContext` | Semantic search-optimized paragraph (2-4 sentences) |
| `keywords` | 5-10 high-value search keywords |
| `intentCategory` | One of: TROUBLESHOOTING, HOW_TO, BILLING, ACCOUNT, FEATURE_REQUEST, GENERAL_INQUIRY, COMPLAINT, INTEGRATION |

---

## Data Cloud Payload Structure

### Key Fields in PayloadCurrentValue

```json
{
  "ssot__CaseId__c": "500al00000mfMVZAA2",       // ← Case to update
  "ssot__Subject__c": "Smart Thermostat...",     // ← Email subject
  "ssot__EmailMessageText__c": "Hello, I...",    // ← Email body
  "ssot__Name__c": "Smart Thermostat...",        // ← Name field
  "ssot__FromAddress__c": "customer@email.com",  // ← Sender
  "ssot__DataSourceObjectId__c": "EmailMessage", // ← Source object type
  "relevantResults": [...]                       // ← Vector search results from Data Cloud
}
```

### Event Metadata

```json
{
  "EventType": "CDCEvent",
  "EventPrompt": "INSERT",
  "ActionDeveloperName": "Email_Case_Classification",
  "SourceObjectDeveloperName": "ssot__EmailMessage__dlm"
}
```

---

## Case Update Logic (Demo)

The system updates the Case record with AI-generated context:

```
┌─────────────────────────────────────────────────────────────────┐
│ CASE: 500al00000mfMVZAA2                                        │
├─────────────────────────────────────────────────────────────────┤
│ Description (Updated):                                          │
│ ─────────────────────────────────────────────────────────────── │
│ [Original Description]                                          │
│                                                                 │
│ ═══════════════════════════════════════════════════════════════ │
│ AI CLASSIFICATION (2026-02-10T21:27:43Z)                        │
│ ─────────────────────────────────────────────────────────────── │
│ Intent Category: TROUBLESHOOTING                                │
│ Keywords: smart thermostat, model 89008x, unresponsive,         │
│           Wi-Fi connection, device offline, frozen screen       │
│ Search Context: Customer reports smart thermostat Model #89008x │
│                 became unresponsive after one month of use.     │
│                 Device shows frozen screen, won't connect to    │
│                 Wi-Fi, and app displays "device offline" error. │
└─────────────────────────────────────────────────────────────────┘
```

---

## Future Enhancement: Case Owner Routing

With the `intentCategory` classification, the system can route Cases to appropriate teams:

| Intent Category | Potential Owner/Queue |
|-----------------|----------------------|
| `TROUBLESHOOTING` | Technical Support Queue |
| `HOW_TO` | Product Training Team |
| `BILLING` | Billing Department Queue |
| `ACCOUNT` | Account Services Queue |
| `FEATURE_REQUEST` | Product Management Queue |
| `COMPLAINT` | Customer Escalations Queue |
| `INTEGRATION` | API Support Team |

---

## Sequence Diagram

```mermaid
sequenceDiagram
    participant Customer
    participant Email2Case as Email-to-Case
    participant DC as Data Cloud
    participant PE as Platform Event
    participant Trigger
    participant Queue as Queueable
    participant Ctrl as Controller
    participant LLM as Models API
    participant Case
    participant Log as Debug_Log__c

    Customer->>Email2Case: Sends Email
    Email2Case->>DC: Sync EmailMessage to DMO
    DC->>DC: Run Vector Search
    DC->>PE: Publish DataObjectDataChgEvent
    PE->>Trigger: after insert
    Trigger->>Queue: enqueueJob()
    Queue->>Ctrl: processEvents()
    
    rect rgb(255, 240, 200)
        Note over Ctrl,LLM: PHASE 1: CALLOUTS ONLY
        Ctrl->>Ctrl: Parse PayloadCurrentValue
        Ctrl->>LLM: Generate Search Context
        LLM-->>Ctrl: {searchContext, keywords, intentCategory}
        Ctrl->>Ctrl: Collect results (no DML)
    end
    
    rect rgb(200, 255, 200)
        Note over Ctrl,Log: PHASE 2: DML ONLY
        Ctrl->>Case: Bulk Update Descriptions
        Ctrl->>Log: Bulk Insert Debug_Log__c
    end
```

---

## Critical Architecture Note: Two-Phase Processing

⚠️ **Salesforce Limitation:** You cannot perform callouts after uncommitted DML in the same transaction.

The controller uses a **two-phase approach** to handle this:

```
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 1: CALLOUTS (No DML allowed)                              │
├─────────────────────────────────────────────────────────────────┤
│ • Loop through all events                                       │
│ • Call LLM API for each event (callout)                        │
│ • Collect EventProcessingResult objects                         │
│ • NO database operations here                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 2: DML (All callouts complete)                            │
├─────────────────────────────────────────────────────────────────┤
│ • Build Case update records from results                        │
│ • Build Debug_Log__c records from results                       │
│ • Database.update(casesToUpdate, false) - bulk                  │
│ • Database.insert(logsToInsert, false) - bulk                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Files Reference

| File | Type | Purpose |
|------|------|---------|
| [DataObjectDataChgEventHandler.trigger](force-app/main/default/triggers/DataObjectDataChgEventHandler.trigger) | Trigger | Entry point for platform events |
| [DataCloudDataChangeEventQueueable.cls](force-app/main/default/classes/DataCloudDataChangeEventQueueable.cls) | Queueable | Enables callouts in async context |
| [DataCloudDataChangeEventController.cls](force-app/main/default/classes/DataCloudDataChangeEventController.cls) | Controller | Main processing logic |
| [GenerateSearchContextInvocable.cls](force-app/main/default/classes/GenerateSearchContextInvocable.cls) | Invocable | LLM integration for AI classification |

---

## Error Handling

1. **LLM Failure:** Falls back to concatenated subject + description
2. **Case Not Found:** Logs error to Debug_Log__c, continues processing
3. **DML Failure:** Uses `Database.update()` with `allOrNone=false` for partial success

---

*Last Updated: February 10, 2026*
