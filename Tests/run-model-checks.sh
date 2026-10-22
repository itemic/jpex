#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
validation_dir=$(mktemp -d "${TMPDIR:-/tmp}/jpex-model-checks.XXXXXX")
trap 'rm -rf "$validation_dir"' EXIT
architecture=$(uname -m)
compiler_flags=(-parse-as-library -module-name jpexModelCheck -target "${architecture}-apple-macosx14.0" -module-cache-path "$validation_dir/module-cache")
xcrun swiftc "${compiler_flags[@]}" jpex/Saves/VisitStatus.swift Tests/LegacyStoreFixture.swift -o "$validation_dir/legacy"
xcrun swiftc "${compiler_flags[@]}" \
    jpex/Saves/VisitStatus.swift jpex/Levels/VisitLevel.swift jpex/Levels/VisitLadder.swift jpex/Levels/LevelColor.swift jpex/Levels/LevelPattern.swift \
    jpex/Places/Prefecture.swift jpex/Places/AdministrativeDivision.swift \
    jpex/Places/Country.swift jpex/Groups/WorldGroup.swift jpex/Groups/CustomWorldGroup.swift jpex/Groups/GroupFlag.swift jpex/Places/DivisionGroup.swift jpex/Places/*Catalog.swift jpex/Places/Countries/*Catalog.swift \
    jpex/Places/CountingRules.swift jpex/Places/CollectionSection.swift jpex/Saves/TravelSnapshot.swift jpex/Saves/SaveModel.swift jpex/Saves/PlaceReorganisation.swift \
    jpex/Places/WorldFormalNames.swift jpex/Places/AdministrativeDivision+Names.swift \
    Tests/ModelRegression.swift Tests/LevelChecks.swift Tests/SaveMergeChecks.swift -o "$validation_dir/current"
"$validation_dir/legacy" "$validation_dir/trips.store"
"$validation_dir/current" "$validation_dir/trips.store"
"$validation_dir/current" "$validation_dir/trips.store" reopen
