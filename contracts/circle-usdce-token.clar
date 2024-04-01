;; title: circle-usdce-token
;; version:
;; summary:
;; description:

(impl-trait 'SP2J933XB2CP2JQ1A4FGN8JA968BBG3NK3EKZ7Q9F.hk-tokens-v1.sip10-token)
(impl-trait .token-traits.allbrige-bridged-token-trait)
(impl-trait .token-traits.extensible-token-actions-v1)
(impl-trait .token-traits.extensible-token)

(use-trait token-extension .token-traits.token-extension)
(use-trait extensible-token-actions-v1 .token-traits.extensible-token-actions-v1)

(define-constant ERR-NOT-AUTHORIZED (err u10000))
(define-constant ERR-MINT-ALLOWANCE-OVERFLOW (err u10001))
(define-constant ERR-PRINCIPAL-INVALID (err u10002))
(define-constant ERR-AMOUNT-INVALID (err u10003))
(define-constant ERR-TOKEN-PAUSED (err u10004))

(define-constant PRECISION u8)
(define-map approved-contracts principal bool)

(define-data-var token-uri (string-utf8 256) u"http://url.to/token-metadata.json")
(define-data-var name (string-ascii 32) "USDC.e (Bridged by X)")
(define-data-var symbol (string-ascii 32) "USDC.e")
(define-data-var contract-owner principal contract-caller)

(define-fungible-token token-data)

(define-map minters-allowances principal uint)
(define-map minters-allowances-tracking principal uint)

(define-public (set-minter-allowance (minter principal) (allowance uint))
	(begin
		;; Ensure that the actor calling this contract is allowed to do so
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		;; Update minter's allowance
		(map-set minters-allowances minter allowance)
		;; Emit an event to increase observability
		(print { type: "allowance", action: "update", object: { minter: minter, allowance: allowance } })
		;; Ok response
		(ok { minter: minter, allowance: allowance })))

(define-data-var token-pause bool false)

(define-public (pause-token)
	(begin
		;; Ensure that the actor calling this contract is allowed to do so
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		;; Pause token
		(var-set token-pause true)
		;; Emit an event to increase observability
		(print { type: "token", action: "paused" })
		;; Ok response
		(ok true)))

(define-public (unpause-token)
	(begin
		;; Ensure that the actor calling this contract is allowed to do so
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		;; Unpause token
		(var-set token-pause false)
		;; Emit an event to increase observability
		(print { type: "token", action: "paused" })
		;; Ok response
		(ok true)))

;;;; SIP-10 trait implementation
;; The logic of these functions will not be upgradable.
;; Constraint: we'd need to have them right from the get go.

(define-read-only 
	(get-total-supply)
  	(ok (ft-get-supply token-data))
)

(define-read-only 
	(get-name)
  	(ok (var-get name))
)

(define-read-only 
	(get-symbol)
  	(ok (var-get symbol))
)

(define-read-only 
	(get-decimals)
   	(ok PRECISION)
)

(define-read-only 
	(get-balance 
		(account principal)
	)
  	(ok (ft-get-balance token-data account))
)

(define-read-only 
	(get-token-uri)
  	(ok (some (var-get token-uri)))
)

(define-public 
	(transfer 
		(amount uint) 
		(sender principal) 
		(recipient principal) 
		(memo (optional (buff 34)))
	)
	;; All-bridge requirement - To be explored
	(begin
		;; (asserts! (is-standard sender) ERR-PRINCIPAL-INVALID)
		;; (asserts! (is-standard recipient) ERR-PRINCIPAL-INVALID)
		;; (asserts! (is-eq (> amount u0) true) ERR-AMOUNT-INVALID)
		;; (if (is-eq sender (var-get contract-owner))
		;; 	(mint! recipient amount memo)
		;; 	(if (is-eq recipient (var-get contract-owner))
		;; 		(burn! sender amount memo)
		;; 		(transfer! amount sender recipient memo)
		;; 	)
		;; )
		(err u0)
	)
)

;;;; Ownership management

(define-read-only 
	(get-contract-owner)
  	(ok (var-get contract-owner))
)

(define-public 
	(set-contract-owner (owner principal))
	(begin
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		(asserts! (is-standard owner) ERR-NOT-AUTHORIZED)
		(ok (var-set contract-owner owner))
	)
)

;;;; Token Extensions
;;;; Functions available for the token extensions

(define-public 
	(set-token-uri 
		(value (string-utf8 256))
	)
	(begin
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		(asserts! (is-eq (> (len value) u0) true) ERR-NOT-AUTHORIZED)
		(ok (var-set token-uri value))
	)
)

(define-public 
	(set-token-name 
		(value (string-ascii 32))
	)
	(begin
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		(asserts! (is-eq (> (len value) u0) true) ERR-NOT-AUTHORIZED)
		(ok (var-set name value))
	)
)

(define-public 
	(set-token-symbol 
		(value (string-ascii 32))
	)
	(begin
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		(asserts! (is-eq (> (len value) u0) true) ERR-NOT-AUTHORIZED)
		(ok (var-set symbol value))
	)
)

(define-map banned-addresses principal bool)

(define-public 
	(ban-address 
		(address principal)
	)
	(begin
		;; Check ACL
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		;; Ban address
		(map-set banned-addresses address true)
		(ok address)
	)
)

(define-public 
	(unban-address 
		(address principal)
	)
	(begin
		;; Check ACL
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		;; Ban address
		(map-set banned-addresses address false)
		(ok address)
	)
)

;; Mint tokens
(define-public (mint! (recipient principal) (amount uint) (memo (optional (buff 34))))
	(let ((minting-allowance (unwrap! (map-get? minters-allowances contract-caller) ERR-NOT-AUTHORIZED))
		  (minted-pre-op (default-to u0 (map-get? minters-allowances-tracking contract-caller)))
		  (minted-post-op (+ minted-pre-op amount)))
		;; Ensure that token is not paused
		(asserts! (is-eq (var-get token-pause) false) ERR-TOKEN-PAUSED)
		;; Ensure that minter can mint
		(asserts! (>= amount u0) ERR-AMOUNT-INVALID)
		;; Ensure that minter can mint
		(asserts! (>= minting-allowance minted-post-op) ERR-MINT-ALLOWANCE-OVERFLOW)
		;; Mint tokens
		(match (ft-mint? token-data amount recipient)
			response 
				(begin
					;; Update allowance tracking
					(map-set minters-allowances-tracking contract-caller minted-post-op)
					;; Emit memo event
					(print memo)
					;; Return Ok
					(ok response))
			error (err error))))

;; Burn tokens
(define-public (burn! (sender principal) (amount uint) (memo (optional (buff 34))))
	(begin
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR-NOT-AUTHORIZED)
		;; Ensure that token is not paused
		(asserts! (is-eq (var-get token-pause) false) ERR-TOKEN-PAUSED)
	    ;; Ensure that token is not paused
		(asserts! (is-eq (var-get token-pause) false) ERR-TOKEN-PAUSED)
		(match 
			(ft-burn? token-data amount sender)
			response (begin
				(print memo)
				(ok response)
			)
			error (err error))))

