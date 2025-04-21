;; Performance Tracking Contract
;; Monitors on-time delivery and efficiency

(define-data-var admin principal tx-sender)

;; Map to store performance records
(define-map performance-records uint
  {
    carrier: principal,
    shipment-id: uint,
    route-id: uint,
    actual-duration: uint,
    actual-fuel: uint,
    on-time: bool,
    delivery-date: uint,
    efficiency-score: uint
  }
)

;; Map to store carrier performance metrics
(define-map carrier-metrics principal
  {
    total-deliveries: uint,
    on-time-deliveries: uint,
    average-efficiency: uint,
    last-updated: uint
  }
)

;; Counter for performance record IDs
(define-data-var record-id-counter uint u0)

;; Public function to record delivery performance
(define-public (record-performance
    (shipment-id uint)
    (route-id uint)
    (actual-duration uint)
    (actual-fuel uint)
    (on-time bool))
  (let (
      (caller tx-sender)
      (current-id (var-get record-id-counter))
      (efficiency-score (calculate-efficiency actual-duration actual-fuel))
    )
    ;; In a real implementation, we would check if the caller is the carrier of the shipment
    ;; For simplicity, we're allowing any caller to record performance
    (var-set record-id-counter (+ current-id u1))

    ;; Update carrier metrics
    (match (map-get? carrier-metrics caller)
      existing-metrics (map-set carrier-metrics caller
        (merge existing-metrics {
          total-deliveries: (+ (get total-deliveries existing-metrics) u1),
          on-time-deliveries: (+ (get on-time-deliveries existing-metrics) (if on-time u1 u0)),
          average-efficiency: (calculate-new-average
                               (get average-efficiency existing-metrics)
                               (get total-deliveries existing-metrics)
                               efficiency-score),
          last-updated: block-height
        }))
      ;; If no existing metrics, create new entry
      (map-set carrier-metrics caller {
        total-deliveries: u1,
        on-time-deliveries: (if on-time u1 u0),
        average-efficiency: efficiency-score,
        last-updated: block-height
      })
    )

    ;; Record the performance data
    (ok (map-set performance-records current-id {
      carrier: caller,
      shipment-id: shipment-id,
      route-id: route-id,
      actual-duration: actual-duration,
      actual-fuel: actual-fuel,
      on-time: on-time,
      delivery-date: block-height,
      efficiency-score: efficiency-score
    }))
  )
)

;; Helper function to calculate efficiency score (simplified)
(define-private (calculate-efficiency (duration uint) (fuel uint))
  ;; Simple efficiency calculation: lower is better
  ;; In a real implementation, this would be more sophisticated
  (if (> (* duration fuel) u0)
      (/ u10000 (* duration fuel))
      u100) ;; Default score if inputs are zero
)

;; Helper function to calculate new average
(define-private (calculate-new-average (old-avg uint) (old-count uint) (new-value uint))
  (/ (+ (* old-avg old-count) new-value) (+ old-count u1))
)

;; Public function to get performance record details
(define-read-only (get-performance-details (record-id uint))
  (map-get? performance-records record-id)
)

;; Public function to get carrier performance metrics
(define-read-only (get-carrier-metrics (carrier principal))
  (map-get? carrier-metrics carrier)
)

;; Public function to get on-time delivery rate for a carrier
(define-read-only (get-on-time-rate (carrier principal))
  (match (map-get? carrier-metrics carrier)
    metrics (if (> (get total-deliveries metrics) u0)
               (/ (* (get on-time-deliveries metrics) u100) (get total-deliveries metrics))
               u0)
    u0
  )
)
