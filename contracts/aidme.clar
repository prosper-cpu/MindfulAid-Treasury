;; MindfulAid Treasury Smart Contract
;; Handles contributions, treasury distribution, and recipient management

;; Error Constants
(define-constant ERR-UNAUTHORIZED-STEWARD-ACCESS (err u100))
(define-constant ERR-RECIPIENT-DUPLICATE (err u101))
(define-constant ERR-RECIPIENT-NONEXISTENT (err u102))
(define-constant ERR-TREASURY-BALANCE-INSUFFICIENT (err u103))
(define-constant ERR-CONTRIBUTION-MINIMUM-NOT-MET (err u104))
(define-constant ERR-CONTRACT-NOT-ACTIVE (err u105))
(define-constant ERR-CONTRIBUTION-AMOUNT-INVALID (err u106))
(define-constant ERR-RECIPIENT-STATUS-INVALID (err u107))
(define-constant ERR-STEWARD-ADDRESS-INVALID (err u108))

;; Data Variables
(define-data-var treasury-steward principal tx-sender)
(define-data-var treasury-balance-total uint u0)
(define-data-var treasury-active-status bool true)
(define-data-var contribution-minimum-amount uint u1000000) ;; 1 STX
(define-data-var treasury-emergency-mode bool false)

;; Data Maps
(define-map recipient-registry 
    principal 
    {
        is-recipient-active: bool,
        support-funds-received: uint,
        last-distribution-block: uint,
        current-support-status: (string-ascii 20)
    }
)

(define-map contributor-registry
    principal
    {
        total-contributions-made: uint,
        last-contribution-block: uint
    }
)

;; Read-only functions
(define-read-only (get-treasury-steward)
    (var-get treasury-steward)
)

(define-read-only (get-treasury-balance)
    (var-get treasury-balance-total)
)

(define-read-only (get-recipient-information (recipient-wallet principal))
    (map-get? recipient-registry recipient-wallet)
)

(define-read-only (get-contributor-information (contributor-wallet principal))
    (map-get? contributor-registry contributor-wallet)
)

(define-read-only (check-treasury-operational-status)
    (and (var-get treasury-active-status) (not (var-get treasury-emergency-mode)))
)

;; Private functions
(define-private (verify-steward-privileges)
    (is-eq tx-sender (var-get treasury-steward))
)

(define-private (update-contributor-history (contributor-wallet principal) (contribution-value uint))
    (let (
        (existing-contributor-record (default-to 
            { total-contributions-made: u0, last-contribution-block: u0 } 
            (map-get? contributor-registry contributor-wallet)
        ))
    )
    (map-set contributor-registry
        contributor-wallet
        {
            total-contributions-made: (+ (get total-contributions-made existing-contributor-record) contribution-value),
            last-contribution-block: block-height
        }
    ))
)

;; Private validation functions
(define-private (validate-contribution-amount (amount uint))
    (and 
        (> amount u0)
        (<= amount u1000000000000) ;; Set reasonable upper limit
    )
)

(define-private (validate-recipient-status (status-code (string-ascii 20)))
    (or 
        (is-eq status-code "active")
        (is-eq status-code "pending")
        (is-eq status-code "suspended")
        (is-eq status-code "completed")
    )
)

(define-private (validate-steward-address (wallet-address principal))
    (and 
        (not (is-eq wallet-address (var-get treasury-steward)))
        (not (is-eq wallet-address (as-contract tx-sender)))
    )
)

;; Public functions
(define-public (make-contribution)
    (let (
        (contribution-value (stx-get-balance tx-sender))
    )
    (asserts! (>= contribution-value (var-get contribution-minimum-amount)) ERR-CONTRIBUTION-MINIMUM-NOT-MET)
    (asserts! (check-treasury-operational-status) ERR-CONTRACT-NOT-ACTIVE)
    
    (try! (stx-transfer? contribution-value tx-sender (as-contract tx-sender)))
    (var-set treasury-balance-total (+ (var-get treasury-balance-total) contribution-value))
    (update-contributor-history tx-sender contribution-value)
    (ok contribution-value))
)

