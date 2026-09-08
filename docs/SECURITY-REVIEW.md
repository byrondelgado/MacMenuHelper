# Security review — 8 September 2026

Scope: the v4.0.1 source and release configuration, pinned dependencies, file and
clipboard actions, application launch, settings routing, preference sharing,
bookmark lifecycle and release packaging. Remediations are included in v4.0.2.
This is a source review with targeted regression checks, not a formal assurance
that all security issues have been eliminated.

## Findings and changes

| Finding in v4.0.1 | Remediation in v4.0.2 |
| --- | --- |
| New File used `FileManager.createFile`, which could truncate an existing file. The configured filename could include a path. | Validate a single filename; use `openat` relative to an opened directory with `O_CREAT`, `O_EXCL` and `O_NOFOLLOW`. Existing files, links and concurrent collisions fail without replacement. Create new files with mode 0600, subject to filesystem ACLs. |
| The escaped copy mode escaped only spaces, and double quotes did not protect command substitution when pasted into a shell. | Escape shell metacharacters or use POSIX single quoting, including embedded quotes and newlines. Shell modes enforce a space separator so custom separators cannot inject operators. Literal copy remains available and is not presented as shell-safe. |
| Full selected paths, monitored directories and clipboard text were logged publicly. | Log operation counts and error codes; remove path and clipboard payload logging. Historical logs are not deleted by an update. |
| Bookmark decoding repeatedly acquired access with no matching release; creation failure crashed the extension. | Decode without retaining access; manage successful starts/stops in one owner, release removed scopes and balance cleanup. Report creation errors instead of calling `fatalError`. OS-granted access has separate lifetime rules. |
| Menu commands selected applications by substring matching and trusted a stored numeric action index. Background Finder callbacks read UI-mutated arrays. | Keep exact immutable items behind per-menu integer tokens, dispatch on the main actor, derive built-in actions from known keys and expose snapshots under a lock. |
| The Settings action relied on the default handler for a custom URL scheme. | Open the URL with the containing app explicitly to avoid another registered handler intercepting it. |
| Any launch error could prompt for broader folder permissions; inheritance checkboxes were ignored. | Request a folder only for recognised permission errors and honour argument/environment inheritance settings. |
| The settings app had the same write entitlement as the extension. An unused upstream entitlement allowed read access to `/`. | Use separate read-only app and read/write extension entitlements, remove the broad unused exception, and verify the actual release signatures. |

No shell execution or direct network client/server was found in the application's
production workflows reviewed. Configured third-party applications can of course
execute code and have their own permissions; their security is outside this review.
The release does not request Full Disk Access, Accessibility or Apple Events access.

## Dependencies

The pinned versions are Swift Collections 1.0.5 and AcknowKit 0.0.6. Queries of
GitHub's global advisory API for each package/version returned no matches. A scan
of all 62 Swift advisories returned by that API on this date also found no
Swift Collections or AcknowKit match. This is a dated database check, not proof
that these packages have no undisclosed vulnerabilities. Dependencies remain
pinned, and packaged licence copies are checked against their source checkouts.

## Verification

Run `./scripts/test-security.sh`. It builds the production safety helpers and
models into a test executable with an isolated preference domain and temporary
files. Cases cover existing data, symlinks, hard links, traversal, invalid URLs,
file modes, concurrent creation, shell round-trips, command substitution, balanced
scope ownership, invalid action indexes, exact item identity and menu snapshots.

The full universal build, deployed entitlements, nested signatures, included
licences, ZIP integrity and published asset digests are checked separately. See
[VALIDATION.md](VALIDATION.md) for UI coverage and platform limits.

References: [Apple open(2) flags](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/open.2.html),
[security-scoped resource lifetime](https://developer.apple.com/documentation/foundation/url/startaccessingsecurityscopedresource()),
[GitHub advisory API](https://docs.github.com/en/rest/security-advisories/global-advisories).
