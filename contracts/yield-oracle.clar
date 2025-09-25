;; Yield Oracle Smart Contract
;; Process satellite and weather data to trigger automatic crop insurance payouts
;; Agricultural yield prediction and parametric insurance automation

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-POLICY-NOT-FOUND (err u101))
(define-constant ERR-INVALID-DATA (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-POLICY-EXPIRED (err u104))
(define-constant ERR-PAYOUT-ALREADY-CLAIMED (err u105))
(define-constant ERR-THRESHOLD-NOT-MET (err u106))
(define-constant ERR-INVALID-CROP-TYPE (err u107))
(define-constant ERR-ORACLE-NOT-AUTHORIZED (err u108))
(define-constant ERR-POLICY-NOT-ACTIVE (err u109))

;; Crop Types
(define-constant CROP-WHEAT u1)
(define-constant CROP-CORN u2)
(define-constant CROP-RICE u3)
(define-constant CROP-SOYBEANS u4)
(define-constant CROP-COTTON u5)
(define-constant CROP-BARLEY u6)

;; Policy Status
(define-constant POLICY-ACTIVE u1)
(define-constant POLICY-EXPIRED u2)
(define-constant POLICY-CLAIMED u3)
(define-constant POLICY-CANCELLED u4)

;; Risk Levels
(define-constant RISK-LOW u1)
(define-constant RISK-MEDIUM u2)
(define-constant RISK-HIGH u3)
(define-constant RISK-CRITICAL u4)

;; Platform Configuration
(define-constant MIN-POLICY-AMOUNT u1000000) ;; 1 STX minimum
(define-constant MAX-POLICY-AMOUNT u100000000000) ;; 100,000 STX maximum
(define-constant PLATFORM-FEE-RATE u200) ;; 2% platform fee
(define-constant ORACLE-UPDATE-THRESHOLD u144) ;; ~1 day in blocks

;; Data Variables
(define-data-var policy-counter uint u0)
(define-data-var oracle-counter uint u0)
(define-data-var total-policies-value uint u0)
(define-data-var total-payouts uint u0)
(define-data-var platform-reserves uint u0)

;; Authorized Oracles
(define-map authorized-oracles
    principal
    {
        name: (string-ascii 64),
        data-type: (string-ascii 32), ;; "weather", "satellite", "market"
        is-active: bool,
        last-update: uint,
        update-count: uint
    }
)

;; Insurance Policies
(define-map insurance-policies
    uint ;; policy-id
    {
        farmer: principal,
        crop-type: uint,
        location-lat: int, ;; latitude * 1000000
        location-lng: int, ;; longitude * 1000000
        planted-area: uint, ;; hectares * 100
        coverage-amount: uint,
        premium-paid: uint,
        policy-start: uint,
        policy-end: uint,
        status: uint,
        expected-yield: uint, ;; tons per hectare * 1000
        minimum-yield-threshold: uint, ;; percentage * 100
        weather-triggers: (list 5 (string-ascii 32)),
        satellite-triggers: (list 5 (string-ascii 32))
    }
)

;; Weather Data
(define-map weather-data
    {location-lat: int, location-lng: int, date: uint}
    {
        temperature-min: int, ;; celsius * 100
        temperature-max: int, ;; celsius * 100
        precipitation: uint, ;; mm * 100
        humidity: uint, ;; percentage * 100
        wind-speed: uint, ;; km/h * 100
        oracle: principal,
        timestamp: uint,
        verified: bool
    }
)

;; Satellite Data
(define-map satellite-data
    {location-lat: int, location-lng: int, date: uint}
    {
        ndvi: uint, ;; normalized * 10000
        evi: uint, ;; enhanced vegetation index * 10000
        soil-moisture: uint, ;; percentage * 100
        land-surface-temp: int, ;; celsius * 100
        cloud-cover: uint, ;; percentage * 100
        oracle: principal,
        timestamp: uint,
        verified: bool
    }
)

;; Yield Predictions
(define-map yield-predictions
    uint ;; policy-id
    {
        predicted-yield: uint, ;; tons per hectare * 1000
        confidence-level: uint, ;; percentage * 100
        risk-factors: (list 10 (string-ascii 32)),
        last-updated: uint,
        prediction-model: (string-ascii 32),
        oracle: principal
    }
)

;; Policy Payouts
(define-map policy-payouts
    uint ;; policy-id
    {
        payout-amount: uint,
        trigger-reason: (string-ascii 128),
        yield-loss-percentage: uint, ;; percentage * 100
        payout-date: uint,
        evidence-hash: (buff 32),
        processed-by: principal
    }
)

;; Historical Yields
(define-map historical-yields
    {location-lat: int, location-lng: int, crop-type: uint, year: uint}
    {
        actual-yield: uint, ;; tons per hectare * 1000
        weather-conditions: (string-ascii 256),
        recorded-by: principal,
        verified: bool
    }
)

;; Risk Assessment
(define-map risk-assessments
    {location-lat: int, location-lng: int, crop-type: uint}
    {
        drought-risk: uint, ;; 0-100 scale
        flood-risk: uint, ;; 0-100 scale
        frost-risk: uint, ;; 0-100 scale
        pest-risk: uint, ;; 0-100 scale
        overall-risk: uint, ;; 0-100 scale
        last-assessed: uint,
        assessor: principal
    }
)

;; Public Functions

;; Add authorized oracle
(define-public (add-oracle
    (oracle principal)
    (name (string-ascii 64))
    (data-type (string-ascii 32))
    )
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        
        (map-set authorized-oracles oracle {
            name: name,
            data-type: data-type,
            is-active: true,
            last-update: u0,
            update-count: u0
        })
        
        (var-set oracle-counter (+ (var-get oracle-counter) u1))
        (ok true)
    )
)

