# Security & documented integrations

GG Customizer is intentionally an app-scoped SwiftUI application. It does not ship an exploit runner, jailbreak payload, sandbox escape, kernel primitive, credential collector, privilege-elevation chain, filesystem bypass, or protected-UI modifier.

## Decision model

An integration is accepted only when all of these are true:

1. It has a public, stable, documented interface.
2. Its supported OS/device range is independently documented by its upstream maintainer.
3. Its operation remains within public iOS APIs or a safe file/share handoff.
4. It requests no system-file access, elevated privilege, credential, passcode, or authentication bypass.
5. Its license and source review are compatible with the GG project.

The app’s integration-manifest importer accepts metadata only. Its closed capability list permits local theme/layout import/export, the iOS share sheet, and an HTTPS documentation link. It does not accept executable code, entitlement changes, filesystem paths, or commands.

## Erosion review

As reviewed on 2026-11-14, the public `jailbreakdotparty/Erosion` repository does not document a stable SDK, integration manifest, or URL scheme for third-party apps. Its README contains upstream claims about OS compatibility, but those claims are not treated by GG Customizer as independently verified compatibility evidence.

Erosion is therefore listed in the app as **External tool — not integrated**. GG Customizer does not copy, link, launch, download, invoke, or automate its code or IPA. This avoids unreviewed privileged behavior and respects the upstream GPL-3.0 license boundary.

## User safety

Before sharing any GG package, confirm that it contains only the intended local design metadata. Before using any external tool, make an independent device backup and review that tool’s own documentation and license. GG’s Recovery Center can restore only its own sandboxed data; it cannot restore or repair another tool’s system-level changes.
