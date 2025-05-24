;; Risk Calculation Contract
;; Computes stress test results based on scenarios and financial data

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_RESULT_EXISTS (err u401))
(define-constant ERR_RESULT_NOT_FOUND (err u402))
(define-constant ERR_INVALID_INPUT (err u403))

;; Stress test results structure
(define-map stress-test-results
  { institution-id: uint, scenario-id: uint, test-date: uint }
  {
    pre-stress-capital-ratio: uint,
    post-stress-capital-ratio: uint,
    capital-shortfall: uint,
    liquidity-impact: uint,
    credit-loss-impact: uint,
    market-risk-impact: uint,
    overall-risk-score: uint,
    pass-status: bool,
    calculation-date: uint
  }
)

;; Calculate and store stress test results
(define-public (calculate-stress-test
  (institution-id uint)
  (scenario-id uint)
  (test-date uint)
  (baseline-capital-ratio uint)
  (baseline-liquidity uint)
  (stress-multiplier uint))
  (let (
    (post-stress-capital (if (> baseline-capital-ratio stress-multiplier)
                           (- baseline-capital-ratio stress-multiplier)
                           u0))
    (liquidity-impact (/ (* baseline-liquidity stress-multiplier) u100))
    (capital-shortfall (if (< post-stress-capital u8) ;; 8% minimum
                        (- u8 post-stress-capital)
                        u0))
    (risk-score (+ stress-multiplier (/ capital-shortfall u2)))
    (pass-status (and (>= post-stress-capital u8) (<= risk-score u50)))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> institution-id u0) ERR_INVALID_INPUT)
    (asserts! (> scenario-id u0) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? stress-test-results { institution-id: institution-id, scenario-id: scenario-id, test-date: test-date })) ERR_RESULT_EXISTS)

    (map-set stress-test-results
      { institution-id: institution-id, scenario-id: scenario-id, test-date: test-date }
      {
        pre-stress-capital-ratio: baseline-capital-ratio,
        post-stress-capital-ratio: post-stress-capital,
        capital-shortfall: capital-shortfall,
        liquidity-impact: liquidity-impact,
        credit-loss-impact: (/ (* stress-multiplier u3) u10),
        market-risk-impact: (/ (* stress-multiplier u2) u10),
        overall-risk-score: risk-score,
        pass-status: pass-status,
        calculation-date: block-height
      }
    )
    (ok true)
  )
)

;; Get stress test results
(define-read-only (get-stress-test-result (institution-id uint) (scenario-id uint) (test-date uint))
  (map-get? stress-test-results { institution-id: institution-id, scenario-id: scenario-id, test-date: test-date })
)

;; Check if institution passed stress test
(define-read-only (did-institution-pass (institution-id uint) (scenario-id uint) (test-date uint))
  (match (map-get? stress-test-results { institution-id: institution-id, scenario-id: scenario-id, test-date: test-date })
    result (get pass-status result)
    false
  )
)

;; Calculate aggregate risk score for institution
(define-read-only (get-institution-risk-level (institution-id uint) (scenario-id uint) (test-date uint))
  (match (map-get? stress-test-results { institution-id: institution-id, scenario-id: scenario-id, test-date: test-date })
    result (get overall-risk-score result)
    u0
  )
)