;; Create insurance policy
(define-public (create-policy
    (crop-type uint)
    (location-lat int)
    (location-lng int)
    (planted-area uint)
    (coverage-amount uint)
    (policy-duration uint)
    (minimum-yield-threshold uint)
    (weather-triggers (list 5 (string-ascii 32)))
    (satellite-triggers (list 5 (string-ascii 32)))
    )
    (let
        (
            (policy-id (+ (var-get policy-counter) u1))
            (premium (calculate-premium-amount crop-type location-lat location-lng planted-area coverage-amount))
            (platform-fee (/ (* premium PLATFORM-FEE-RATE) u10000))
            (net-premium (- premium platform-fee))
        )
        ;; Validate inputs
        (asserts! (and (>= crop-type u1) (<= crop-type u6)) ERR-INVALID-CROP-TYPE)
        (asserts! (and (>= coverage-amount MIN-POLICY-AMOUNT) (<= coverage-amount MAX-POLICY-AMOUNT)) ERR-INVALID-DATA)
        (asserts! (> planted-area u0) ERR-INVALID-DATA)
        (asserts! (> policy-duration u0) ERR-INVALID-DATA)
        
        ;; Transfer premium
        (try! (stx-transfer? premium tx-sender (as-contract tx-sender)))
        
        ;; Create policy
        (map-set insurance-policies policy-id {
            farmer: tx-sender,
            crop-type: crop-type,
            location-lat: location-lat,
            location-lng: location-lng,
            planted-area: planted-area,
            coverage-amount: coverage-amount,
            premium-paid: premium,
            policy-start: stacks-block-height,
            policy-end: (+ stacks-block-height policy-duration),
            status: POLICY-ACTIVE,
            expected-yield: (calculate-expected-yield crop-type location-lat location-lng),
            minimum-yield-threshold: minimum-yield-threshold,
            weather-triggers: weather-triggers,
            satellite-triggers: satellite-triggers
        })
        
        ;; Update platform statistics
        (var-set policy-counter policy-id)
        (var-set total-policies-value (+ (var-get total-policies-value) coverage-amount))
        (var-set platform-reserves (+ (var-get platform-reserves) platform-fee))
        
        (ok policy-id)
    )
)

;; Update weather data (oracle function)
(define-public (update-weather-data
    (location-lat int)
    (location-lng int)
    (date uint)
    (temperature-min int)
    (temperature-max int)
    (precipitation uint)
    (humidity uint)
    (wind-speed uint)
    )
    (let
        (
            (oracle-info (unwrap! (map-get? authorized-oracles tx-sender) ERR-ORACLE-NOT-AUTHORIZED))
        )
        ;; Validate oracle authorization
        (asserts! (get is-active oracle-info) ERR-ORACLE-NOT-AUTHORIZED)
        (asserts! (is-eq (get data-type oracle-info) "weather") ERR-ORACLE-NOT-AUTHORIZED)
        
        ;; Store weather data
        (map-set weather-data {location-lat: location-lat, location-lng: location-lng, date: date} {
            temperature-min: temperature-min,
            temperature-max: temperature-max,
            precipitation: precipitation,
            humidity: humidity,
            wind-speed: wind-speed,
            oracle: tx-sender,
            timestamp: stacks-block-height,
            verified: true
        })
        
        ;; Update oracle statistics
        (map-set authorized-oracles tx-sender
            (merge oracle-info {
                last-update: stacks-block-height,
                update-count: (+ (get update-count oracle-info) u1)
            })
        )
        
        (ok true)
    )
)

