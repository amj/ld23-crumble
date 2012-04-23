canvas = atom.canvas
canvas.width = 960
canvas.height = 704
ctx = atom.context

atom.input.bind atom.key.ENTER, 'select' 
atom.input.bind atom.key.SPACE, 'begin'

###
sounds = SoundMap( snd_ctx, {
    fall: 'sound/fall.wav'
    select: 'sound/select.wav'
} )
###

sounds = window.sounds

class Game extends atom.Game
    sprites: []
    doods: []
    bads: []
    timer: 15
    wave: 0
    OK: 1
    BADS: 2
    state: @OK
    constructor: ->
        super()
        @sprites = []
        @reset()

    reset: ->
        @score = ['foo','bar']
        @hero = new Hero('images/hero.png')
        @hero.x = 150
        @hero.y = 150

        (@doods.push(new Dood('images/dood.png', this)) for i in [0..15])
        d.x = Math.random() * 170 + canvas.width /2 for d in @doods
        d.y = Math.random() * 150 + canvas.height /2 for d in @doods

        @bg = new Background()
        @bg.drop_some_tiles(.3)
        @bg.drop_some_tiles(.3)
        @sprites.push(@bg)
        @sprites.push(d) for d in @doods
        @sprites.push(@hero)
        @timer = 5
        @wave = 0
        @state = @OK

        true
        
    update: (dt) ->
        (sprite.update(dt) if sprite != undefined) for sprite in @sprites

        [cx, cy] = @pack_centroid()

        for dude in @doods when not dude.nommed and not dude.falling
            dude.move_centroid(cx, cy)
            dude.move_separation(@doods, 3, 60)
            if Math.random() > .7
                dude.pick_new_direction()

            #flock avoid the hero
            if Math.random() > .2
                dude.move_separation([@hero], 20, 200)

            #flock avoid the bads
            if @bads.length
                dude.move_separation(@bads, 7, 130)

        for dude in @doods when not dude.falling 
            tx = Math.ceil(dude.x / 16)
            ty = Math.ceil(dude.y / 16)
            if @bg.tiles[ty][tx].val == SPACE
                dude.die()
                sounds.playSound('nooo', .5)
            else if @bg.tiles[ty][tx].val == WATER and not dude.nommed #bounce 
                dude.xv *= -1
                dude.yv *= -1
                dude.move(dt)

        #handle game state logic
        @last_elapsed = dt
        @timer -= dt
        if @timer <= 0 && @state == @OK
            @create_bads()
            @state = @BADS
            @timer = 8
            @wave += 1
            @bg.drop_some_tiles()
            console.log "state: #{@state}"
        else if @timer <=0 and @state == @BADS
            (b.retreat() for b in @bads)
            @state = @OK
            @timer = 10
            @bg.drop_some_tiles()
            sounds.playSound('fall', .3)

    collision: (x, y) ->
        for o in @world.collidableSprites()
            return true if y > o.y - @dh and y < o.y + o.dh and x > o.x - @dw and x < o.x + o.dw
        false

    create_bads: ->
        newbads = (new Bad('images/bad.png', this) for i in [0..2 * @wave])
        for bad in newbads
            _origin = @bg.edges[Math.floor(Math.random() * (@bg.edges.length - 1))]
            console.log _origin
            bad.origin = {x: _origin.x * 16, y:_origin.y * 16}
            bad.x = bad.origin.x
            bad.y = bad.origin.y
            console.log "set origin: #{bad.origin.x}, #{bad.origin.y}"
        (@bads.push(b) for b in newbads)
        (@sprites.push(b) for b in newbads)
        #(console.log "bad at: #{b.x}, #{b.y}" for b in @bads)
        #(console.log "bad origin: #{b.origin.x}, #{b.origin.y}" for b in @bads)

    remove_sprite: (sprite)->
        for b, i in @doods
            if b == sprite
                @doods.splice(i,1)
                console.log "removed from doods at idx #{i}"
                console.log "doods left #{@doods.length}"
        for b, i in @bads
            if b == sprite
                @bads.splice(i,1)
                console.log "removed from bads at idx #{i}"
        for b, i in @sprites
            if b == sprite
                @sprites.splice(i,1)
                console.log "removed from sprites at idx #{i}"

        if @doods.length == 0
            #game over!
            if @wave
                $('header').text( "You lasted #{@wave} waves!")
            @stop()
            setTimeout ->
                game = new TitleScreen()
                game.run()

                window.onblur = -> game.stop()
                window.onfocus = -> game.run()
            , 0



    pack_centroid: ->
        not_ded = []
        (not_ded.push(dude) unless dude.falling or dude.nommed) for dude in @doods
        summa = (t,s) -> t + s.x
        summay = (t,s) -> t + s.y
        cx = not_ded.reduce( summa, 0 )/ not_ded.length
        cy = not_ded.reduce( summay, 0 )/ not_ded.length
        [cx, cy]

    draw: ->
        (sprite.draw(ctx) if sprite != undefined) for sprite in @sprites
        if @state == @OK
            $('#timer').html @timer.toFixed(2)
        else
            $('#timer').html '<b>*DANGER*</b>'

        ctx.save()
        ctx.textAlign = 'left'
        ctx.font = '25px Mate SC'
        ctx.fillStyle = '#ff5c00'
        ctx.fillText "Wave ##{@wave}", 10, 30

        @renderDebugOverlay()
        ctx.restore()

    renderDebugOverlay: () ->
        $('#fps').html "#{Math.round(1 / @last_elapsed)} FPS"

