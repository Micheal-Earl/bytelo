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
  self.decay = 50 -- higher decay = tighter controls

  self.attack_delay = 0.1
  self.last_attack = 0

  -- test stuff
  self.offsetX = self.width/2
  self.offsetY = self.height/2
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

  -- draw player gun
  self:drawGun()

  -- reset to default color
  love.graphics.setColor(1, 1, 1)
end

function Player:destroy()
  Player.super.destroy(self)
end

function Player:drawGun(len)
  local mouseX, mouseY = current_room.camera:mousePosition()
  local playerX, playerY = self.x + self.offsetX, self.y + self.offsetY

  local gun_length = 18

  local angle = math.atan2((mouseX - playerX), (mouseY - playerY))

  local goalX = playerX + math.sin(angle) * gun_length
  local goalY = playerY + math.cos(angle) * gun_length

  love.graphics.setColor(0, 1, 1)
  love.graphics.line(playerX, playerY, goalX, goalY)
end

function Player:handleInput(dt)
  -- this is a filter function used by the collider lib, it handles
  -- collision resolution depending on what player collides with
  local function filter(item, other)
    if     other.class == 'Upgrade' then
      return 'cross'
    elseif other.class == 'Enemy'   then 
      return 'slide'
    elseif other.class == 'player_bullet'  then 
      return 'cross'
    else
      return 'slide'
    end
  end

  -- move the player collider then set player x, y to collider x, y
  local goalX, goalY = self.x + self.vx * dt, self.y + self.vy * dt
  local actualX, actualY, cols, len = self.area.world:move(self, goalX, goalY, filter)
  self.x, self.y = actualX, actualY

  -- **TODO** Fix the input library workaround so we can use input:down('mouse1')
  if love.mouse.isDown(1) then self:shoot() end

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
  -- we have to get the cameras mousePosition otherwise things break
  local x, y = current_room.camera:mousePosition()

  local function fireRate()
    local cur_time = os.clock()
    
    if self.last_attack + self.attack_delay <= cur_time then
      return true, cur_time
    end
  end

  local can_attack, cur_time = fireRate()

  if can_attack then
    self.last_attack = cur_time
    self.area:addGameObject('ShootEffect', self.x + 10, self.y + 10, {x, y})

    -- this if statement removes super saiyan cheese
    if(distance(x, y, self.x + self.offsetX, self.y + self.offsetY)) > 30 then
      self.area:addGameObject('Bullet', self.x + 10, self.y + 10, {6, 6, x, y, 800}, 'player_bullet')
      --self.area:addGameObject('Bullet', self.x + 5, self.y + 5, {6, 6, x, y, 800, 0.3, 0}, 'player_bullet')
      --self.area:addGameObject('Bullet', self.x + 5, self.y + 5, {6, 6, x, y, 800, -0.3, -0}, 'player_bullet')
    end
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