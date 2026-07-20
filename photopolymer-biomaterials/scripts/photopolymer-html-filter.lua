function Image(element)
  if element.src:match("^assets/") then
    element.src = "../review/" .. element.src
  end

  return element
end
