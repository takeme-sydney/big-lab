#!/bin/sh
set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

expected_target() {
  case "$1" in
    shared/docs/lab-overview.md)
      printf '%s\n' "../website/pages/intern-overview.html"
      ;;
    shared/docs/contribution-strategy.md)
      printf '%s\n' "../website/pages/intern-contribution-strategy.html"
      ;;
    shared/docs/learning-roadmap.md)
      printf '%s\n' "../website/pages/intern-roadmap.html"
      ;;
    shared/docs/meeting-preparation.md)
      printf '%s\n' "../website/pages/intern-meeting.html"
      ;;
    shared/docs/yunong-yuan-research-guide.md)
      printf '%s\n' "../website/pages/intern-yunong-yuan.html"
      ;;
    shared/docs/contribution-map.md)
      printf '%s\n' "../website/pages/intern-contribution-map.html"
      ;;
    microneedle-drug-delivery/review/README.md)
      printf '%s\n' "../website-pages/microneedle-small-data-ml-review.html"
      ;;
    photopolymer-biomaterials/review/README.md)
      printf '%s\n' "../website-pages/photopolymer-biomaterials-review.html"
      ;;
    *)
      basename=${1##*/}
      printf '%s.html\n' "${basename%.md}"
      ;;
  esac
}

first_body_line() {
  awk '
    NR == 1 && $0 == "---" {
      in_front_matter = 1
      next
    }
    in_front_matter && $0 == "---" {
      in_front_matter = 0
      next
    }
    in_front_matter {
      next
    }
    /^[[:space:]]*$/ {
      next
    }
    {
      print
      exit
    }
  ' "$1"
}

validate() {
  source_file=$1
  target=$(expected_target "$source_file")
  source_dir=${source_file%/*}
  if [ "$source_dir" = "$source_file" ]; then
    source_dir=.
  fi

  if [ ! -f "$PROJECT_ROOT/$source_dir/$target" ]; then
    printf '%s\n' "Missing HTML target for $source_file: $target" >&2
    return 1
  fi

  case "$source_file" in
    microneedle-drug-delivery/references/translated\ \ papers/01-yuan-2023-drug-permeation-microneedled-skin-ml-ja.md)
      return 0
      ;;
  esac

  expected="[HTML版を開く]($target)"
  actual=$(first_body_line "$PROJECT_ROOT/$source_file")
  if [ "$actual" != "$expected" ]; then
    printf '%s\n' \
      "Invalid HTML link in $source_file" \
      "  expected first body line: $expected" \
      "  actual first body line:   $actual" >&2
    return 1
  fi
}

find "$PROJECT_ROOT" \
  -type f \
  -name '*.md' \
  -not -path "$PROJECT_ROOT/.git/*" \
  -not -path "$PROJECT_ROOT/node_modules/*" \
  -not -path "$PROJECT_ROOT/vendor/*" \
  -print |
  LC_ALL=C sort |
  while IFS= read -r source_path; do
    source_file=${source_path#"$PROJECT_ROOT"/}

    if [ "$source_file" = "AGENTS.md" ]; then
      continue
    fi

    validate "$source_file"
  done

printf '%s\n' "Validated Markdown-to-HTML links."
