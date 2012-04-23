canvas = atom.canvas
canvas.width = 800
canvas.height = 600
ctx = atom.context
ctx.scale 1, -1
ctx.translate 0,-600
snd_ctx = new webkitAudioContext
window.sm = null

initSound = () ->
    console.log 'in initSound!'
    sm = new sound_map.SoundMap(
        snd_ctx, s1: 'sound/select.wav', s2: 'sound/select.wav',
        (_sound_map) ->
            window.sm = _sound_map
            console.log 'loader callback!'
    ) 
    sm.load()
    sm
   
window.sm = initSound()

batSpeed = 200
v = cp.v

class Game extends atom.Game
    constructor: ->
        @score = [0,0]
        @dir = -1
        @reset()

    newBat: ->
        body = new cp.Body Infinity, cp.momentForBox(Infinity, 50, 200)
        shape = @space.addShape new cp.BoxShape body, 50, 200
        shape.setElasticity 1
        shape.setFriction 0.8
        shape.group = 1
        body # rogue body

    newBall: ->
        body = @space.addBody new cp.Body 25, cp.momentForBox 80, 20, 20
        shape = @space.addShape new cp.BoxShape body, 20, 20
        shape.setElasticity 0.9
        shape.setFriction 0.6
        body

    addWalls: ->
        bottom = @space.addShape(new cp.SegmentShape(@space.staticBody, v(0, 0), v(800, 0), 0))
        bottom.setElasticity(1)
        bottom.setFriction(0.1)
        bottom.group = 1
        top = @space.addShape(new cp.SegmentShape(@space.staticBody, v(0, 600), v(800, 600), 0))
        top.setElasticity(1)
        top.setFriction(0.1)
        top.group = 1

    update: (dt) ->
        if atom.input.pressed 'tie'
            return @reset()

        dt = 1/60
        
        for b,i in @bats
            if atom.input.down "b#{i}up"
                b.setVelocity v(0, batSpeed)
                b.w = 1*(i*2-1)
            else if atom.input.down "b#{i}down"
                b.setVelocity v(0, -batSpeed)
                b.w = -1*(i*2-1)
            else
                b.setVelocity v(0, 0)
                b.w = 0

            b.position_func(dt)
            #b.velocity_func(v(0,0), 1, dt)

        @space.step dt

        if @ball.p.x < -80
            @win 1
            #sm.playSound(sm.s1, snd_ctx)
        else if @ball.p.x > canvas.width + 80
            @win 0
            #sm.playSound(sm.s2, snd_ctx)

        if @ball.p.y < -100 or @ball.p.y > canvas.height + 100
            @win if @ball.p.x < canvas.width/2 then 1 else 0

    win: (p) ->
        @score[p]++
        @dir = if p == 0 then -1 else 1
        @reset()

    reset: ->
        @space = new cp.Space
        @space.gravity = v(0, -50)
        @space.damping = 0.92
        @bats = []
        @bats.push @newBat() for [0..1]
        @bats[0].setPos v(40, 300)
        @bats[1].setPos v(canvas.width-40, 300)
        b.shapeList[0].update(b.p, b.rot) for b in @bats

        @ball = @newBall()
        @ball.setPos v(400-10, 300-10)
        @ball.setVelocity v(160*@dir,0)
        b.shapeList[0].update(b.p, b.rot) for b in [@ball]
        begin = (arb, space) ->
            console.log 'in collision handler'
            sm.playSound sm.s2, snd_ctx
            true
        @space.addCollisionHandler(@ball, @bats[0], begin, begin, begin, begin)
        @space.addCollisionHandler(@ball, @bats[1], (arb, space) ->
            sm.playSound sm.s2, snd_ctx )

        @addWalls()
        ctx.fillStyle = 'black'
        ctx.fillRect 0, 0, canvas.width, canvas.height

	draw: ->
		ctx.fillStyle = 'rgba(0,0,0,0.1)'
		ctx.fillRect 0, 0, canvas.width, canvas.height
		ctx.fillStyle = 'white'
		for b in @bats
			b.shapeList[0].draw(ctx)
		@ball.shapeList[0].draw(ctx)

		ctx.save()
		ctx.font = '50px Mate SC'
		ctx.scale 1,-1
		ctx.textBaseline = 'top'
		ctx.textAlign = 'left'
		ctx.fillText @score[0], 150, -590
		ctx.textAlign = 'right'
		ctx.fillText @score[1], 800-150, -590
		ctx.restore()