class SpriteImage
    ready: false
    constructor: (url) ->
        image = new Image
        image.src = url
        image.onload = => @ready = true
        @image = image

#assuming horizontal rows.
class Sprite
    sx: 0 #source
    sy: 0
    w: 0
    h: 0
    dx: 0 #destination
    dy: 0

    #frame_names should be a dict of names to what frame you want
    constructor: (spriteurl, w, h, num_frames, frame_names) ->
        @image = new SpriteImage(spriteurl)
        @num_frames ?= num_frames
        @frame_names ?= frame_names

    drawImage: (ctx, sx, sy, dx, dy) ->
        if @image.ready
            ctx.drawImage(@image.image, sx, sy, @w, @h, dx, dy, @w, @h)

GRASS = 0
MOUNTAIN = 1
WATER = 2
SPACE = 3
class Tile extends Sprite
    w: 16
    h: 16
    anim_frames: 1 #will run from 1->5
    animating: false
    done: false

    constructor: (x,y, val, variety) ->
        @tx = x
        @ty = y
        @sx = variety * @w
        @sy = val * @h
        @val = val
        @image = new SpriteImage('images/tiles.png')

    draw: (ctx) ->
        if @animating == false
            @drawImage ctx, @sx, @sy, @tx * @w, @ty * @h
        else
            @drawImage ctx, @sx, SPACE*@h, @tx * @w, @ty * @h
            ctx.save()
            ctx.translate(@tx * @w + 8, @ty * @h + 8)
            ctx.scale(1/ (@anim_frames * @anim_frames), 1/ (@anim_frames * @anim_frames))
            ctx.rotate(1-@anim_frames)
            @drawImage ctx, @sx, @sy, -8, -8
            ctx.restore()
            @anim_frames += .08
            if @anim_frames >= 5
                @done =true
                @animating = false
                @sy = SPACE * @h
                @val = SPACE

    drop: ->
        if @animating != true and @done != true and @val != SPACE
            @animating = true
            @anim_frames = 1
            return true
        return false

    droppable: ->
        @val != SPACE and @animating != true

TSIZE = 16
class Background extends Sprite
    constructor: () ->
        @edges = []
        @dw = canvas.width
        @dh = canvas.height
        console.log "#{@dw} by #{@dh}"
        @tw = @dw / TSIZE
        @th = @dh / TSIZE
        console.log "it's #{@tw} by #{@th}"
        num_types = 3 #0 thru 3
        num_varieties = 4
        offset = {x: Math.random() * 40, y: Math.random() *40}
        @tmap = (( (@distribute(PerlinNoise.noise((x+offset.x)/14, (y+offset.y)/10, 0))) for x in [0..@tw]) for y in [0..@th])
        #@tmap = ((Math.round(Math.random() * num_types) for x in [0..@tw]) for y in [0..@th])

        @edges.push( x:0, y:i)  for i in [0..@th-1]
        @edges.push( x:i, y:0)  for i in [0..@tw-1]
        @edges.push( x:i, y:@th-1)  for i in [0..@tw-1]
        @edges.push( x:@tw-1, y:i)  for i in [0..@th-1]

        console.log( "Edges: #{e.x for e in @edges}")

        @tiles = ((new Tile(i, j, x, (i + j + Math.round(Math.random() * 3)) % num_varieties) for x, i in y) for y, j in @tmap)
 
    draw: (ctx) ->
        (tile.draw(ctx) for tile in tlist) for tlist in @tiles

    distribute: (noise_val) ->
        if noise_val > .70
            return 2 #agua
        if noise_val > .33
            return 0 #grass
        return 1 #mountain 

    drop_some_tiles: (odds) ->
        if not odds
            odds = .55
        for edge, i in @edges
            if Math.random() > odds and edge
                @tiles[edge.y][edge.x].drop() #returns true if drop happening

                newedges = []
                if edge.y < @th - 1
                    if @tiles[edge.y+1][edge.x].droppable()
                        newedges.push({y: edge.y + 1, x:edge.x})
                if edge.y > 0
                    if @tiles[edge.y-1][edge.x].droppable()
                        newedges.push({y: edge.y - 1, x:edge.x})
                if edge.x < @tw - 1
                    if @tiles[edge.y][edge.x+1].droppable()
                        newedges.push({y: edge.y, x:edge.x + 1})
                if edge.x > 0
                    if @tiles[edge.y][edge.x-1].droppable()
                        newedges.push({y: edge.y, x:edge.x - 1})

                @edges.splice(i,1)
                i -= 1
                @edges.push(e) for e in newedges
        
    update: ->

    perlin: (grid, size, step) ->
        
