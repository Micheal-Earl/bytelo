Player = GameObject:extend()

function Player:new(area, x, y, opts)
  Player.super.new(self, area, x, y, opts)

  -- physics
  self.collider = self.area.world:add(self, self.x, self.y, 20, 20)

  -- shape
  self.width = 20
  self.height = 20

  -- movement stuff
  self.vx, self.vy = 0, 0

  -- STATS
  self.speed = 300
  self.decay = 60 -- higher decay = tighter controls

  -- test stuff
  offsetX = self.width/2
  offsetY = self.height/2
end

function Player:update(dt)
  -- update the parent object
  Player.super.update(self, dt)

  -- if player is not dead then handle input
  if not self.dead then 
    self:handleInput(dt) 
  end
end

function Player:draw()
  -- draw border rectangle
  love.graphics.setColor(0, 1, 1)
  love.graphics.rectangle('line', self.x, self.y, self.width, self.height)

  -- draw inner rectangle
  love.graphics.setColor(0, 1, 1, 0.2)
  love.graphics.rectangle('fill', self.x + 1, self.y + 1, self.width - 1, self.height - 1)

  -- reset to default color
  love.graphics.setColor(1, 1, 1)
end

function Player:destroy()
  Player.super.destroy(self)
end

function Player:handleInput(dt)
  -- this is a filter function used by the collider lib, it handles
  -- collision resolution depending on what player collides with
  local function filter(item, other)
    if     other.class == 'Upgrade' then
      return 'cross'
    elseif other.class == 'Enemy'   then 
      return 'slide'
    elseif other.class == 'Bullet'  then 
      return 'cross'
    end
  end

  -- move the player collider then set player x, y to collider x, y
  local goalX, goalY = self.x + self.vx * dt, self.y + self.vy * dt
  local actualX, actualY, cols, len = self.area.world:move(self, goalX, goalY, filter)
  self.x, self.y = actualX, actualY

  -- **TODO** Fix fire rate bug
  if input:pressed('mouse1')  then
    self:shoot()
  end

  -- handles moving the player object
	if input:down('up')        then self.vy = -self.speed
	elseif input:down('down')  then self.vy = self.speed
	elseif(self.vy < 0)        then self.vy = self.vy + self.decay
  elseif(self.vy > 0)        then self.vy = self.vy - self.decay end
  
	if input:down('left')      then self.vx = -self.speed
	elseif input:down('right') then self.vx = self.speed
	elseif(self.vx < 0)        then self.vx = self.vx + self.decay
	elseif(self.vx > 0)        then self.vx = self.vx - self.decay end

  -- **TODO** handle collision in its own function?
  for i = 1, len do
    obj = cols[i].other
    if obj.class == "Enemy" then self.dead = true end
    if obj.class == "Upgrade" then self:upgrade(obj) end
  end
end

function Player:shoot()
  local x, y = love.mouse.getPosition()
  -- this if statement removes super saiyan cheese
  if(distance(x, y, self.x + offsetX, self.y + offsetY)) > 30 then
    self.area:addGameObject('Bullet', self.x + 5, self.y + 5, {6, 6, x, y, 750}, 'player_bullet')
  end
end

function Player:isOutOfBounds()
  if self.y > window_height or self.y < 0 then
    return true
  elseif self.x > window_width or self.x < 0 then
    return true
  else
    return false
  end
end