;; Update satellite data (oracle function)
(define-public (update-satellite-data
    (location-lat int)
    (location-lng int)
    (date uint)
    (ndvi uint)
    (evi uint)
    (soil-moisture uint)
    (land-surface-temp int)
    (cloud-cover uint)
    )
    (let
        (
            (oracle-info (unwrap! (map-get? authorized-oracles tx-sender) ERR-ORACLE-NOT-AUTHORIZED))
        )
        ;; Validate oracle authorization
        (asserts! (get is-active oracle-info) ERR-ORACLE-NOT-AUTHORIZED)
        (asserts! (is-eq (get data-type oracle-info) "satellite") ERR-ORACLE-NOT-AUTHORIZED)
        
        ;; Store satellite data
        (map-set satellite-data {location-lat: location-lat, location-lng: location-lng, date: date} {
            ndvi: ndvi,
            evi: evi,
            soil-moisture: soil-moisture,
            land-surface-temp: land-surface-temp,
            cloud-cover: cloud-cover,
            oracle: tx-sender,
            timestamp: stacks-block-height,
            verified: true
        })
        
        ;; Update oracle statistics
        (map-set authorized-oracles tx-sender
            (merge oracle-info {
                last-update: stacks-block-height,
                update-count: (+ (get update-count oracle-info) u1)
            })
        )
        
        (ok true)
    )
)

;; Process payout for policy
(define-public (process-payout
    (policy-id uint)
    (trigger-reason (string-ascii 128))
    (yield-loss-percentage uint)
    (evidence-hash (buff 32))
    )
    (let
        (
            (policy (unwrap! (map-get? insurance-policies policy-id) ERR-POLICY-NOT-FOUND))
            (oracle-info (unwrap! (map-get? authorized-oracles tx-sender) ERR-ORACLE-NOT-AUTHORIZED))
            (payout-amount (/ (* (get coverage-amount policy) yield-loss-percentage) u10000))
        )
        ;; Validate payout conditions
        (asserts! (get is-active oracle-info) ERR-ORACLE-NOT-AUTHORIZED)
        (asserts! (is-eq (get status policy) POLICY-ACTIVE) ERR-POLICY-NOT-ACTIVE)
        (asserts! (<= stacks-block-height (get policy-end policy)) ERR-POLICY-EXPIRED)
        (asserts! (>= yield-loss-percentage (get minimum-yield-threshold policy)) ERR-THRESHOLD-NOT-MET)
        
        ;; Transfer payout to farmer
        (try! (as-contract (stx-transfer? payout-amount tx-sender (get farmer policy))))
        
        ;; Record payout
        (map-set policy-payouts policy-id {
            payout-amount: payout-amount,
            trigger-reason: trigger-reason,
            yield-loss-percentage: yield-loss-percentage,
            payout-date: stacks-block-height,
            evidence-hash: evidence-hash,
            processed-by: tx-sender
        })
        
        ;; Update policy status
        (map-set insurance-policies policy-id
            (merge policy {status: POLICY-CLAIMED})
        )
        
        ;; Update platform statistics
        (var-set total-payouts (+ (var-get total-payouts) payout-amount))
        
        (ok payout-amount)
    )
)

;; Update yield prediction
(define-public (update-yield-prediction
    (policy-id uint)
    (predicted-yield uint)
    (confidence-level uint)
    (risk-factors (list 10 (string-ascii 32)))
    (prediction-model (string-ascii 32))
    )
    (let
        (
            (policy (unwrap! (map-get? insurance-policies policy-id) ERR-POLICY-NOT-FOUND))
            (oracle-info (unwrap! (map-get? authorized-oracles tx-sender) ERR-ORACLE-NOT-AUTHORIZED))
        )
        ;; Validate oracle authorization
        (asserts! (get is-active oracle-info) ERR-ORACLE-NOT-AUTHORIZED)
        (asserts! (is-eq (get status policy) POLICY-ACTIVE) ERR-POLICY-NOT-ACTIVE)
        
        ;; Update yield prediction
        (map-set yield-predictions policy-id {
            predicted-yield: predicted-yield,
            confidence-level: confidence-level,
            risk-factors: risk-factors,
            last-updated: stacks-block-height,
            prediction-model: prediction-model,
            oracle: tx-sender
        })
        
        ;; Check if payout should be triggered based on prediction
        (if (< predicted-yield (/ (* (get expected-yield policy) (get minimum-yield-threshold policy)) u10000))
            (let
                (
                    (loss-percentage (/ (* (- (get expected-yield policy) predicted-yield) u10000) (get expected-yield policy)))
                )
                (begin (try! (process-payout policy-id "Low yield prediction" loss-percentage 0x00)) true)
            )
            true
        )
        
        (ok true)
    )
)