;; Transfer tokens
(define-public 
	(transfer! 
		(amount uint)
		(sender principal)
		(recipient principal)
		(memo (optional (buff 34)))
	)
	(begin 
		;; Ensure amount is positive
		(asserts! (> amount u0) ERR-TOKEN-PAUSED)
		;; Ensure the sender is not banned
		(unwrap! (map-get? banned-addresses sender) ERR-NOT-AUTHORIZED)
		;; Ensure the recipient is not banned
		(unwrap! (map-get? banned-addresses recipient) ERR-NOT-AUTHORIZED)
		;; Ensure that token is not paused
		(asserts! (is-eq (var-get token-pause) false) ERR-TOKEN-PAUSED)
		;; Ensure that send tokens are owned by the contract-caller
		(asserts! 
			(or (is-eq sender contract-caller)
				(is-eq contract-caller (var-get contract-owner))) 
			ERR-NOT-AUTHORIZED)
		(match 
			(ft-transfer? token-data amount sender recipient)
			response (begin
				(print memo)
				(ok response)
			)
			error (err error)
		)
	)
)

;; Run extensions
(define-public 
	(run-extension! 
		(self <extensible-token-actions-v1>)
		(extension <token-extension>)
		(payload (buff 8192))
	)
	(begin 
		;; TODO: Check ACLs
		(as-contract (contract-call? extension run! self payload))
	)
)

