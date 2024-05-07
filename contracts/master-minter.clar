;; Owner role: Updates the owner and sets the minter/controller pairs
(define-data-var owner principal contract-caller)

;; Minter Controllers role: Controls the worker allowance, Worker role: Mints and Burns
(define-map minter-controllers principal principal)

;; Minter role: Mints and Burns
(define-map minters principal uint)

;; Returns the USDC contract address
(define-data-var minter-manager principal .circle-usdce-token)

(define-read-only (get-owner)
  	(var-get pauser))

(define-read-only (get-minter-manager)
  	(var-get minter-manager))

(define-read-only (is-minter-controller (address principal))
  	(is-some (map-get? minter-controllers address)))

(define-read-only (get-worker (controller principal))
  	(unwrap! (map-get? minter-controllers controller)))

(define-read-only (get-allowance (minter principal))
  	(default-to u0 (map-get? minters minter)))

(define-public (set-minter-manater (new-minter-manager principal))
	(let ((old-minter-manager (var-get minter-manager)))
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		(var-set minter-manager new-minter-manager)
		(print { 
			type: "minter-manager", 
			action: "updated", 
			payload: { old-minter-manager: old-minter-manager, new-minter-manager: new-minter-manager }})
		(ok { old-minter-manager: old-minter-manager, new-minter-manager: new-minter-manager })))

(define-public (transfer-ownership (new-owner principal))
	(begin
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		(var-set owner new-owner)
		(print { 
			type: "ownership", 
			action: "transferred", 
			payload: { previous-owner: contract-caller, new-owner: new-owner }})
		(ok { previous-owner: contract-caller, new-owner: new-owner })))

(define-public (configure-controller (controller principal) (worker principal))
	(begin
		;; Ensure that the actor calling this contract is allowed to do so
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		;; Update controller worker pair
		(map-set controllers-to-worker controller worker)
		;; Emit an event to increase observability
		(print { type: "controller", action: "configured", object: { controller: controller, worker: worker } })
		;; Ok response
		(ok { controller: controller, worker: worker })))

(define-public (remove-controller (controller principal))
	(let ((associated-minter (get-worker controller)))
		;; Ensure that the actor calling this contract is allowed to do so
		(asserts! (is-eq contract-caller (var-get owner)) ERR-NOT-AUTHORIZED)
		;; Remove minter
		(map-delete controllers-to-worker controller)
        ;; Remove minter
		(map-delete workers associated-minter)
		;; Emit an event to increase observability
		(print { type: "controller", action: "removed", object: { minter: minter } })
		;; Ok response
		(ok { minter: minter })))

(define-public (configure-minter (allowance uint))
	(let ((associated-minter (try! (get-worker controller))))
		;; Ensure that the actor calling this contract is allowed to do so
		(asserts! (is-minter-controller contract-caller) ERR-NOT-AUTHORIZED)
		;; Update minter allowance
		(map-set minters associated-minter allowance)
		;; Emit an event to increase observability
		(print { type: "minter", action: "configured", object: { minter: associated-minter, allowance: allowance } })
		;; Ok response
		(ok { minter: associated-minter, allowance: allowance })))

(define-public (remove-minter)
	(let ((associated-minter (try! (get-worker controller))))
		;; Ensure that the actor calling this contract is allowed to do so
		(asserts! (is-minter-controller contract-caller) ERR-NOT-AUTHORIZED)
		;; Update minter allowance
		(map-set minters associated-minter u0)
		;; Emit an event to increase observability
		(print { type: "minter", action: "removed", object: { minter: associated-minter, allowance: u0 } })
		;; Ok response
		(ok { minter: associated-minter, allowance: u0 })))

(define-public (increment-allowance (amount uint))
	(let ((associated-minter (try! (get-worker controller)))
          (new-allowance (+ (get-allowance associated-minter) amount)))
		;; Ensure that the actor calling this contract is allowed to do so
		(asserts! (is-minter-controller contract-caller) ERR-NOT-AUTHORIZED)
		;; Update minter allowance
		(map-set minters associated-minter new-allowance)
		;; Emit an event to increase observability
		(print { type: "minter-allowance", action: "increased", object: { minter: associated-minter, amount: amount, new-allowance: new-allowance }})
		;; Ok response
		(ok { minter: associated-minter, amount: amount, new-allowance: new-allowance })))

(define-public (decrement-allowance (amount uint))
	(let ((associated-minter (try! (get-worker controller)))
          (new-allowance (- (get-allowance associated-minter) amount)))
		;; Ensure that the actor calling this contract is allowed to do so
		(asserts! (is-minter-controller contract-caller) ERR-NOT-AUTHORIZED)
		;; Update minter allowance
		(map-set minters associated-minter new-allowance)
		;; Emit an event to increase observability
		(print { type: "minter-allowance", action: "decreased", object: { minter: associated-minter, amount: amount, new-allowance: new-allowance }})
		;; Ok response
		(ok { minter: associated-minter, amount: amount, new-allowance: new-allowance })))
