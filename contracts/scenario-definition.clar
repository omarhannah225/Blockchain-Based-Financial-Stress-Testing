;; Scenario Definition Contract
;; Records and manages stress test parameters and scenarios

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_SCENARIO_EXISTS (err u201))
(define-constant ERR_SCENARIO_NOT_FOUND (err u202))
(define-constant ERR_INVALID_PARAMETERS (err u203))

;; Scenario data structure
(define-map scenarios
  { scenario-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    severity-level: uint, ;; 1-5 scale
    interest-rate-shock: int, ;; basis points
    market-shock: int, ;; percentage points
    credit-loss-rate: uint, ;; percentage
    liquidity-stress: uint, ;; percentage
    created-date: uint,
    active: bool
  }
)

;; Track scenario count
(define-data-var scenario-counter uint u0)

;; Create a new stress test scenario
(define-public (create-scenario
  (name (string-ascii 100))
  (description (string-ascii 500))
  (severity-level uint)
  (interest-rate-shock int)
  (market-shock int)
  (credit-loss-rate uint)
  (liquidity-stress uint))
  (let ((scenario-id (+ (var-get scenario-counter) u1)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (and (>= severity-level u1) (<= severity-level u5)) ERR_INVALID_PARAMETERS)
    (asserts! (<= credit-loss-rate u100) ERR_INVALID_PARAMETERS)
    (asserts! (<= liquidity-stress u100) ERR_INVALID_PARAMETERS)

    (map-set scenarios
      { scenario-id: scenario-id }
      {
        name: name,
        description: description,
        severity-level: severity-level,
        interest-rate-shock: interest-rate-shock,
        market-shock: market-shock,
        credit-loss-rate: credit-loss-rate,
        liquidity-stress: liquidity-stress,
        created-date: block-height,
        active: true
      }
    )
    (var-set scenario-counter scenario-id)
    (ok scenario-id)
  )
)

;; Update scenario status
(define-public (toggle-scenario-status (scenario-id uint))
  (let ((scenario (unwrap! (map-get? scenarios { scenario-id: scenario-id }) ERR_SCENARIO_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set scenarios
      { scenario-id: scenario-id }
      (merge scenario { active: (not (get active scenario)) })
    )
    (ok true)
  )
)

;; Get scenario details
(define-read-only (get-scenario (scenario-id uint))
  (map-get? scenarios { scenario-id: scenario-id })
)

;; Check if scenario is active
(define-read-only (is-scenario-active (scenario-id uint))
  (match (map-get? scenarios { scenario-id: scenario-id })
    scenario (get active scenario)
    false
  )
)

;; Get total scenarios count
(define-read-only (get-scenario-count)
  (var-get scenario-counter)
)
