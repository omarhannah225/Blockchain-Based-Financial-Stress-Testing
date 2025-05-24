;; Regulatory Reporting Contract
;; Submits stress test results to regulatory authorities

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_REPORT_EXISTS (err u501))
(define-constant ERR_REPORT_NOT_FOUND (err u502))
(define-constant ERR_INVALID_AUTHORITY (err u503))

;; Regulatory report structure
(define-map regulatory-reports
  { report-id: uint }
  {
    institution-id: uint,
    scenario-id: uint,
    test-date: uint,
    regulatory-authority: (string-ascii 50),
    compliance-status: (string-ascii 20),
    submission-date: uint,
    report-hash: (buff 32),
    approved: bool,
    reviewer: (optional principal)
  }
)

;; Track report count
(define-data-var report-counter uint u0)

;; Authorized regulatory authorities
(define-map authorized-authorities
  { authority-name: (string-ascii 50) }
  { authorized: bool, registration-date: uint }
)

;; Register regulatory authority
(define-public (register-authority (authority-name (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set authorized-authorities
      { authority-name: authority-name }
      { authorized: true, registration-date: block-height }
    )
    (ok true)
  )
)

;; Submit regulatory report
(define-public (submit-regulatory-report
  (institution-id uint)
  (scenario-id uint)
  (test-date uint)
  (regulatory-authority (string-ascii 50))
  (compliance-status (string-ascii 20))
  (report-hash (buff 32)))
  (let ((report-id (+ (var-get report-counter) u1)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? authorized-authorities { authority-name: regulatory-authority })) ERR_INVALID_AUTHORITY)

    (map-set regulatory-reports
      { report-id: report-id }
      {
        institution-id: institution-id,
        scenario-id: scenario-id,
        test-date: test-date,
        regulatory-authority: regulatory-authority,
        compliance-status: compliance-status,
        submission-date: block-height,
        report-hash: report-hash,
        approved: false,
        reviewer: none
      }
    )
    (var-set report-counter report-id)
    (ok report-id)
  )
)

;; Approve regulatory report
(define-public (approve-report (report-id uint))
  (let ((report (unwrap! (map-get? regulatory-reports { report-id: report-id }) ERR_REPORT_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set regulatory-reports
      { report-id: report-id }
      (merge report { approved: true, reviewer: (some tx-sender) })
    )
    (ok true)
  )
)

;; Get regulatory report
(define-read-only (get-regulatory-report (report-id uint))
  (map-get? regulatory-reports { report-id: report-id })
)

;; Check if authority is authorized
(define-read-only (is-authority-authorized (authority-name (string-ascii 50)))
  (match (map-get? authorized-authorities { authority-name: authority-name })
    authority (get authorized authority)
    false
  )
)

;; Get total reports count
(define-read-only (get-report-count)
  (var-get report-counter)
)
