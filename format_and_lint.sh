# Lint and format this iOS project using swiftlint and swiftformat
# Usage: ./format_and_lint.sh

# swiftlint
swiftlint lint --fix --format --path . --strict --config .swiftlint.yml

# swiftformat
swiftformat . --config .swiftformat.yml --swiftversion 5.7

