;; Carrier Verification Contract
;; This contract validates legitimate transportation companies

(define-data-var admin principal tx-sender)

;; Map to store verified carriers
(define-map verified-carriers principal
  {
    company-name: (string-utf8 100),
    license-number: (string-utf8 50),
    verified: bool,
    verification-date: uint
  }
)

;; Public function to register a carrier (can only be called by the carrier themselves)
(define-public (register-carrier (company-name (string-utf8 100)) (license-number (string-utf8 50)))
  (let ((caller tx-sender))
    (if (is-none (map-get? verified-carriers caller))
        (ok (map-set verified-carriers caller {
          company-name: company-name,
          license-number: license-number,
          verified: false,
          verification-date: u0
        }))
        (err u1) ;; Error code 1: Carrier already registered
    )
  )
)

;; Admin function to verify a carrier
(define-public (verify-carrier (carrier principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (match (map-get? verified-carriers carrier)
          carrier-data (ok (map-set verified-carriers carrier
            (merge carrier-data {
              verified: true,
              verification-date: block-height
            })
          ))
          (err u3) ;; Error code 3: Carrier not found
        )
        (err u2) ;; Error code 2: Not authorized
    )
  )
)

;; Public function to check if a carrier is verified
(define-read-only (is-verified-carrier (carrier principal))
  (match (map-get? verified-carriers carrier)
    carrier-data (get verified carrier-data)
    false
  )
)

;; Public function to get carrier details
(define-read-only (get-carrier-details (carrier principal))
  (map-get? verified-carriers carrier)
)

;; Admin function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (let ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (ok (var-set admin new-admin))
        (err u2) ;; Error code 2: Not authorized
    )
  )
)