class Dood extends Sprite
    w: 16
    h: 16
    x: 0
    y: 0
    xv: 0
    yv: 0
    xf: 0
    yf: 0
    sx: 0 #sprite offsets
    sy: 0
    max_spd: 70
    falling: false
    fall_frame: 1
    done: false
    nommed: false
    frame: 0

    constructor: (sprite_url, world) ->
        @image = new SpriteImage(sprite_url)
        @pick_new_direction()
        @world = world
        @affinity = Math.random() * .1 + .05
        @nommed_by = null
        @frame = Math.floor(Math.random() * 8)

    update: (dt) ->
        [lastxv, lastyv] = [@xv, @yv]
        if Math.round(Math.random() * 10) == 1
            @pick_new_direction()

        if dim([@xv, @yv]) > @max_spd
            @xv /= 1.4
            @yv /= 1.4

        @xv -= dt
        @yv -= dt
        @move(dt)

        if @fall_frame >= 3
            @falling_done =true
            @falling = false
            @world.remove_sprite(this)

        if @nommed and not @falling
            [@xv, @yv] = [lastxv, lastyv] 

        #adjust frame
        @frame += dt*8
        if @frame > 9
            @frame = 0

        @sx = Math.floor(@frame) * @w



    nom_by: (baddie) ->
        @nommed = true
        @nommed_by = baddie.origin
        @max_spd = baddie.spd
        #play sound 
        vec_to_target = [@nommed_by.x - @x, @nommed_by.y - @y]
        [@xv, @yv] = normalize(vec_to_target)
        @xv *= @max_spd
        @yv *= @max_spd 

    move: (dt) ->
        @x += @xv * dt
        @y += @yv * dt
        if 0 > @x or @x > (canvas.width - 16)
            @xv *= -1
            @x += @xv * dt

        if 0 > @y or @y > (canvas.height - 16)
            @yv *= -1
            @y += @yv * dt

    dist_from: (other_dude) ->
        if other_dude == this
            return 0
        else
            distance(@x, @y, other_dude.x, other_dude.y) 

    draw: (ctx) ->
        if @falling == false
            @drawImage ctx, @sx, @sy, @x, @y
        else
            @drawImage ctx, @sx, SPACE*@h, @x, @y
            ctx.save()
            ctx.translate(@x + 8, @y + 8)
            ctx.scale(1/ Math.pow(@fall_frame,3), 1/ Math.pow(@fall_frame,3))
            ctx.rotate(1-@fall_frame)
            @drawImage ctx, @sx, 0, -8, -8
            ctx.restore()
            @fall_frame += .08

    die: ->
        if not @falling and not @falling_done
            @falling = true
            @falling_done = false
            @fall_frame = 1
            @xv = 0
            @yv = 0

    pick_new_direction: () ->
        @xv += (Math.random() * 40) - 20
        @yv += (Math.random() * 40) - 20

    #adjust our velocities to avoid others
    move_separation: (others, weight, max_dist) ->
        for other in others
            vec = [@x - other.x, @y - other.y]
            #console.log "vecs: #{vecs}"
            dist = dim(vec)
            if dist > max_dist
                return
            if not isNaN(vec[0]) and dist != 0
                @blend_move_vec( vec, weight/dist)

        #console.log "xv, yv #{@xv}, #{@yv}"

    #adjust our velocity to move towards the centroid of all of them
    move_centroid: (centroidx, centroidy) ->
        vec_to_centroid = [centroidx - @x, centroidy - @y]
        @blend_move_vec(vec_to_centroid, @affinity)

    #blend our current xv,yv with a new vec, weighting the new vec accordingly
    #new_vec is not expected to be normalized
    blend_move_vec: (vec, weight) ->
        weight = Math.min weight, 30

        vec = [vec[0]*weight + @xv, vec[1]*weight + @yv]
        @xv = vec[0] / (1 + weight/2)
        @yv = vec[1] / (1 + weight/2)

        #console.log "xv, yv #{@xv}, #{@yv}"
        # 


