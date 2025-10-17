(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_ATTENDANCE (err u400))
(define-constant ERR_PAYMENT_FAILED (err u500))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))

(define-data-var program-active bool true)
(define-data-var monthly-allowance uint u1000000)
(define-data-var min-attendance-rate uint u80)
(define-data-var payment-period uint u4320)

(define-map families 
  { family-id: uint }
  { 
    head: principal,
    children-count: uint,
    total-allowance: uint,
    last-payment-block: uint,
    active: bool
  }
)

(define-map children
  { child-id: uint }
  {
    family-id: uint,
    name: (string-ascii 50),
    age: uint,
    school: (string-ascii 100),
    active: bool
  }
)

(define-map attendance-records
  { child-id: uint, month: uint, year: uint }
  {
    days-attended: uint,
    total-days: uint,
    verified: bool,
    verifier: principal
  }
)

(define-map payment-history
  { family-id: uint, payment-id: uint }
  {
    amount: uint,
    stacks-block-height: uint,
    children-count: uint
  }
)

(define-data-var next-family-id uint u1)
(define-data-var next-child-id uint u1)
(define-data-var next-payment-id uint u1)

(define-read-only (get-family (family-id uint))
  (map-get? families { family-id: family-id })
)

(define-read-only (get-child (child-id uint))
  (map-get? children { child-id: child-id })
)

(define-read-only (get-attendance (child-id uint) (month uint) (year uint))
  (map-get? attendance-records { child-id: child-id, month: month, year: year })
)

(define-read-only (get-program-status)
  {
    active: (var-get program-active),
    allowance: (var-get monthly-allowance),
    min-attendance: (var-get min-attendance-rate),
    payment-period: (var-get payment-period)
  }
)

(define-read-only (calculate-attendance-rate (child-id uint) (month uint) (year uint))
  (match (get-attendance child-id month year)
    attendance-data (ok (/ (* (get days-attended attendance-data) u100) (get total-days attendance-data)))
    (err ERR_NOT_FOUND)
  )
)

(define-read-only (is-eligible-for-payment (family-id uint) (month uint) (year uint))
  (match (get-family family-id)
    family-data
    (and 
      (get active family-data)
      (var-get program-active)
      (>= stacks-block-height (+ (get last-payment-block family-data) (var-get payment-period)))
    )
    false
  )
)

(define-public (register-family (head principal) (children-count uint))
  (let ((family-id (var-get next-family-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (get-family family-id)) ERR_ALREADY_EXISTS)
    (map-set families 
      { family-id: family-id }
      { 
        head: head,
        children-count: children-count,
        total-allowance: u0,
        last-payment-block: stacks-block-height,
        active: true
      }
    )
    (var-set next-family-id (+ family-id u1))
    (ok family-id)
  )
)

(define-public (register-child (family-id uint) (name (string-ascii 50)) (age uint) (school (string-ascii 100)))
  (let ((child-id (var-get next-child-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (get-family family-id)) ERR_NOT_FOUND)
    (map-set children 
      { child-id: child-id }
      {
        family-id: family-id,
        name: name,
        age: age,
        school: school,
        active: true
      }
    )
    (var-set next-child-id (+ child-id u1))
    (ok child-id)
  )
)

(define-public (record-attendance (child-id uint) (month uint) (year uint) (days-attended uint) (total-days uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (get-child child-id)) ERR_NOT_FOUND)
    (asserts! (<= days-attended total-days) ERR_INVALID_ATTENDANCE)
    (map-set attendance-records 
      { child-id: child-id, month: month, year: year }
      {
        days-attended: days-attended,
        total-days: total-days,
        verified: true,
        verifier: tx-sender
      }
    )
    (ok true)
  )
)

(define-public (process-monthly-payment (family-id uint) (month uint) (year uint))
  (let (
    (family-data (unwrap! (get-family family-id) ERR_NOT_FOUND))
    (payment-amount (* (var-get monthly-allowance) (get children-count family-data)))
    (payment-id (var-get next-payment-id))
  )
    (asserts! (is-eligible-for-payment family-id month year) ERR_UNAUTHORIZED)
    (try! (stx-transfer? payment-amount tx-sender (get head family-data)))
    (map-set families 
      { family-id: family-id }
      (merge family-data { 
        total-allowance: (+ (get total-allowance family-data) payment-amount),
        last-payment-block: stacks-block-height 
      })
    )
    (map-set payment-history
      { family-id: family-id, payment-id: payment-id }
      {
        amount: payment-amount,
        stacks-block-height: stacks-block-height,
        children-count: (get children-count family-data)
      }
    )
    (var-set next-payment-id (+ payment-id u1))
    (ok payment-amount)
  )
)

(define-public (update-program-settings (active bool) (allowance uint) (min-attendance uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set program-active active)
    (var-set monthly-allowance allowance)
    (var-set min-attendance-rate min-attendance)
    (ok true)
  )
)

(define-public (deactivate-family (family-id uint))
  (let ((family-data (unwrap! (get-family family-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set families 
      { family-id: family-id }
      (merge family-data { active: false })
    )
    (ok true)
  )
)


(define-map verifiers
  { verifier: principal }
  {
    authorized: bool,
    school: (string-ascii 100),
    verifications-count: uint,
    authorized-at: uint
  }
)

(define-read-only (get-verifier (verifier principal))
  (map-get? verifiers { verifier: verifier })
)

(define-read-only (is-authorized-verifier (verifier principal))
  (match (get-verifier verifier)
    verifier-data (get authorized verifier-data)
    false
  )
)

(define-public (authorize-verifier (verifier principal) (school (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (is-authorized-verifier verifier)) ERR_ALREADY_EXISTS)
    (map-set verifiers
      { verifier: verifier }
      {
        authorized: true,
        school: school,
        verifications-count: u0,
        authorized-at: stacks-block-height
      }
    )
    (ok true)
  )
)

(define-public (revoke-verifier (verifier principal))
  (let ((verifier-data (unwrap! (get-verifier verifier) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set verifiers
      { verifier: verifier }
      (merge verifier-data { authorized: false })
    )
    (ok true)
  )
)

(define-public (record-attendance-by-verifier (child-id uint) (month uint) (year uint) (days-attended uint) (total-days uint))
  (let (
    (child-data (unwrap! (get-child child-id) ERR_NOT_FOUND))
    (verifier-data (unwrap! (get-verifier tx-sender) ERR_UNAUTHORIZED))
  )
    (asserts! (get authorized verifier-data) ERR_UNAUTHORIZED)
    (asserts! (<= days-attended total-days) ERR_INVALID_ATTENDANCE)
    (asserts! (is-eq (get school child-data) (get school verifier-data)) ERR_UNAUTHORIZED)
    (map-set attendance-records
      { child-id: child-id, month: month, year: year }
      {
        days-attended: days-attended,
        total-days: total-days,
        verified: true,
        verifier: tx-sender
      }
    )
    (map-set verifiers
      { verifier: tx-sender }
      (merge verifier-data { verifications-count: (+ (get verifications-count verifier-data) u1) })
    )
    (ok true)
  )
)