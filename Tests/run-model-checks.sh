#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
validation_dir=$(mktemp -d "${TMPDIR:-/tmp}/jpex-model-checks.XXXXXX")
trap 'rm -rf "$validation_dir"' EXIT
architecture=$(uname -m)
compiler_flags=(-parse-as-library -module-name jpexModelCheck -target "${architecture}-apple-macosx14.0" -module-cache-path "$validation_dir/module-cache")
xcrun swiftc "${compiler_flags[@]}" jpex/VisitStatus.swift Tests/LegacyStoreFixture.swift -o "$validation_dir/legacy"
xcrun swiftc "${compiler_flags[@]}" \
    jpex/VisitStatus.swift jpex/VisitLevel.swift jpex/VisitLadder.swift jpex/LevelColor.swift jpex/LevelPattern.swift \
    jpex/Prefecture.swift jpex/AdministrativeDivision.swift \
    jpex/Country.swift jpex/WorldGroup.swift jpex/DivisionGroup.swift jpex/*Catalog.swift \
    jpex/CountingRules.swift jpex/CollectionSection.swift jpex/TravelSnapshot.swift jpex/SaveModel.swift jpex/PlaceReorganisation.swift \
    jpex/WorldFormalNames.swift jpex/AdministrativeDivision+Names.swift \
    Tests/ModelRegression.swift Tests/LevelChecks.swift -o "$validation_dir/current"
"$validation_dir/legacy" "$validation_dir/trips.store"
"$validation_dir/current" "$validation_dir/trips.store"
"$validation_dir/current" "$validation_dir/trips.store" reopen