class Hero extends Dood
    spd: 180

    update: (dt) ->
        if atom.input.mouse.x and atom.input.mouse.y
            v = [atom.input.mouse.x - @x, atom.input.mouse.y - @y]
            @blend_move_vec(v, 1)
            #console.log "hero vec: #{@xv} , #{@yv}"
        else
            return

        spd = dim([@xv, @yv])
        if spd > @spd
            [@xv, @yv] = normalize( [@xv, @yv] )
            @xv *= @spd
            @yv *= @spd

        @move(dt)

class Bad extends Dood
    spd: 110
    toggled: false
    constructor: (sprite_url, world) ->
        @image = new SpriteImage(sprite_url)
        @world = world
        @origin = {x: 0, y:0}
        @pick_target()
        @frame = Math.floor(Math.random() * 7)

    pick_target: ->
        @target = @world.doods[Math.round(Math.random() * (@world.doods.length-1))]

    update: (dt) ->
        if not @target
            @pick_target()
        vec_to_target = [@target.x - @x, @target.y - @y]
        @blend_move_vec(vec_to_target, .3)

        #bads avoid the hero
        @move_separation([@world.hero], 40, 170) unless @toggled

        spd = dim([@xv, @yv])
        if spd > @spd
            [@xv, @yv] = normalize( [@xv, @yv] )
            @xv *= @spd
            @yv *= @spd

        @move(dt)

        @frame += dt*12
        if @frame > 7
            @frame = 0

        @sx = Math.floor(@frame) * @w

    retreat: ->
        @target = @origin
        @toggled = true

    move: (dt) ->
        @x += @xv * dt
        @y += @yv * dt

        if Math.abs(@x - @target.x) < 20 and Math.abs(@y - @target.y) < 20
            if @toggled
                @world.remove_sprite(this) 
            else
                console.log "caught! #{@x}, #{@y} -- #{@target.x}, #{@target.y}"
                sounds.playSound('hehe', .5)
                @target.nom_by(this)
                @target = @origin
                @toggled = true


distance = (x1, y1, x2, y2) ->
    Math.sqrt( Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2))

dim = (vec) ->
    distance(0, 0, vec[0], vec[1])

normalize = (vec) ->
    _dim = distance(0,0, vec[0], vec[1])
    [vec[0]/ _dim, vec[1]/_dim]

random = (to, from) ->
    if not from
        return Math.random() * to
    return Math.random() * (to - from) + from

class TitleScreen extends atom.Game
    last_wave: null
    last_score: null

    constructor: ->
        @bg = new Background()
        @timer = 3
        @time = 0
        @bg.drop_some_tiles(.1)

        super()

    update: (dt) ->
        @timer -= dt
        @time += dt
        if atom.input.pressed 'begin'
            @stop()
            sounds.playSound('fall')
            setTimeout ->
                game = new Game
                game.run()

                window.onblur = -> game.stop()
                window.onfocus = -> game.run()
            , 0

        if @timer <= 0
            @bg.drop_some_tiles(.83)
            sounds.playSound('fall', .3)
            @timer = 2

    draw: ->
        @bg.draw(ctx)
        ctx.save()
        ctx.fillStyle = 'rgba(0,0,0,0.3)'
        ctx.fillRect 0, 0, canvas.width, canvas.height
        ctx.font = '80px Mate SC'
        ctx.fillStyle = 'rgba(135,155,200,1)'
        ctx.textAlign = 'center'
        ctx.fillText 'CRUMBLE', canvas.width/2, 250
        ctx.font = '25px Mate SC'
        ctx.fillStyle = 'rgba(115,125,170,1)'
        ctx.fillText 'PRESS SPACE TO PLAY', canvas.width/2, 300 if Math.floor(@time*3) % 3

        ctx.restore()


game = new TitleScreen
game.run()


