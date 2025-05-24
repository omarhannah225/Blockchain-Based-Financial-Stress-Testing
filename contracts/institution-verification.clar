;; Institution Verification Contract
;; Validates and manages financial entities eligible for stress testing

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INSTITUTION_EXISTS (err u101))
(define-constant ERR_INSTITUTION_NOT_FOUND (err u102))
(define-constant ERR_INVALID_LICENSE (err u103))

;; Institution data structure
(define-map institutions
  { institution-id: uint }
  {
    name: (string-ascii 100),
    license-number: (string-ascii 50),
    institution-type: (string-ascii 20),
    verified: bool,
    registration-date: uint,
    last-updated: uint
  }
)

;; Track institution count
(define-data-var institution-counter uint u0)

;; Register a new financial institution
(define-public (register-institution
  (name (string-ascii 100))
  (license-number (string-ascii 50))
  (institution-type (string-ascii 20)))
  (let ((institution-id (+ (var-get institution-counter) u1)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? institutions { institution-id: institution-id })) ERR_INSTITUTION_EXISTS)

    (map-set institutions
      { institution-id: institution-id }
      {
        name: name,
        license-number: license-number,
        institution-type: institution-type,
        verified: false,
        registration-date: block-height,
        last-updated: block-height
      }
    )
    (var-set institution-counter institution-id)
    (ok institution-id)
  )
)

;; Verify an institution
(define-public (verify-institution (institution-id uint))
  (let ((institution (unwrap! (map-get? institutions { institution-id: institution-id }) ERR_INSTITUTION_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set institutions
      { institution-id: institution-id }
      (merge institution { verified: true, last-updated: block-height })
    )
    (ok true)
  )
)

;; Get institution details
(define-read-only (get-institution (institution-id uint))
  (map-get? institutions { institution-id: institution-id })
)

;; Check if institution is verified
(define-read-only (is-institution-verified (institution-id uint))
  (match (map-get? institutions { institution-id: institution-id })
    institution (get verified institution)
    false
  )
)

;; Get total institutions count
(define-read-only (get-institution-count)
  (var-get institution-counter)
)
