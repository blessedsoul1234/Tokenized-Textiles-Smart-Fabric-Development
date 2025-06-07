;; Collaboration Framework Contract
;; Facilitates textile research collaboration between institutions

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u400))
(define-constant err-not-found (err u401))
(define-constant err-unauthorized (err u402))
(define-constant err-invalid-status (err u403))

;; Collaboration status constants
(define-constant status-proposed u1)
(define-constant status-active u2)
(define-constant status-completed u3)
(define-constant status-cancelled u4)

;; Collaboration data structure
(define-map collaborations
  { collaboration-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    lead-institution: uint,
    initiator: principal,
    status: uint,
    start-date: uint,
    end-date: uint,
    budget: uint,
    objectives: (string-ascii 300)
  }
)

;; Collaboration counter
(define-data-var collaboration-counter uint u0)

;; Collaboration participants
(define-map collaboration-participants
  { collaboration-id: uint, institution-id: uint }
  {
    role: (string-ascii 50),
    contribution: (string-ascii 200),
    joined-date: uint,
    active: bool
  }
)

;; Collaboration resources
(define-map collaboration-resources
  { collaboration-id: uint, resource-id: uint }
  {
    resource-type: (string-ascii 50),
    description: (string-ascii 200),
    provider-institution: uint,
    allocated-date: uint,
    quantity: uint
  }
)

;; Resource counter per collaboration
(define-map resource-counters uint uint)

;; Create collaboration
(define-public (create-collaboration
  (title (string-ascii 100))
  (description (string-ascii 500))
  (lead-institution uint)
  (end-date uint)
  (budget uint)
  (objectives (string-ascii 300)))
  (let ((collaboration-id (+ (var-get collaboration-counter) u1)))
    (map-set collaborations
      { collaboration-id: collaboration-id }
      {
        title: title,
        description: description,
        lead-institution: lead-institution,
        initiator: tx-sender,
        status: status-proposed,
        start-date: block-height,
        end-date: end-date,
        budget: budget,
        objectives: objectives
      }
    )
    (var-set collaboration-counter collaboration-id)
    (map-set resource-counters collaboration-id u0)
    (ok collaboration-id)
  )
)

;; Join collaboration
(define-public (join-collaboration
  (collaboration-id uint)
  (institution-id uint)
  (role (string-ascii 50))
  (contribution (string-ascii 200)))
  (match (map-get? collaborations { collaboration-id: collaboration-id })
    collaboration-data
    (begin
      (map-set collaboration-participants
        { collaboration-id: collaboration-id, institution-id: institution-id }
        {
          role: role,
          contribution: contribution,
          joined-date: block-height,
          active: true
        }
      )
      (ok true)
    )
    err-not-found
  )
)

;; Activate collaboration
(define-public (activate-collaboration (collaboration-id uint))
  (match (map-get? collaborations { collaboration-id: collaboration-id })
    collaboration-data
    (begin
      (asserts! (is-eq (get initiator collaboration-data) tx-sender) err-unauthorized)
      (map-set collaborations
        { collaboration-id: collaboration-id }
        (merge collaboration-data { status: status-active })
      )
      (ok true)
    )
    err-not-found
  )
)

;; Add resource to collaboration
(define-public (add-resource
  (collaboration-id uint)
  (resource-type (string-ascii 50))
  (description (string-ascii 200))
  (provider-institution uint)
  (quantity uint))
  (match (map-get? collaborations { collaboration-id: collaboration-id })
    collaboration-data
    (let ((resource-count (default-to u0 (map-get? resource-counters collaboration-id)))
          (resource-id (+ resource-count u1)))
      (map-set collaboration-resources
        { collaboration-id: collaboration-id, resource-id: resource-id }
        {
          resource-type: resource-type,
          description: description,
          provider-institution: provider-institution,
          allocated-date: block-height,
          quantity: quantity
        }
      )
      (map-set resource-counters collaboration-id resource-id)
      (ok resource-id)
    )
    err-not-found
  )
)

;; Get collaboration details
(define-read-only (get-collaboration (collaboration-id uint))
  (map-get? collaborations { collaboration-id: collaboration-id })
)

;; Get participant details
(define-read-only (get-participant (collaboration-id uint) (institution-id uint))
  (map-get? collaboration-participants { collaboration-id: collaboration-id, institution-id: institution-id })
)

;; Get resource details
(define-read-only (get-resource (collaboration-id uint) (resource-id uint))
  (map-get? collaboration-resources { collaboration-id: collaboration-id, resource-id: resource-id })
)

;; Get total collaborations
(define-read-only (get-collaboration-count)
  (var-get collaboration-counter)
)
