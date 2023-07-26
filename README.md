# Filecoin ZK Voting Protocol

## Compiling

```bash
zokrates compile -i src/identifier_proof.zok
zokrates export-verifier
```

## Proof Generation

```bash
zokrates compute-witness -a 0 1
zokrates generate-proof
zokrates verify
```
