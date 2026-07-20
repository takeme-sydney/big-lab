function Image(element)
  if element.src:match("^assets/") then
    element.src = "../../reviews/photopolymer-biomaterials/" .. element.src
  end

  return element
end