point2canvas = (a) -> a
cp.PolyShape::draw = (ctx) ->
    ctx.beginPath()

    verts = this.tVerts
    len = verts.length
    lastPoint = point2canvas(new cp.Vect(verts[len - 2], verts[len - 1]))
    ctx.moveTo(lastPoint.x, lastPoint.y)

    i = 0
    while i < len
        p = point2canvas(new cp.Vect(verts[i], verts[i+1]))
        ctx.lineTo(p.x, p.y)
        i += 2
    ctx.fill()
    #ctx.stroke()

atom.input.bind atom.key.Q, 'b0up'
atom.input.bind atom.key.A, 'b0down'
atom.input.bind atom.key.UP_ARROW, 'b1up'
atom.input.bind atom.key.DOWN_ARROW, 'b1down'

atom.input.bind atom.key.T, 'tie'
atom.input.bind atom.key.SPACE, 'begin'


console.log 'parsing title'
class TitleScreen extends atom.Game
    constructor: ->
        super()
        @time = 0

    update: (dt) ->
        @time += dt
        if atom.input.pressed 'begin'
            @stop()
            setTimeout ->
                game = new Game
                game.run()
            , 0

    draw: ->
        ctx.fillStyle = 'rgba(0,0,0,0.2)'
        ctx.fillRect 0, 0, canvas.width, canvas.height
        ctx.save()
        ctx.scale 1, -1
        ctx.textBaseline = 'top'
        ctx.textAlign = 'center'
        ctx.fillStyle = 'rgba(200,200,250, 1)'
        ctx.font = '80px Mate SC'
        ctx.fillText 'AWESOME', 400+Math.cos(@time*2)*30*Math.cos(@time*3), -500+Math.sin(@time*3)*20

        ctx.font = '25px Mate SC'
        ctx.fillText 'Press Space to Play', 400, -200 if Math.floor(@time*3) % 2
        ctx.restore()

console.log 'declared title'

class World
    width:800
    height:600
    viewWidth: canvas.width
    viewHeight: canvas.height
    sprites: []

    constructor: ->
        console.log 'creating World'
        @hero = new Hero(this)
        @sprites.push(new Background(this))
        @sprites.push(@hero)
        console.log 'created World'

    reset: -> @hero.reset(@width, @height)

    heroViewOffsetX: -> @hero.viewOffsetX(@viewWidth)
    heroViewOffsetY: -> @hero.viewOffsetY(@viewHeight)

    viewWidthLimit: -> @width - @viewWidth
    viewHeightLimit: -> @height - @viewHeight

    atViewLimitLeft:   -> @hero.x < @heroViewOffsetX()
    atViewLimitTop:    -> @hero.y < @heroViewOffsetY()
    atViewLimitRight:  -> @hero.x > @viewWidthLimit() + @heroViewOffsetX()
    atViewLimitBottom: -> @hero.y > @viewHeightLimit() + @heroViewOffsetY()

    render: (lastUpdate, lastElapsed) ->
        sprite.draw() for sprite in @sprites

class SpriteImage
    ready: false
    constructor: (url) ->
        image = new Image
        image.src = 'sheet.png'
        image.onload = => @ready = true
        @image = image

class Sprite
    sx: 0
    sy: 0
    sw: 0
    sx: 0
    dx: 0
    dy: 0
    dw: 0
    dh: 0
    x: 0
    y: 0

    image: new SpriteImage
    constructor: (@world) ->

    drawImage: (sx, sy, dx, dy) ->
        if @image.ready
            @world.ctx.drawImage(@image.image, sx, sy, @sw, @sh, dx, dy, @dw, @dh)


