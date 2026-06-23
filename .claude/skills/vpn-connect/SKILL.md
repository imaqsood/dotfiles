---
name: vpn-connect
description: Ensure the Perforce VPN is connected before accessing internal/VPN-only resources, or connect/disconnect it on request. Use when a task needs an internal Perforce site or host (e.g. *.perforce.com internal tools, Jenkins, Artifactory, internal Confluence/Jira behind VPN) and a request fails with a network/DNS/timeout error, or when the user asks to connect, disconnect, or check the VPN.
---

# VPN connect

The user is on macOS with Cisco Secure Client connecting to **North America East**
(`na-east.perforce.com`). Sign-in requires their password **and** Microsoft
Authenticator 2FA, so the final sign-in step must be done by the user — you cannot
complete it for them. Your job is to detect the VPN state, open the sign-in window,
wait for them, and confirm.

Three commands are installed on PATH (in `~/.local/bin`):

| Command | Purpose |
|---|---|
| `vpnstatus` | Prints `connected` / `disconnected`; exits 0 if connected, 1 if not. |
| `vpnup` | Opens the Cisco sign-in window, clicks Connect, then **blocks up to 3 min** polling until connected. Returns 0 once connected. |
| `vpndown` | Disconnects immediately. |

## To ensure connectivity before an internal request

1. Run `vpnstatus`. If it prints `connected`, proceed with the task — do nothing else.
2. If `disconnected`, tell the user you're bringing the VPN up, then run `vpnup`.
   - `vpnup` opens the Cisco window and waits. **Prompt the user clearly**:
     "Enter your password and approve the Microsoft Authenticator 2FA in the Cisco
     window — I'll continue once you're connected."
   - `vpnup` returns `0` and prints `✅ VPN connected` once it's up. Then proceed.
   - If `vpnup` exits non-zero (`⏳ Still not connected`), the user hasn't finished
     signing in. Ask them to complete it and re-run, or run `vpnup` again.
3. Only after `vpnstatus` is `connected` should you retry the internal request.

## On explicit user requests

- "connect the vpn" → run `vpnup` (after checking `vpnstatus`).
- "disconnect" / "drop the vpn" → run `vpndown`.
- "is the vpn up?" → run `vpnstatus`.

## Notes

- Never store the user's password or 2FA seed — sign-in always happens in the Cisco
  window by design.
- `vpnup` is idempotent: if already connected it just prints "VPN already connected"
  and exits 0, so it's safe to run defensively.
- The default user (email) and host are pre-filled via
  `~/.cisco/vpn/preferences.xml`, so the user only types a password + approves 2FA.