(define-public (register-new-recipient (recipient-wallet principal))
    (begin
        (asserts! (verify-steward-privileges) ERR-UNAUTHORIZED-STEWARD-ACCESS)
        (asserts! (is-none (map-get? recipient-registry recipient-wallet)) ERR-RECIPIENT-DUPLICATE)
        
        (map-set recipient-registry 
            recipient-wallet
            {
                is-recipient-active: true,
                support-funds-received: u0,
                last-distribution-block: u0,
                current-support-status: "active"
            }
        )
        (ok true)
    )
)

(define-public (distribute-funds (recipient-wallet principal) (distribution-value uint))
    (begin
        (asserts! (verify-steward-privileges) ERR-UNAUTHORIZED-STEWARD-ACCESS)
        (asserts! (check-treasury-operational-status) ERR-CONTRACT-NOT-ACTIVE)
        (asserts! (>= (var-get treasury-balance-total) distribution-value) ERR-TREASURY-BALANCE-INSUFFICIENT)
        (asserts! 
            (is-some (map-get? recipient-registry recipient-wallet)) 
            ERR-RECIPIENT-NONEXISTENT
        )
        
        (try! (as-contract (stx-transfer? distribution-value tx-sender recipient-wallet)))
        (var-set treasury-balance-total (- (var-get treasury-balance-total) distribution-value))
        
        (let (
            (recipient-record (unwrap! (map-get? recipient-registry recipient-wallet) ERR-RECIPIENT-NONEXISTENT))
        )
        (map-set recipient-registry
            recipient-wallet
            {
                is-recipient-active: (get is-recipient-active recipient-record),
                support-funds-received: (+ (get support-funds-received recipient-record) distribution-value),
                last-distribution-block: block-height,
                current-support-status: (get current-support-status recipient-record)
            }
        )
        (ok distribution-value))
    )
)

;; Administrative functions
(define-public (set-minimum-contribution (new-minimum-value uint))
    (begin
        (asserts! (verify-steward-privileges) ERR-UNAUTHORIZED-STEWARD-ACCESS)
        (asserts! (validate-contribution-amount new-minimum-value) ERR-CONTRIBUTION-AMOUNT-INVALID)
        (var-set contribution-minimum-amount new-minimum-value)
        (ok true)
    )
)

(define-public (toggle-treasury-status)
    (begin
        (asserts! (verify-steward-privileges) ERR-UNAUTHORIZED-STEWARD-ACCESS)
        (var-set treasury-active-status (not (var-get treasury-active-status)))
        (ok true)
    )
)

(define-public (enable-emergency-mode)
    (begin
        (asserts! (verify-steward-privileges) ERR-UNAUTHORIZED-STEWARD-ACCESS)
        (var-set treasury-emergency-mode true)
        (ok true)
    )
)

(define-public (disable-emergency-mode)
    (begin
        (asserts! (verify-steward-privileges) ERR-UNAUTHORIZED-STEWARD-ACCESS)
        (var-set treasury-emergency-mode false)
        (ok true)
    )
)

(define-public (update-recipient-status (recipient-wallet principal) (new-status (string-ascii 20)))
    (begin
        (asserts! (verify-steward-privileges) ERR-UNAUTHORIZED-STEWARD-ACCESS)
        (asserts! (validate-recipient-status new-status) ERR-RECIPIENT-STATUS-INVALID)
        (asserts! 
            (is-some (map-get? recipient-registry recipient-wallet)) 
            ERR-RECIPIENT-NONEXISTENT
        )
        
        (let (
            (current-record (unwrap! (map-get? recipient-registry recipient-wallet) ERR-RECIPIENT-NONEXISTENT))
        )
        (map-set recipient-registry
            recipient-wallet
            {
                is-recipient-active: (get is-recipient-active current-record),
                support-funds-received: (get support-funds-received current-record),
                last-distribution-block: (get last-distribution-block current-record),
                current-support-status: new-status
            }
        )
        (ok true))
    )
)

;; Transfer ownership
(define-public (transfer-steward-rights (new-steward-address principal))
    (begin
        (asserts! (verify-steward-privileges) ERR-UNAUTHORIZED-STEWARD-ACCESS)
        (asserts! (validate-steward-address new-steward-address) ERR-STEWARD-ADDRESS-INVALID)
        (var-set treasury-steward new-steward-address)
        (ok true)
    )
)