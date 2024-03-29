// Generated by CoffeeScript 1.3.1
(function() {
  var Background, Entity, Game, Hero, Sprite, SpriteImage, TitleScreen, World, batSpeed, canvas, ctx, game, initSound, point2canvas, snd_ctx, v,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  canvas = atom.canvas;

  canvas.width = 800;

  canvas.height = 600;

  ctx = atom.context;

  ctx.scale(1, -1);

  ctx.translate(0, -600);

  snd_ctx = new webkitAudioContext;

  window.sm = null;

  initSound = function() {
    var sm;
    console.log('in initSound!');
    sm = new sound_map.SoundMap(snd_ctx, {
      s1: 'sound/select.wav',
      s2: 'sound/select.wav'
    }, function(_sound_map) {
      window.sm = _sound_map;
      return console.log('loader callback!');
    });
    sm.load();
    return sm;
  };

  window.sm = initSound();

  batSpeed = 200;

  v = cp.v;

  Game = (function(_super) {

    __extends(Game, _super);

    Game.name = 'Game';

    function Game() {
      this.score = [0, 0];
      this.dir = -1;
      this.reset();
    }

    Game.prototype.newBat = function() {
      var body, shape;
      body = new cp.Body(Infinity, cp.momentForBox(Infinity, 50, 200));
      shape = this.space.addShape(new cp.BoxShape(body, 50, 200));
      shape.setElasticity(1);
      shape.setFriction(0.8);
      shape.group = 1;
      return body;
    };

    Game.prototype.newBall = function() {
      var body, shape;
      body = this.space.addBody(new cp.Body(25, cp.momentForBox(80, 20, 20)));
      shape = this.space.addShape(new cp.BoxShape(body, 20, 20));
      shape.setElasticity(0.9);
      shape.setFriction(0.6);
      return body;
    };

    Game.prototype.addWalls = function() {
      var bottom, top;
      bottom = this.space.addShape(new cp.SegmentShape(this.space.staticBody, v(0, 0), v(800, 0), 0));
      bottom.setElasticity(1);
      bottom.setFriction(0.1);
      bottom.group = 1;
      top = this.space.addShape(new cp.SegmentShape(this.space.staticBody, v(0, 600), v(800, 600), 0));
      top.setElasticity(1);
      top.setFriction(0.1);
      return top.group = 1;
    };

    Game.prototype.update = function(dt) {
      var b, i, _i, _len, _ref;
      if (atom.input.pressed('tie')) {
        return this.reset();
      }
      dt = 1 / 60;
      _ref = this.bats;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        b = _ref[i];
        if (atom.input.down("b" + i + "up")) {
          b.setVelocity(v(0, batSpeed));
          b.w = 1 * (i * 2 - 1);
        } else if (atom.input.down("b" + i + "down")) {
          b.setVelocity(v(0, -batSpeed));
          b.w = -1 * (i * 2 - 1);
        } else {
          b.setVelocity(v(0, 0));
          b.w = 0;
        }
        b.position_func(dt);
      }
      this.space.step(dt);
      if (this.ball.p.x < -80) {
        this.win(1);
      } else if (this.ball.p.x > canvas.width + 80) {
        this.win(0);
      }
      if (this.ball.p.y < -100 || this.ball.p.y > canvas.height + 100) {
        return this.win(this.ball.p.x < canvas.width / 2 ? 1 : 0);
      }
    };

    Game.prototype.win = function(p) {
      this.score[p]++;
      this.dir = p === 0 ? -1 : 1;
      return this.reset();
    };

    Game.prototype.reset = function() {
      var b, begin, _i, _j, _k, _len, _len1, _ref, _ref1;
      this.space = new cp.Space;
      this.space.gravity = v(0, -50);
      this.space.damping = 0.92;
      this.bats = [];
      for (_i = 0; _i <= 1; _i++) {
        this.bats.push(this.newBat());
      }
      this.bats[0].setPos(v(40, 300));
      this.bats[1].setPos(v(canvas.width - 40, 300));
      _ref = this.bats;
      for (_j = 0, _len = _ref.length; _j < _len; _j++) {
        b = _ref[_j];
        b.shapeList[0].update(b.p, b.rot);
      }
      this.ball = this.newBall();
      this.ball.setPos(v(400 - 10, 300 - 10));
      this.ball.setVelocity(v(160 * this.dir, 0));
      _ref1 = [this.ball];
      for (_k = 0, _len1 = _ref1.length; _k < _len1; _k++) {
        b = _ref1[_k];
        b.shapeList[0].update(b.p, b.rot);
      }
      begin = function(arb, space) {
        console.log('in collision handler');
        sm.playSound(sm.s2, snd_ctx);
        return true;
      };
      this.space.addCollisionHandler(this.ball, this.bats[0], begin, begin, begin, begin);
      this.space.addCollisionHandler(this.ball, this.bats[1], function(arb, space) {
        return sm.playSound(sm.s2, snd_ctx);
      });
      this.addWalls();
      ctx.fillStyle = 'black';
      return ctx.fillRect(0, 0, canvas.width, canvas.height);
    };

    return Game;

  })(atom.Game);

  ({
    draw: function() {
      var b, _i, _len, _ref;
      ctx.fillStyle = 'rgba(0,0,0,0.1)';
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      ctx.fillStyle = 'white';
      _ref = this.bats;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        b = _ref[_i];
        b.shapeList[0].draw(ctx);
      }
      this.ball.shapeList[0].draw(ctx);
      ctx.save();
      ctx.font = '50px Mate SC';
      ctx.scale(1, -1);
      ctx.textBaseline = 'top';
      ctx.textAlign = 'left';
      ctx.fillText(this.score[0], 150, -590);
      ctx.textAlign = 'right';
      ctx.fillText(this.score[1], 800 - 150, -590);
      return ctx.restore();
    }
  });

  point2canvas = function(a) {
    return a;
  };

  cp.PolyShape.prototype.draw = function(ctx) {
    var i, lastPoint, len, p, verts;
    ctx.beginPath();
    verts = this.tVerts;
    len = verts.length;
    lastPoint = point2canvas(new cp.Vect(verts[len - 2], verts[len - 1]));
    ctx.moveTo(lastPoint.x, lastPoint.y);
    i = 0;
    while (i < len) {
      p = point2canvas(new cp.Vect(verts[i], verts[i + 1]));
      ctx.lineTo(p.x, p.y);
      i += 2;
    }
    return ctx.fill();
  };

  atom.input.bind(atom.key.Q, 'b0up');

  atom.input.bind(atom.key.A, 'b0down');

  atom.input.bind(atom.key.UP_ARROW, 'b1up');

  atom.input.bind(atom.key.DOWN_ARROW, 'b1down');

  atom.input.bind(atom.key.T, 'tie');

  atom.input.bind(atom.key.SPACE, 'begin');

  console.log('parsing title');

  TitleScreen = (function(_super) {

    __extends(TitleScreen, _super);

    TitleScreen.name = 'TitleScreen';

    function TitleScreen() {
      TitleScreen.__super__.constructor.call(this);
      this.time = 0;
    }

    TitleScreen.prototype.update = function(dt) {
      this.time += dt;
      if (atom.input.pressed('begin')) {
        this.stop();
        return setTimeout(function() {
          var game;
          game = new Game;
          return game.run();
        }, 0);
      }
    };

    TitleScreen.prototype.draw = function() {
      ctx.fillStyle = 'rgba(0,0,0,0.2)';
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      ctx.save();
      ctx.scale(1, -1);
      ctx.textBaseline = 'top';
      ctx.textAlign = 'center';
      ctx.fillStyle = 'rgba(200,200,250, 1)';
      ctx.font = '80px Mate SC';
      ctx.fillText('AWESOME', 400 + Math.cos(this.time * 2) * 30 * Math.cos(this.time * 3), -500 + Math.sin(this.time * 3) * 20);
      ctx.font = '25px Mate SC';
      if (Math.floor(this.time * 3) % 2) {
        ctx.fillText('Press Space to Play', 400, -200);
      }
      return ctx.restore();
    };

    return TitleScreen;

  })(atom.Game);

  console.log('declared title');

  World = (function() {

    World.name = 'World';

    World.prototype.width = 800;

    World.prototype.height = 600;

    World.prototype.viewWidth = canvas.width;

    World.prototype.viewHeight = canvas.height;

    World.prototype.sprites = [];

    function World() {
      console.log('creating World');
      this.hero = new Hero(this);
      this.sprites.push(new Background(this));
      this.sprites.push(this.hero);
      console.log('created World');
    }

    World.prototype.reset = function() {
      return this.hero.reset(this.width, this.height);
    };

    World.prototype.heroViewOffsetX = function() {
      return this.hero.viewOffsetX(this.viewWidth);
    };

    World.prototype.heroViewOffsetY = function() {
      return this.hero.viewOffsetY(this.viewHeight);
    };

    World.prototype.viewWidthLimit = function() {
      return this.width - this.viewWidth;
    };

    World.prototype.viewHeightLimit = function() {
      return this.height - this.viewHeight;
    };

    World.prototype.atViewLimitLeft = function() {
      return this.hero.x < this.heroViewOffsetX();
    };

    World.prototype.atViewLimitTop = function() {
      return this.hero.y < this.heroViewOffsetY();
    };

    World.prototype.atViewLimitRight = function() {
      return this.hero.x > this.viewWidthLimit() + this.heroViewOffsetX();
    };

    World.prototype.atViewLimitBottom = function() {
      return this.hero.y > this.viewHeightLimit() + this.heroViewOffsetY();
    };

    World.prototype.render = function(lastUpdate, lastElapsed) {
      var sprite, _i, _len, _ref, _results;
      _ref = this.sprites;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        sprite = _ref[_i];
        _results.push(sprite.draw());
      }
      return _results;
    };

    return World;

  })();

  SpriteImage = (function() {

    SpriteImage.name = 'SpriteImage';

    SpriteImage.prototype.ready = false;

    function SpriteImage(url) {
      var image,
        _this = this;
      image = new Image;
      image.src = 'sheet.png';
      image.onload = function() {
        return _this.ready = true;
      };
      this.image = image;
    }

    return SpriteImage;

  })();

  Sprite = (function() {

    Sprite.name = 'Sprite';

    Sprite.prototype.sx = 0;

    Sprite.prototype.sy = 0;

    Sprite.prototype.sw = 0;

    Sprite.prototype.sx = 0;

    Sprite.prototype.dx = 0;

    Sprite.prototype.dy = 0;

    Sprite.prototype.dw = 0;

    Sprite.prototype.dh = 0;

    Sprite.prototype.x = 0;

    Sprite.prototype.y = 0;

    Sprite.prototype.image = new SpriteImage;

    function Sprite(world) {
      this.world = world;
    }

    Sprite.prototype.drawImage = function(sx, sy, dx, dy) {
      if (this.image.ready) {
        return this.world.ctx.drawImage(this.image.image, sx, sy, this.sw, this.sh, dx, dy, this.dw, this.dh);
      }
    };

    return Sprite;

  })();

  Background = (function(_super) {

    __extends(Background, _super);

    Background.name = 'Background';

    function Background(world) {
      this.dw = world.viewWidth;
      this.dh = world.viewHeight;
      this.sw = world.viewWidth;
      this.sh = world.viewHeight;
      console.log('midcreated BG');
      Background.__super__.constructor.call(this, world);
      console.log('created BG');
    }

    Background.prototype.draw = function() {
      var x, y;
      x = this.world.hero.x - this.world.heroViewOffsetX();
      y = this.world.hero.y - this.world.heroViewOffsetY();
      if (this.world.atViewLimitLeft()) {
        x = 0;
      }
      if (this.world.atViewLimitTop()) {
        y = 0;
      }
      if (this.world.atViewLimitRight()) {
        x = this.world.viewWidthLimit();
      }
      if (this.world.atViewLimitBottom()) {
        y = this.world.viewHeightLimit();
      }
      return this.drawImage(x, y, this.dx, this.dy);
    };

    return Background;

  })(Sprite);

  Entity = (function(_super) {

    __extends(Entity, _super);

    Entity.name = 'Entity';

    function Entity() {
      return Entity.__super__.constructor.apply(this, arguments);
    }

    Entity.prototype.draw = function() {
      if (this.world.atViewLimitLeft()) {
        this.dx = this.x;
      }
      if (this.world.atViewLimitTop()) {
        this.dy = this.y;
      }
      if (this.world.atViewLimitRight()) {
        this.dx = this.x - this.world.viewWidthLimit();
      }
      if (this.world.atViewLimitBottom()) {
        this.dy = this.y - this.world.viewHeightLimit();
      }
      return this.drawImage(this.sx, this.sy, this.dx, this.dy);
    };

    return Entity;

  })(Sprite);

  Hero = (function(_super) {

    __extends(Hero, _super);

    Hero.name = 'Hero';

    function Hero() {
      return Hero.__super__.constructor.apply(this, arguments);
    }

    Hero.prototype.sw = 32;

    Hero.prototype.sh = 30;

    Hero.prototype.dw = 32;

    Hero.prototype.dh = 30;

    Hero.prototype.speed = 256;

    Hero.prototype.sy = 513;

    Hero.prototype.direction = 0;

    Hero.prototype.draw = function() {
      this.dx = this.world.heroViewOffsetX();
      this.dy = this.world.heroViewOffsetY();
      this.sx = Math.round(this.x + this.y) % 64 < 32 ? this.direction : this.direction + 32;
      return Hero.__super__.draw.apply(this, arguments);
    };

    Hero.prototype.velocity = function(mod) {
      return this.speed * mod;
    };

    Hero.prototype.collision = function(x, y) {
      var o, _i, _len, _ref;
      _ref = this.world.collidableSprites();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        o = _ref[_i];
        if (y > o.y - this.dh && y < o.y + o.dh && x > o.x - this.dw && x < o.x + o.dw) {
          return true;
        }
      }
      return false;
    };

    Hero.prototype.up = function(mod) {
      var y;
      this.direction = 64;
      y = this.y - this.velocity(mod);
      if (y > 0 && !this.collision(this.x, y)) {
        return this.y -= this.velocity(mod);
      }
    };

    Hero.prototype.down = function(mod, height) {
      var y;
      this.direction = 0;
      y = this.y + this.velocity(mod);
      if (y < height - this.dh && !this.collision(this.x, y)) {
        return this.y += this.velocity(mod);
      }
    };

    Hero.prototype.left = function(mod) {
      var x;
      this.direction = 128;
      x = this.x - this.velocity(mod);
      if (x > 0 && !this.collision(x, this.y)) {
        return this.x -= this.velocity(mod);
      }
    };

    Hero.prototype.right = function(mod, width) {
      var x;
      this.direction = 192;
      x = this.x + this.velocity(mod);
      if (x < width - this.dw && !this.collision(x, this.y)) {
        return this.x += this.velocity(mod);
      }
    };

    Hero.prototype.viewOffsetX = function(width) {
      return (width / 2) - (this.dw / 2);
    };

    Hero.prototype.viewOffsetY = function(height) {
      return (height / 2) - (this.dh / 2);
    };

    Hero.prototype.reset = function(width, height) {
      this.x = this.viewOffsetX(width);
      return this.y = this.viewOffsetY(height);
    };

    return Hero;

  })(Entity);

  game = new TitleScreen;

  game.run();

  window.onblur = function() {
    return game.stop();
  };

  window.onfocus = function() {
    return game.run();
  };

}).call(this);
