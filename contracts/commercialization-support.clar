;; Commercialization Support Contract
;; Supports textile commercialization and market entry

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u500))
(define-constant err-not-found (err u501))
(define-constant err-unauthorized (err u502))
(define-constant err-insufficient-funds (err u503))

;; Commercialization stage constants
(define-constant stage-concept u1)
(define-constant stage-prototype u2)
(define-constant stage-pilot u3)
(define-constant stage-market-ready u4)

;; Commercialization project data structure
(define-map commercialization-projects
  { project-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    owner: principal,
    innovation-id: uint,
    stage: uint,
    funding-required: uint,
    funding-raised: uint,
    market-potential: (string-ascii 200),
    target-market: (string-ascii 100),
    created-date: uint
  }
)

;; Project counter
(define-data-var project-counter uint u0)

;; Funding rounds
(define-map funding-rounds
  { project-id: uint, round-id: uint }
  {
    round-type: (string-ascii 50),
    target-amount: uint,
    raised-amount: uint,
    investor-count: uint,
    start-date: uint,
    end-date: uint,
    active: bool
  }
)

;; Round counter per project
(define-map round-counters uint uint)

;; Investments
(define-map investments
  { project-id: uint, investor: principal }
  {
    amount: uint,
    investment-date: uint,
    equity-percentage: uint,
    terms: (string-ascii 200)
  }
)

;; Market validation data
(define-map market-validations
  { project-id: uint }
  {
    market-size: uint,
    competition-analysis: (string-ascii 300),
    customer-feedback: (string-ascii 300),
    validation-score: uint,
    validated-by: principal,
    validation-date: uint
  }
)

;; Create commercialization project
(define-public (create-project
  (title (string-ascii 100))
  (description (string-ascii 500))
  (innovation-id uint)
  (funding-required uint)
  (market-potential (string-ascii 200))
  (target-market (string-ascii 100)))
  (let ((project-id (+ (var-get project-counter) u1)))
    (map-set commercialization-projects
      { project-id: project-id }
      {
        title: title,
        description: description,
        owner: tx-sender,
        innovation-id: innovation-id,
        stage: stage-concept,
        funding-required: funding-required,
        funding-raised: u0,
        market-potential: market-potential,
        target-market: target-market,
        created-date: block-height
      }
    )
    (var-set project-counter project-id)
    (map-set round-counters project-id u0)
    (ok project-id)
  )
)

;; Start funding round
(define-public (start-funding-round
  (project-id uint)
  (round-type (string-ascii 50))
  (target-amount uint)
  (end-date uint))
  (match (map-get? commercialization-projects { project-id: project-id })
    project-data
    (begin
      (asserts! (is-eq (get owner project-data) tx-sender) err-unauthorized)
      (let ((round-count (default-to u0 (map-get? round-counters project-id)))
            (round-id (+ round-count u1)))
        (map-set funding-rounds
          { project-id: project-id, round-id: round-id }
          {
            round-type: round-type,
            target-amount: target-amount,
            raised-amount: u0,
            investor-count: u0,
            start-date: block-height,
            end-date: end-date,
            active: true
          }
        )
        (map-set round-counters project-id round-id)
        (ok round-id)
      )
    )
    err-not-found
  )
)

;; Make investment
(define-public (invest
  (project-id uint)
  (amount uint)
  (equity-percentage uint)
  (terms (string-ascii 200)))
  (match (map-get? commercialization-projects { project-id: project-id })
    project-data
    (begin
      (map-set investments
        { project-id: project-id, investor: tx-sender }
        {
          amount: amount,
          investment-date: block-height,
          equity-percentage: equity-percentage,
          terms: terms
        }
      )
      ;; Update project funding
      (map-set commercialization-projects
        { project-id: project-id }
        (merge project-data { funding-raised: (+ (get funding-raised project-data) amount) })
      )
      (ok true)
    )
    err-not-found
  )
)

;; Update project stage
(define-public (update-project-stage (project-id uint) (new-stage uint))
  (match (map-get? commercialization-projects { project-id: project-id })
    project-data
    (begin
      (asserts! (is-eq (get owner project-data) tx-sender) err-unauthorized)
      (map-set commercialization-projects
        { project-id: project-id }
        (merge project-data { stage: new-stage })
      )
      (ok true)
    )
    err-not-found
  )
)

;; Add market validation
(define-public (add-market-validation
  (project-id uint)
  (market-size uint)
  (competition-analysis (string-ascii 300))
  (customer-feedback (string-ascii 300))
  (validation-score uint))
  (match (map-get? commercialization-projects { project-id: project-id })
    project-data
    (begin
      (map-set market-validations
        { project-id: project-id }
        {
          market-size: market-size,
          competition-analysis: competition-analysis,
          customer-feedback: customer-feedback,
          validation-score: validation-score,
          validated-by: tx-sender,
          validation-date: block-height
        }
      )
      (ok true)
    )
    err-not-found
  )
)

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? commercialization-projects { project-id: project-id })
)

;; Get funding round details
(define-read-only (get-funding-round (project-id uint) (round-id uint))
  (map-get? funding-rounds { project-id: project-id, round-id: round-id })
)

;; Get investment details
(define-read-only (get-investment (project-id uint) (investor principal))
  (map-get? investments { project-id: project-id, investor: investor })
)

;; Get market validation
(define-read-only (get-market-validation (project-id uint))
  (map-get? market-validations { project-id: project-id })
)

;; Get total projects
(define-read-only (get-project-count)
  (var-get project-counter)
)
