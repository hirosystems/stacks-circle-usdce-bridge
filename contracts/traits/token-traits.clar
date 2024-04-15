;; Token contract must conform to the Bridged constraints 
;; We're assuming the token is initially being bridged by Allbridge:
;; https://github.com/allbridge-io/bridge-stacks-contract-public/blob/master/contracts/traits/bridge-token.clar
(define-trait allbrige-bridged-token-trait
  (
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    (get-name () (response (string-ascii 32) uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-decimals () (response uint uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-token-uri () (response (optional (string-utf8 256)) uint))
    (get-contract-owner () (response principal uint))
    (set-contract-owner (principal) (response bool uint))
  )
)

;; Token contract must conform to the Bridged constraints 
(define-trait extendable-token-actions-v1
  (
    ;; Getters
    (get-name () (response (string-ascii 32) uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-decimals () (response uint uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-token-uri () (response (optional (string-utf8 256)) uint))
    (get-contract-owner () (response principal uint))
    ;; Metadata Controls
    (set-contract-owner (principal) (response bool uint))
    (set-token-uri ((string-utf8 256)) (response bool uint))
    (set-token-name ((string-ascii 32)) (response bool uint))
    (set-token-symbol ((string-ascii 32)) (response bool uint))
    ;; Access Controls
    (ban-address (principal) (response principal uint))
    (unban-address (principal) (response principal uint))
    ;; Token Controls
    (mint! (principal uint (optional (buff 34))) (response bool uint))
    (burn! (principal uint (optional (buff 34))) (response bool uint))
    (transfer! (uint principal principal (optional (buff 34))) (response bool uint))
  )
)

;; Token contract must conform to the Bridged constraints 
(define-trait extendable-token
  (
    (run-extension! (<extendable-token-actions-v1> <token-extension> (buff 8192)) (response bool uint))
  )
)

;; Token contract must conform to the Bridged constraints 
(define-trait token-extension
  (
    (run! (<extendable-token-actions-v1> (buff 8192)) (response bool uint))
  )
)
