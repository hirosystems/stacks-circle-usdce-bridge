;; title: circle-usdce-token
;; version:
;; summary:
;; description:

(impl-trait 'SP2J933XB2CP2JQ1A4FGN8JA968BBG3NK3EKZ7Q9F.hk-tokens-v1.sip10-token)
(impl-trait .token-traits.allbrige-bridged-token-trait)

(use-trait token-extension .token-traits.token-extension)
(use-trait extendable-token-actions-v1 .token-traits.extendable-token-actions-v1)
(use-trait master-minter-contract .token-traits.master-minter)

;;;;
;; Constants
;;;;

(define-constant ERR-NOT-AUTHORIZED (err u10000))
(define-constant ERR-MINT-ALLOWANCE-OVERFLOW (err u10001))
(define-constant ERR-PRINCIPAL-INVALID (err u10002))
(define-constant ERR-AMOUNT-INVALID (err u10003))
(define-constant ERR-TOKEN-PAUSED (err u10004))
(define-constant PRECISION u8)

;;;;
;; Storage
;;;;

;; Token balances data map
(define-fungible-token token-data)

;; Token Metadata URI
(define-data-var token-uri (string-utf8 256) u"http://url.to/token-metadata.json")

;; Token Name
(define-data-var name (string-ascii 32) "USDC.e (Bridged by X)")

;; Token Symbol
(define-data-var symbol (string-ascii 32) "USDC.e")

;; Owner role: Change any role (including the current owner) except the owner
(define-data-var owner principal contract-caller)

;; 2 steps owner role transfer
(define-data-var pending-owner (optional principal) none)

;; Blacklister role: Blacklist and unblacklist addresses
(define-data-var blacklister principal contract-caller)

;; Pauser role: Pauses all the contract functions except the role changes
(define-data-var pauser principal contract-caller)

;; Master-minter role: Creates and controls the minters and minter controllers and define maximum allowance each minter can mint
(define-data-var master-minter principal contract-caller)

;; Minters role: Mints/Burns the asset up to allowed allowance set by masterMinter
(define-map minters principal uint)

;; Rescuer role: Rescues funds sent to the contract address
(define-data-var rescuer principal contract-caller)

;; Banned addresse data map
(define-map banned-addresses principal bool)

;; Keep track of paused status
(define-data-var token-pause bool true)

;;;;
;; SIP-10 trait implementation
;;;;

(define-read-only (get-total-supply)
  	(ok (ft-get-supply token-data)))

(define-read-only (get-name)
  	(ok (var-get name)))

(define-read-only (get-symbol)
  	(ok (var-get symbol)))

(define-read-only (get-decimals)
   	(ok PRECISION))

(define-read-only (get-balance (account principal))
  	(ok (ft-get-balance token-data account)))

(define-read-only (get-token-uri)
  	(ok (some (var-get token-uri))))

(define-public (transfer 
		(amount uint) 
		(sender principal) 
		(recipient principal) 
		(memo (optional (buff 34))))
	;; Allbridge trait requirement - To be explored
	(transfer! amount sender recipient memo))

;;;;
;; Pause
;;;;

(define-public (update-pauser (address principal))
	(begin
		;; Check ACL
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		;; Update pauser
		(var-set pauser address)
		(ok address)))

(define-read-only (is-token-paused)
  	(ok (var-get token-pause)))

(define-read-only (get-pauser)
  	(var-get pauser))

(define-public (pause-token)
	(begin
		;; Ensure that the actor calling this contract is allowed to do so
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		;; Pause token
		(var-set token-pause true)
		;; Emit an event to increase observability
		(print { type: "token", action: "paused" })
		;; Ok response
		(ok true)))

(define-public (unpause-token)
	(begin
		;; Ensure that the actor calling this contract is allowed to do so
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		;; Unpause token
		(var-set token-pause false)
		;; Emit an event to increase observability
		(print { type: "token", action: "paused" })
		;; Ok response
		(ok true)))

;;;;
;; Ownership
;;;;

(define-read-only (get-contract-owner)
  	(get-owner))

(define-public (set-contract-owner (new-owner principal))
	(transfer-ownership new-owner))

(define-read-only (get-owner)
  	(ok (var-get owner)))

(define-read-only (get-pending-owner)
  	(ok (var-get pending-owner)))

(define-public (transfer-ownership (new-owner principal))
	(begin
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		(asserts! (is-standard new-owner) ERR-NOT-AUTHORIZED)
		(print { 
			type: "ownership", 
			action: "transfer-started", 
			payload: { previous-owner: contract-caller, new-owner: new-owner }})
		(ok (var-set pending-owner (some new-owner)))))

(define-public (accept-ownership)
	(let ((previous-owner (var-get owner)))
		(asserts! (is-eq (some contract-caller) (var-get pending-owner)) ERR-NOT-AUTHORIZED)
		(var-set pending-owner none)
		(var-set owner contract-caller)
		(print { 
			type: "ownership", 
			action: "transferred", 
			payload: { previous-owner: previous-owner, new-owner: contract-caller }})
		(ok (some contract-caller))))

;;;;
;; Blacklist management
;;;;

(define-public (update-blacklister (address principal))
	(begin
		;; Check ACL
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		;; Update blacklister
		(var-set blacklister address)
		(ok address)))

(define-read-only (get-blacklister)
  	(var-get blacklister))

(define-read-only (is-blacklisted (address principal))
  	(is-some (map-get? banned-addresses address)))

(define-public (blacklist (address principal))
	(begin
		;; Check ACL
		(asserts! (is-eq contract-caller (var-get blacklister)) ERR-NOT-AUTHORIZED)
		;; Ban address
		(map-set banned-addresses address true)
		(ok address)))

(define-public (unblacklist (address principal))
	(begin
		;; Check ACL
		(asserts! (is-eq contract-caller (var-get blacklister)) ERR-NOT-AUTHORIZED)
		;; Ban address
		(map-delete banned-addresses address)
		(ok address)))

;;;;
;; Rescuer management
;;;;

(define-public (update-rescuer (address principal))
	(begin
		;; Check ACL
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		;; Update rescuer
		(var-set rescuer address)
		(ok address)))

(define-read-only (get-rescuer)
  	(var-get rescuer))

;;;;
;; Minting management
;;;;

(define-public (update-master-minter (master-minter-address <master-minter-contract>))
	(begin
		;; Check ACL
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		;; Update master-minter
		(var-set master-minter (contract-of master-minter-address))
		(ok (contract-of master-minter-address))))

(define-public (configure-minter (minter principal) (allowance uint))
	(begin
		;; Ensure that the actor calling this contract is allowed to do so
		(asserts! (is-eq contract-caller (var-get master-minter)) ERR-NOT-AUTHORIZED)
		;; Update minter's allowance
		(map-set minters minter allowance)
		;; Emit an event to increase observability
		(print { type: "minters", action: "updated", object: { minter: minter, allowance: allowance } })
		;; Ok response
		(ok { minter: minter, allowance: allowance })))

(define-public (remove-minter (minter principal))
	(begin
		;; Ensure that the actor calling this contract is allowed to do so
		(asserts! (is-eq contract-caller (var-get master-minter)) ERR-NOT-AUTHORIZED)
		;; Remove minter
		(map-delete minters minter)
		;; Emit an event to increase observability
		(print { type: "minters", action: "removed", object: { minter: minter } })
		;; Ok response
		(ok { minter: minter })))

(define-read-only (get-master-minter)
  	(var-get master-minter))

(define-read-only (is-minter (address principal))
  	(is-some (map-get? minters address)))

(define-read-only (get-minter-allowance (address principal))
  	(default-to u0 (map-get? minters address)))

;; Mint tokens
(define-public (mint! (recipient principal) (amount uint) (memo (optional (buff 34))))
	(let ((minting-allowance (unwrap! (map-get? minters contract-caller) ERR-NOT-AUTHORIZED))
		  (minted-pre-op (get-minter-allowance contract-caller))
		  (minted-post-op (+ minted-pre-op amount)))
		;; Ensure that token is not paused
		(asserts! (is-eq (var-get token-pause) false) ERR-TOKEN-PAUSED)
		;; Ensure that minter can mint
		(asserts! (>= amount u0) ERR-AMOUNT-INVALID)
		;; Ensure that minter can mint
		(asserts! (>= minting-allowance minted-post-op) ERR-MINT-ALLOWANCE-OVERFLOW)
		;; Mint tokens
		(unwrap-panic (ft-mint? token-data amount recipient))
		;; Update allowance tracking
		(map-set minters contract-caller minted-post-op)
		;; Emit memo event
		(print memo)
		;; Return Ok
		(ok true)))

;; Burn tokens
(define-public (burn! (amount uint))
	(begin
		(asserts! (is-minter contract-caller) ERR-NOT-AUTHORIZED)
		;; Ensure that token is not paused
		(asserts! (is-eq (var-get token-pause) false) ERR-TOKEN-PAUSED)
		;; Burn tokens
		(ft-burn? token-data amount contract-caller)))

;; Transfer tokens
(define-public (transfer! (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
	(begin 
		;; Ensure amount is positive
		(asserts! (> amount u0) ERR-AMOUNT-INVALID)
		;; Ensure the sender is not banned
		(asserts! (is-none (map-get? banned-addresses sender)) ERR-NOT-AUTHORIZED)
		;; Ensure the recipient is not banned
		(asserts! (is-none (map-get? banned-addresses recipient)) ERR-NOT-AUTHORIZED)
		;; Ensure that token is not paused
		(asserts! (is-eq (var-get token-pause) false) ERR-TOKEN-PAUSED)
		;; Ensure that send tokens are owned by the tx-sender
		(asserts! (is-eq sender tx-sender) ERR-NOT-AUTHORIZED)
		(match 
			(ft-transfer? token-data amount sender recipient)
			response (begin
				(print memo)
				(ok response)
			)
			error (err error))))

;;;;
;; Upgrade process
;;;;

(define-public (set-token-uri (value (string-utf8 256)))
	(begin
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		(ok (var-set token-uri value))))

(define-public (set-token-name (value (string-ascii 32)))
	(begin
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		(ok (var-set name value))))

(define-public (set-token-symbol (value (string-ascii 32)))
	(begin
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		(ok (var-set symbol value))))
