;; Data Collection Contract
;; Gathers and stores financial performance metrics

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_DATA_EXISTS (err u301))
(define-constant ERR_DATA_NOT_FOUND (err u302))
(define-constant ERR_INVALID_INSTITUTION (err u303))

;; Financial data structure
(define-map financial-data
  { institution-id: uint, reporting-period: uint }
  {
    total-assets: uint,
    total-liabilities: uint,
    tier1-capital: uint,
    risk-weighted-assets: uint,
    net-income: int,
    loan-portfolio: uint,
    deposits: uint,
    liquidity-ratio: uint,
    leverage-ratio: uint,
    submission-date: uint
  }
)

;; Submit financial data for an institution
(define-public (submit-financial-data
  (institution-id uint)
  (reporting-period uint)
  (total-assets uint)
  (total-liabilities uint)
  (tier1-capital uint)
  (risk-weighted-assets uint)
  (net-income int)
  (loan-portfolio uint)
  (deposits uint)
  (liquidity-ratio uint)
  (leverage-ratio uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> institution-id u0) ERR_INVALID_INSTITUTION)
    (asserts! (is-none (map-get? financial-data { institution-id: institution-id, reporting-period: reporting-period })) ERR_DATA_EXISTS)

    (map-set financial-data
      { institution-id: institution-id, reporting-period: reporting-period }
      {
        total-assets: total-assets,
        total-liabilities: total-liabilities,
        tier1-capital: tier1-capital,
        risk-weighted-assets: risk-weighted-assets,
        net-income: net-income,
        loan-portfolio: loan-portfolio,
        deposits: deposits,
        liquidity-ratio: liquidity-ratio,
        leverage-ratio: leverage-ratio,
        submission-date: block-height
      }
    )
    (ok true)
  )
)

;; Get financial data for an institution and period
(define-read-only (get-financial-data (institution-id uint) (reporting-period uint))
  (map-get? financial-data { institution-id: institution-id, reporting-period: reporting-period })
)

;; Calculate capital adequacy ratio
(define-read-only (calculate-capital-ratio (institution-id uint) (reporting-period uint))
  (match (map-get? financial-data { institution-id: institution-id, reporting-period: reporting-period })
    data (if (> (get risk-weighted-assets data) u0)
           (some (/ (* (get tier1-capital data) u100) (get risk-weighted-assets data)))
           none)
    none
  )
)

;; Calculate asset quality ratio
(define-read-only (calculate-asset-quality (institution-id uint) (reporting-period uint))
  (match (map-get? financial-data { institution-id: institution-id, reporting-period: reporting-period })
    data (if (> (get total-assets data) u0)
           (some (/ (* (get loan-portfolio data) u100) (get total-assets data)))
           none)
    none
  )
)
