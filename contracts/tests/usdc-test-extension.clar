(impl-trait .token-traits.token-extension)
(use-trait extendable-token .token-traits.extendable-token-actions-v1)

(define-public (run! (token <extendable-token>) (action (buff 8192)))
    (ok true))
