local Object = require '../lib/classic/classic'

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
  self.speed = g_speed
  self.decay = g_decay -- higher decay = tighter controls

  self.bullet_amt = 1
  self.fire_rate = 0.4
  self.bullet_speed = g_bullet_speed
  self.score_multiplier = g_score_multiplier
  self.ups = 0

  -- test stuff
  offsetX = self.width/2
  offsetY = self.height/2

  -- maybe handle this in stage, idk
  self.score = 0
end

function Player:update(dt)
  Player.super.update(self, dt)
  if not self.dead then 
    self:handleInput(dt) 
    self:saveState()
  end
end

function Player:draw()
  love.graphics.setColor(0, 1, 1)
  love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
  --love.graphics.line(self.x, self.y, self.x + 20, self.y + 20)
  love.graphics.setColor(1, 1, 1, 0.1)
  self:drawGun()
  -- draw inside
  love.graphics.setColor(0, 1, 1, 0.2)
  love.graphics.rectangle('fill', self.x + 1, self.y + 1, 
                          self.width - 1, self.height - 1)
  love.graphics.setColor(1, 1, 1)
end

function Player:drawGun()
  local x, y = love.mouse.getPosition()
  print(vector.str(vector.trim(10, x, y)))
  dx, dy = vector.trim(10, x, y)
  --love.graphics.line(self.x + 10, self.y + 10, dx, dy)
end

-----------------------------------------------------
function Player:handleInput(dt)

  local function filter(item, other)
    if     other.class == 'Upgrade' then
      return 'cross'
    elseif other.class == 'Enemy'   then 
      return 'cross'
    elseif other.class == 'Bullet'  then 
      return 'cross'
    end
    --return "cross"
  end

  local goalX, goalY = self.x + self.vx * dt, self.y + self.vy * dt
  local actualX, actualY, cols, len = self.area.world:move(self, goalX, goalY, filter)
  self.x, self.y = actualX, actualY

  -- **TODO** Fix fire rate bug
  if input:pressed('mouse1', self.fire_rate)  then
    local x, y = love.mouse.getPosition()
    -- this if statement removes super saiyan cheese
    if(distance(x, y, self.x + offsetX, self.y + offsetY)) > 30 then
      for i = 1, self.bullet_amt do
        self.area:addGameObject(
          'Bullet', 
          self.x + 5, 
          self.y + 5, 
          {
            6, 
            6, 
            x + random(-10, 10), 
            y + random(-10, 10), 
            self.bullet_speed
          }, 
          'player_bullet'
        )
      end
    end
  end

	if input:down('up') then 
		self.vy = -self.speed
	elseif input:down('down') then 
		self.vy = self.speed
	elseif(self.vy < 0) then
		self.vy = self.vy + self.decay
	elseif(self.vy > 0) then
		self.vy = self.vy - self.decay
	end

	if input:down('left') then 
		self.vx = -self.speed
	elseif input:down('right') then 
		self.vx = self.speed
	elseif(self.vx < 0) then
		self.vx = self.vx + self.decay
	elseif(self.vx > 0) then
		self.vx = self.vx - self.decay
  end

  -- **TODO** handle collision in its own function?
  for i = 1, len do
    print('collide ' .. tostring(cols[i].other.class))
    obj = cols[i].other
    if obj.class == "Enemy" then self.dead = true end
    if obj.class == "Upgrade" then self:upgrade(obj) end
  end
end

function Player:upgrade(upgrade_object)
  upgrade_object.dead = true
  self.ups = self.ups - 1
  self.score = self.score + 10 * g_score_multiplier
  self.area:addGameObject(
    'Notify', 
    self.x - 50, 
    self.y - 20, 
    {"+"..10*g_score_multiplier, 20, 5, 0.4}
  )
end

function Player:outOfBounds()
  if self.y > window_height or self.y < 0 then
    return true
  elseif self.x > window_width or self.x < 0 then
    return true
  else
    return false
  end
end

function Player:saveState()
  g_score = self.score
  g_bullet_speed = self.bullet_speed
  g_speed = self.speed
  g_decay = self.decay
  g_score_multiplier = self.score_multiplier
end