class Background extends Sprite
    constructor: (world) ->
        @dw = world.viewWidth
        @dh = world.viewHeight
        @sw = world.viewWidth
        @sh = world.viewHeight
        console.log 'midcreated BG'
        super(world)
        console.log 'created BG'

    draw: ->
        #The background moves as the hero does.
        x = @world.hero.x - @world.heroViewOffsetX()
        y = @world.hero.y - @world.heroViewOffsetY()
        # Prevent the background from scrolling at the start of the world.
        x = 0 if @world.atViewLimitLeft()
        y = 0 if @world.atViewLimitTop()
        # Prevent the background from scrolling at the end of the world.
        x = @world.viewWidthLimit() if @world.atViewLimitRight()
        y = @world.viewHeightLimit() if @world.atViewLimitBottom()
        @drawImage(x, y, @dx, @dy)

class Entity extends Sprite
  draw: ->
    # When the view is at the start of the world the sprites can be
    # drawn at their full world co-ordinates.
    @dx = @x if @world.atViewLimitLeft()
    @dy = @y if @world.atViewLimitTop()
    # When the view is at the end of the world the sprites are drawn
    # as an offset from the edge of the world.
    @dx = @x - @world.viewWidthLimit() if @world.atViewLimitRight()
    @dy = @y - @world.viewHeightLimit() if @world.atViewLimitBottom()
    @drawImage(@sx, @sy, @dx, @dy)


class Hero extends Entity
  # The sprite that represents the player and can be controlled and
  # moved through the world.
  sw:    32
  sh:    30
  dw:    32
  dh:    30
  speed: 256
  sy:    513
  direction: 0

  draw: ->
    # By default the hero is drawn to the centre of the view.
    @dx = @world.heroViewOffsetX()
    @dy = @world.heroViewOffsetY()
    # Alternate sprite frames as the player's position changes to
    # create an animation effect.
    @sx = if Math.round(@x+@y)%64 < 32 then @direction else @direction + 32
    super

  # The player's velocity is the default speed multiplied by the 
  # current time difference.
  velocity: (mod) -> @speed * mod

  # Detect a collision between the proposed new player co-ordinates
  # and the collidable objects in the world. If the player's co-ordinates
  # fall within their bounds then it has collided.
  collision: (x, y) ->
    for o in @world.collidableSprites()
      return true if y > o.y - @dh and y < o.y + o.dh and x > o.x - @dw and x < o.x + o.dw
    false

  # Handle keyboard input. By changing the `@direction` value in each
  # function the player's sprite changes and produces the effect that 
  # makes the hero look in the direction he is travelling.
  # 
  # The player's position is modified in the direction of the key
  # press if still inside the world and no collisions are detected.
  up: (mod) -> 
    @direction = 64
    y = @y - @velocity(mod)
    @y -= @velocity(mod) if y > 0 and !@collision(@x, y)
  down: (mod, height) -> 
    @direction = 0
    y = @y + @velocity(mod)
    @y += @velocity(mod) if y < height - @dh and !@collision(@x, y)
  left: (mod) -> 
    @direction = 128
    x = @x - @velocity(mod)
    @x -= @velocity(mod) if x > 0 and !@collision(x, @y)
  right: (mod, width) -> 
    @direction = 192
    x = @x + @velocity(mod)
    @x += @velocity(mod) if x < width - @dw and !@collision(x, @y)

  # Helpers that the world uses to calculate the centre position of the
  # hero.
  viewOffsetX: (width)  -> (width / 2)   - (@dw / 2)
  viewOffsetY: (height) -> (height / 2)  - (@dh / 2)

  # The hero starts the game in the centre of the world.
  reset: (width, height) ->
    @x = @viewOffsetX(width)
    @y = @viewOffsetY(height) 

game = new TitleScreen
game.run()

window.onblur = -> game.stop()
window.onfocus = -> game.run()
