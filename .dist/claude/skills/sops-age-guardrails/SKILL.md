---
name: sops-age-guardrails
description: "Use for SOPS/age secret editing and review: .sops.yaml creation_rules, encrypted_regex/unencrypted_regex, age recipients and identity environment boundaries, avoiding whole-file encryption, decrypt/edit/re-encrypt workflows, and repo-local secret placement."
---

# SOPS Age Guardrails

## Purpose

Prevent accidental whole-file encryption and local identity leakage when editing SOPS-managed files with age recipients.

## Decision Rules

PROHIBITED: Do not encrypt whole structured config files when only secrets are sensitive; inspect `.sops.yaml` and require narrow `encrypted_regex`, `encrypted_suffix`, or `unencrypted_regex` rules before running `sops -e -i`.
PREFERRED: Keep operational metadata plaintext and encrypt only narrow secret subtrees such as `secrets`, `data`, or `stringData`.

REQUIRED: Keep age private identities out of tracked repo docs/code; provide identities through caller environment, ignored local config, or CI secret surfaces.
REQUIRED: Use SOPS read/edit/encrypt workflows for writes; never hand-edit `ENC[...]` ciphertext or copy plaintext over encrypted files.

## Operating Workflow

1. Read the nearest `.sops.yaml` before editing encrypted files.
2. Confirm the path matches a `creation_rules.path_regex` entry.
3. Confirm the rule encrypts only the intended secret keys.
4. Edit through SOPS, then verify the diff keeps non-secret metadata readable.
5. For single-secret reads, prefer `sops -d --extract` over decrypting the whole file into logs or shell history.

## Commands

```bash
sops -d --extract '["secrets"]["KEY"]' path/to/file.yml
sops path/to/file.yml
sops -e -i path/to/file.yml
sops updatekeys path/to/file.yml
```

## Review Checklist

- `.sops.yaml` is committed with public recipients and path rules.
- Private age identity paths are not tracked in repo code, docs, or examples.
- Structured config keeps non-secret keys reviewable.
- The diff does not introduce broad ciphertext churn outside the intended secret subtree.
- MAC mismatch fixes re-save the final plaintext state through SOPS instead of editing encrypted payloads manually.

## scripts Repo Pattern

For the local `scripts` operations repo, stack manifests use top-level `secrets` as the only SOPS-encrypted subtree. Use `env.secret_keys` for rendered `.env` keys and `secret_files` for file-shaped runtime secrets.

Expected rule:

```yaml
encrypted_regex: ^secrets$
```
