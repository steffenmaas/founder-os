# ADR-0001: Founder OS is published under PolyForm Noncommercial 1.0.0

- **Status:** Accepted
- **Date:** 2026-08-08
- **Deciders:** Steffen Maas (Ocean One Ventures)

## Context

Founder OS is being made public so that the plugin marketplace resolves without access
configuration, so that adoption in any repository is frictionless, and so the module is a
visible Ocean One asset. Public without a licence means "all rights reserved": readers may
look and fork under GitHub's terms, but no one may legally *use* it — which defeats the
purpose. A licence choice was therefore forced by the visibility change.

## Options

| Option | Upside | Downside |
|---|---|---|
| No licence | Maximum control | Nobody may legally use it; adoption blocked |
| MIT / Apache-2.0 | Maximum adoption, community contributions | Competitors may commercialise it |
| BUSL-1.1 | Source-available, converts to open source after a term | Explanation-heavy; term management overhead |
| **PolyForm Noncommercial 1.0.0** | Founders, teams, non-profits and education use it freely; commercial exploitation by third parties is not licensed | Not OSI-approved; some companies' policies reject non-OSI licences |

## Decision

**PolyForm Noncommercial 1.0.0.** It matches the intent precisely: the rulebook should be
usable by the founders it was written for, while the right to package and sell it stays
with Ocean One Ventures. Non-OSI status is acceptable — this is a methodology asset, not a
library other products link against.

## Consequences

**Positive:** public repository, so plugin installation needs no access configuration;
GitHub secret scanning and push protection become available at no cost; the module can be
referenced publicly as an Ocean One asset.

**Negative:** accepted knowingly — companies with strict OSI-only policies cannot adopt it,
and outside contributions may be discouraged by the non-commercial clause.

**Binding for agents:**

> Founder OS is licensed under PolyForm Noncommercial 1.0.0. Do not change, remove, or
> relicense `LICENSE`, and do not add dependencies or copied material whose licence is
> incompatible with it. Every new plugin in this marketplace inherits this licence unless a
> superseding ADR says otherwise.

## Revisit when

A commercial offering around Founder OS is planned (then a dual-licence model needs its own
ADR), or when adoption is demonstrably blocked by the non-OSI status.
