#!/bin/bash
# Thin wrapper: adopt reuses the init skill's installer so the merge logic
# lives in exactly one place. A separate path lets each skill pre-approve
# only its own script in `allowed-tools`.
exec "$(cd "$(dirname "$0")" && pwd)/../../init/scripts/install.sh" "$@"
