;; Freelancer Reputation System Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-rating (err u103))
(define-constant err-already-rated (err u104))

;; Data Variables
(define-map freelancers
    principal
    {
        total-ratings: uint,
        rating-sum: uint,
        jobs-completed: uint,
        active: bool
    }
)

(define-map job-ratings
    {job-id: uint, client: principal, freelancer: principal}
    {rating: uint}
)

;; Helper Functions
(define-private (calculate-average (sum uint) (count uint))
    (if (is-eq count u0)
        u0
        (/ sum count)
    )
)

;; Public Functions
(define-public (register-freelancer)
    (begin
        (map-set freelancers tx-sender {
            total-ratings: u0,
            rating-sum: u0,
            jobs-completed: u0,
            active: true
        })
        (ok true)
    )
)

(define-public (rate-freelancer (freelancer principal) (job-id uint) (rating uint))
    (let (
        (freelancer-data (unwrap! (map-get? freelancers freelancer) err-not-found))
        (rating-key {job-id: job-id, client: tx-sender, freelancer: freelancer})
    )
        (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
        (asserts! (is-none (map-get? job-ratings rating-key)) err-already-rated)
        
        (map-set job-ratings rating-key {rating: rating})
        (map-set freelancers freelancer {
            total-ratings: (+ (get total-ratings freelancer-data) u1),
            rating-sum: (+ (get rating-sum freelancer-data) rating),
            jobs-completed: (+ (get jobs-completed freelancer-data) u1),
            active: (get active freelancer-data)
        })
        (ok true)
    )
)

(define-public (deactivate-profile)
    (let (
        (freelancer-data (unwrap! (map-get? freelancers tx-sender) err-not-found))
    )
        (map-set freelancers tx-sender
            (merge freelancer-data {active: false})
        )
        (ok true)
    )
)

;; Read-only Functions
(define-read-only (get-freelancer-rating (freelancer principal))
    (let (
        (freelancer-data (unwrap! (map-get? freelancers freelancer) err-not-found))
    )
        (ok {
            average-rating: (calculate-average 
                (get rating-sum freelancer-data) 
                (get total-ratings freelancer-data)
            ),
            total-ratings: (get total-ratings freelancer-data),
            jobs-completed: (get jobs-completed freelancer-data),
            active: (get active freelancer-data)
        })
    )
)

(define-read-only (get-job-rating (job-id uint) (client principal) (freelancer principal))
    (ok (unwrap! (map-get? job-ratings {
        job-id: job-id,
        client: client,
        freelancer: freelancer
    }) err-not-found))
)
