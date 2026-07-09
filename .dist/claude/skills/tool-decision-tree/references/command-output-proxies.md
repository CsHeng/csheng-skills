# Command Output Proxies

Token-reducing command proxies such as `rtk` are local productivity helpers, not portable repo requirements.

## Prefer A Proxy When

- Running noisy exploratory commands.
- Inspecting broad search or status output where filtering does not hide needed evidence.
- The command is non-interactive and exact stdout/stderr shape is not the evidence under test.

## Use Raw Or Passthrough Commands When

- Exact stdout, stderr, exit behavior, color, progress, or prompt text matters.
- The command is interactive or TTY-sensitive.
- A machine-readable stream is consumed by another command.
- Diagnosing shell behavior, command availability, PATH, or proxy behavior itself.
- Running commands that need a visible prompt, such as hunk-level staging.

## Local RTK Notes

- `rtk <cmd>` may reduce noisy local output.
- `rtk proxy <cmd>` is useful when the proxy wrapper exists but raw interaction or unfiltered output is needed.
- Do not write repository docs, scripts, or cross-agent instructions that require `rtk`.
