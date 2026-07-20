local removed_title = false

local html_targets = {
  ["lab-overview.md"] = "intern-overview.html",
  ["contribution-strategy.md"] = "intern-contribution-strategy.html",
  ["learning-roadmap.md"] = "intern-roadmap.html",
  ["meeting-preparation.md"] = "intern-meeting.html",
  ["yunong-yuan-research-guide.md"] = "intern-yunong-yuan.html",
  ["contribution-map.md"] = "intern-contribution-map.html",
  ["../reviews/photopolymer-biomaterials/README.md"] = "photopolymer-biomaterials-review.html",
  ["../website/pages/safety.html"] = "safety.html"
}

local function is_external_or_fragment(target)
  return target:match("^#")
    or target:match("^//")
    or target:match("^[%a][%w+.-]*:")
end

function Header(element)
  if not removed_title and element.level == 1 then
    removed_title = true
    return {}
  end
end

function Link(element)
  local path, fragment = element.target:match("^([^#]+)(#.*)$")
  path = path or element.target
  fragment = fragment or ""

  if html_targets[path] then
    element.target = html_targets[path] .. fragment
  elseif not is_external_or_fragment(element.target)
      and not path:match("^[^/]+%.html?$") then
    element.target = "../" .. element.target
  end

  return element
end

function Image(element)
  if not is_external_or_fragment(element.src) then
    element.src = "../" .. element.src
  end

  return element
end
