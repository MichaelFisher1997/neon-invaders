local HUD = {}

local function textShadowPrint(text, x, y)
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.print(text, x+2, y+2)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(text, x, y)
end

function HUD.draw(score, lives, wave, vw, vh)
  love.graphics.setFont(love.graphics.newFont(18))
  -- Score top-left
  textShadowPrint("Score: " .. tostring(score), vw * 0.02, vh * 0.02)
  -- Wave top-right
  local waveText = "Wave " .. tostring(wave)
  local tw = love.graphics.getFont():getWidth(waveText)
  textShadowPrint(waveText, vw - tw - vw*0.02, vh * 0.02)
  -- Lives centered top as triangles
  local centerX = vw / 2
  local y = vh * 0.04
  local spacing = 32
  love.graphics.setColor(0.153, 0.953, 1.0, 1.0)
  for i = 1, lives do
    local x = centerX + (i - (lives+1)/2) * spacing
    love.graphics.polygon("fill", x, y, x-10, y+16, x+10, y+16)
  end
end

function HUD.drawTouchHints(vw, vh)
  -- Draw minimal, percent-based hints anchored to bottom area (virtual space)
  local padY = vh * 0.72
  local btnW = vw * 0.22
  local btnH = vh * 0.22
  local gap = vw * 0.02

  -- Left and Right hint rectangles
  love.graphics.setColor(1,1,1,0.10)
  love.graphics.rectangle('fill', gap, padY, btnW, btnH, 8, 8)
  love.graphics.rectangle('fill', gap + btnW + gap, padY, btnW, btnH, 8, 8)
  love.graphics.setColor(1,1,1,0.28)
  love.graphics.rectangle('line', gap, padY, btnW, btnH, 8, 8)
  love.graphics.rectangle('line', gap + btnW + gap, padY, btnW, btnH, 8, 8)

  -- Simple arrow icons
  love.graphics.setColor(1,1,1,0.5)
  local function arrowLeft(x,y,w,h)
    love.graphics.polygon('fill', x + w*0.65, y + h*0.3, x + w*0.35, y + h*0.5, x + w*0.65, y + h*0.7)
  end
  local function arrowRight(x,y,w,h)
    love.graphics.polygon('fill', x + w*0.35, y + h*0.3, x + w*0.65, y + h*0.5, x + w*0.35, y + h*0.7)
  end
  arrowLeft(gap, padY, btnW, btnH)
  arrowRight(gap + btnW + gap, padY, btnW, btnH)

  -- Fire button hint
  local fireR = vw * 0.08
  local fireCx = vw - fireR - gap
  local fireCy = vh - fireR - gap
  love.graphics.setColor(1,1,1,0.10)
  love.graphics.circle('fill', fireCx, fireCy, fireR)
  love.graphics.setColor(1,1,1,0.30)
  love.graphics.circle('line', fireCx, fireCy, fireR)
end

return HUD