;; Private Functions

;; Calculate premium amount
(define-private (calculate-premium-amount
    (crop-type uint)
    (location-lat int)
    (location-lng int)
    (planted-area uint)
    (coverage-amount uint)
    )
    (let
        (
            (base-rate u300) ;; 3% base rate
            (area-multiplier (/ planted-area u100)) ;; area factor
            (risk-multiplier (get-location-risk-multiplier location-lat location-lng crop-type))
        )
        (/ (* (* coverage-amount base-rate) (+ u100 (* area-multiplier risk-multiplier))) u1000000)
    )
)

;; Get location risk multiplier
(define-private (get-location-risk-multiplier
    (location-lat int)
    (location-lng int)
    (crop-type uint)
    )
    ;; Simplified risk calculation (in production would use complex models)
    (if (> location-lat 45000000) ;; Northern regions
        u150 ;; 1.5x multiplier
        (if (< location-lat -30000000) ;; Southern regions
            u120 ;; 1.2x multiplier
            u100 ;; 1.0x baseline
        )
    )
)

;; Calculate expected yield
(define-private (calculate-expected-yield
    (crop-type uint)
    (location-lat int)
    (location-lng int)
    )
    ;; Simplified yield calculation based on crop type and location
    (if (is-eq crop-type CROP-WHEAT)
        u3500 ;; 3.5 tons per hectare
        (if (is-eq crop-type CROP-CORN)
            u9000 ;; 9.0 tons per hectare
            (if (is-eq crop-type CROP-RICE)
                u4500 ;; 4.5 tons per hectare
                u2500 ;; default yield
            )
        )
    )
)

;; Check weather triggers
(define-private (check-weather-triggers
    (location-lat int)
    (location-lng int)
    (date uint)
    )
    ;; Simplified trigger checking (in production would be more sophisticated)
    (ok true)
)

;; Check satellite triggers
(define-private (check-satellite-triggers
    (location-lat int)
    (location-lng int)
    (date uint)
    )
    ;; Simplified trigger checking (in production would be more sophisticated)
    (ok true)
)

;; Read-Only Functions

;; Get policy details
(define-read-only (get-policy (policy-id uint))
    (map-get? insurance-policies policy-id)
)

;; Get weather data
(define-read-only (get-weather-data (location-lat int) (location-lng int) (date uint))
    (map-get? weather-data {location-lat: location-lat, location-lng: location-lng, date: date})
)

;; Get satellite data
(define-read-only (get-satellite-data (location-lat int) (location-lng int) (date uint))
    (map-get? satellite-data {location-lat: location-lat, location-lng: location-lng, date: date})
)

;; Get yield prediction
(define-read-only (get-yield-prediction (policy-id uint))
    (map-get? yield-predictions policy-id)
)

;; Get policy payout
(define-read-only (get-policy-payout (policy-id uint))
    (map-get? policy-payouts policy-id)
)

;; Get oracle info
(define-read-only (get-oracle-info (oracle principal))
    (map-get? authorized-oracles oracle)
)

;; Get platform statistics
(define-read-only (get-platform-stats)
    {
        total-policies: (var-get policy-counter),
        total-oracles: (var-get oracle-counter),
        total-policies-value: (var-get total-policies-value),
        total-payouts: (var-get total-payouts),
        platform-reserves: (var-get platform-reserves)
    }
)

;; Calculate premium quote
(define-read-only (calculate-premium-quote
    (crop-type uint)
    (location-lat int)
    (location-lng int)
    (planted-area uint)
    (coverage-amount uint)
    )
    (calculate-premium-amount crop-type location-lat location-lng planted-area coverage-amount)
)

;; Get risk assessment
(define-read-only (get-risk-assessment (location-lat int) (location-lng int) (crop-type uint))
    (map-get? risk-assessments {location-lat: location-lat, location-lng: location-lng, crop-type: crop-type})
)

;; Get historical yield
(define-read-only (get-historical-yield (location-lat int) (location-lng int) (crop-type uint) (year uint))
    (map-get? historical-yields {location-lat: location-lat, location-lng: location-lng, crop-type: crop-type, year: year})
)
