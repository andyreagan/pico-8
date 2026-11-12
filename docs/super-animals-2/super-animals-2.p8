pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- super animals 2
-- two players race the evil
-- monster boss to the ultra
-- diamond! each picks an animal.

function _init()
 grav=0.25
 chars={
  {name="cheetah",spd=2,jump=4.6,w=14,h=12,sh=16,
   info={"fastest runner and","highest jumper!","x: hold to sprint"}},
  {name="dragon",spd=1.2,jump=3.6,w=12,h=10,sh=12,
   info={"breathes fire! monsters","can't touch the fire.","x: breathe fire"}},
  {name="unicorn",spd=1.3,jump=3.6,w=12,h=12,sh=16,
   info={"shoots rainbows! monsters","can't touch rainbows.","x: rainbow (up+x aims up)"}},
  {name="snail",spd=0.8,jump=2.9,w=10,h=7,sh=8,
   info={"sticks to walls+ceilings","x: hide in shell (safe!)","if stuck, you fall off"}},
  {name="penguin",spd=1.1,jump=3.2,w=8,h=11,sh=11,
   info={"swims in water!","x on ice: belly slide,","it knocks out monsters"}},
 }
 -- who picked what. p1 is yellow,
 -- p2 is pink
 pcol={10,14}
 sels={{i=1,on=true},{i=2,on=false}}
 state="select"
 parts={}
 clouds={}
 for i=1,8 do add(clouds,{x=rnd(768),y=4+rnd(50)}) end
end

-->8
-- level

level={
 "................................................................................................",
 "................................................................................................",
 "................................................................................................",
 "................................................................................................",
 "................................................................................................",
 "................................................................................................",
 "................................................................................................",
 ".....................................b..............m.....b.....................................",
 ".................###......b......................sssssss................b.......................",
 ".................................................sssssss..........................sssssss.......",
 "..............s.................................ssssssss....................................D...",
 "..P.....s..m..s...m.....m....m...............c.sssssssss.......m................c.....m....sss..",
 "####################iiiiiiiiiii#wwsswwssww##################iiiiii#wwsswwssww###################",
 "################################wwwwwwwwww#########################wwwwwwwwww###################",
 "################################wwwwwwwwww#########################wwwwwwwwww###################",
}

function load_level()
 mw=#level[1]
 tiles={} mons={} flags={}
 for r=0,14 do
  tiles[r]={}
  for c=0,mw-1 do
   local ch=sub(level[r+1],c+1,c+1)
   local x,y=c*8,r*8
   if ch=="m" then
    add(mons,{kind=1,x=x,y=y,w=8,h=8,vx=-0.4})
    ch="."
   elseif ch=="b" then
    add(mons,{kind=2,x=x,y=y,ox=x,oy=y,w=8,h=6,t=rnd()})
    ch="."
   elseif ch=="c" then
    add(flags,{x=x,y=y-8})
    ch="."
   elseif ch=="D" then
    gem={x=x-2,y=y-1,w=12,h=9}
    ch="."
   elseif ch=="P" then
    resx=x resy=y+8
    ch="."
   end
   tiles[r][c]=ch
  end
 end
end

function tile(c,r)
 if c<0 or c>=mw then return "s" end
 if r<0 or r>14 then return "." end
 return tiles[r][c]
end

function tile_at(x,y) return tile(flr(x/8),flr(y/8)) end

function is_solid(ch) return ch=="#" or ch=="s" or ch=="i" end
function is_water(ch) return ch=="w" end

-- does a box touch any tile that
-- passes test f?
function box_hits(x,y,w,h,f)
 for tx=flr(x/8),flr((x+w-1)/8) do
  for ty=flr(y/8),flr((y+h-1)/8) do
   if f(tile(tx,ty)) then return true end
  end
 end
 return false
end

function blocked(e,x,y) return box_hits(x,y,e.w,e.h,is_solid) end

-- move 1px at a time so nothing
-- ever goes through anything
function move(e)
 e.hitx=0 e.hity=0
 local d=e.vx
 while d!=0 do
  local s=mid(-1,d,1)
  if blocked(e,e.x+s,e.y) then e.hitx=sgn(s) e.vx=0 break end
  e.x+=s d-=s
 end
 d=e.vy
 while d!=0 do
  local s=mid(-1,d,1)
  if blocked(e,e.x,e.y+s) then e.hity=sgn(s) e.vy=0 break end
  e.y+=s d-=s
 end
 e.ground=blocked(e,e.x,e.y+1)
end

function overlap(a,b)
 return a.x+1<b.x+b.w and b.x+1<a.x+a.w
  and a.y+1<b.y+b.h and b.y+1<a.y+a.h
end

function poof(x,y,cols)
 for i=1,12 do
  local a=rnd()
  add(parts,{x=x,y=y,vx=cos(a)*(0.5+rnd()),vy=sin(a)*(0.5+rnd()),
   c=rnd(cols),t=10+rnd(15)})
 end
end

-->8
-- game

function start_game()
 load_level()
 ps={}
 for n=1,2 do
  local s=sels[n]
  if s.on and s.rdy then
   local c=chars[s.i]
   local p={n=n-1,c=c,w=c.w,h=c.h,face=1,cool=0,fuel=40,
    lives=3,col=pcol[n]}
   add(ps,p)
   spawn(p)
   p.hurt=0
  end
  s.rdy=false
 end
 boss={x=-20,y=30,w=16,h=16,stun=0,wait=150}
 bspd=0.45
 beams={}
 parts={}
 timer=0
 camx=0
 state="play"
 msg=#ps>1 and "go team!" or "go "..ps[1].c.name.."!"
 msgt=60
end

-- back to the last checkpoint
function spawn(p)
 p.x=resx-p.n*10 p.y=resy-p.h
 p.vx=0 p.vy=0 p.stick=nil p.shell=false p.slide=0
 p.bub=false p.fire=false p.ride=nil
 p.hurt=90
end

-- the other player, if they are
-- up and running
function buddy(p)
 for o in all(ps) do
  if o!=p and not o.out and not o.bub then return o end
 end
end

-- float in a bubble over to your
-- buddy (when you get hurt or
-- left behind)
function float(p)
 p.bub=true p.bt=0
 p.vx=0 p.vy=0 p.stick=nil p.shell=false p.slide=0
 p.fire=false p.ride=nil
end

function lose_life(p)
 p.lives-=1
 sfx(4)
 poof(p.x+p.w/2,p.y+p.h/2,{8,7,10})
 if p.lives<=0 then
  p.out=true
  for o in all(ps) do
   if not o.out then
    msg="p"..(p.n+1).." is out!" msgt=60
    return
   end
  end
  state="over" overmsg="out of lives!"
  return
 end
 if buddy(p) then float(p) else spawn(p) end
 msg="ouch!" msgt=40
end

-- monsters can't hurt you right
-- after a hit, in a bubble, a
-- snail in its shell or a sliding
-- penguin
function safe(p)
 return p.out or p.bub or p.hurt>0 or p.shell or p.slide>0
end

-- fire and rainbows: zap monsters,
-- stun the boss
function zap(a)
 for i=#mons,1,-1 do
  local m=mons[i]
  if overlap(a,m) then
   poof(m.x+4,m.y+4,{2,8,14})
   deli(mons,i)
   sfx(3)
  end
 end
 if boss.stun<=0 and overlap(a,boss) then
  boss.stun=90
  sfx(3)
 end
end

function _update()
 if msgt and msgt>0 then msgt-=1 end
 for i=#parts,1,-1 do
  local p=parts[i]
  p.x+=p.vx p.y+=p.vy p.t-=1
  if p.t<=0 then deli(parts,i) end
 end
 if state=="select" then
  update_select()
 elseif state=="play" then
  timer+=1
  for p in all(ps) do
   if state=="play" and not p.out then update_player(p) end
  end
  if state=="play" then carry() end
  if state=="play" then update_cam() end
  if state=="play" then update_mons() end
  if state=="play" then update_beams() end
  if state=="play" then update_boss() end
 elseif btnp(4) or btnp(5) or btnp(4,1) or btnp(5,1) then
  state="select"
 end
end

-- each player picks an animal and
-- presses z when ready. player 2
-- joins by pressing a button.
function update_select()
 for n=1,2 do
  local s,k=sels[n],n-1
  if not s.on then
   if btnp(4,k) or btnp(5,k) then s.on=true sfx(6) end
  elseif s.rdy then
   if btnp(5,k) then
    s.rdy=false
   elseif n==1 and btnp(4,k) then
    -- p1 pressing z again starts
    -- without waiting for p2
    start_game()
    return
   end
  else
   if btnp(0,k) then s.i=(s.i-2)%#chars+1 sfx(6) end
   if btnp(1,k) then s.i=s.i%#chars+1 sfx(6) end
   if btnp(4,k) then
    s.rdy=true sfx(0)
   elseif n==2 and btnp(5,k) then
    s.on=false
   end
  end
 end
 if sels[1].rdy and (sels[2].rdy or not sels[2].on) then
  start_game()
 end
end

function update_player(p)
 local c=p.c
 if p.hurt>0 then p.hurt-=1 end
 if p.cool>0 then p.cool-=1 end
 if p.bub then update_bub(p) return end
 -- idle = not touching any button.
 -- an idle player can ride along
 -- with their buddy (see carry)
 p.idle=true
 for i=0,5 do
  if btn(i,p.n) then p.idle=false p.ride=nil end
 end
 local dir=0
 if btn(0,p.n) then dir=-1 end
 if btn(1,p.n) then dir=1 end
 if dir!=0 and not p.shell then p.face=dir end
 -- water: only penguins allowed!
 local wet=box_hits(p.x,p.y,p.w,p.h,is_water)
 if wet and c.name!="penguin" then
  sfx(9)
  lose_life(p)
  return
 end
 if p.ride then
  -- riding: carry() moves us
 elseif not (c.name=="snail" and snail_update(p,dir)) then
  walk(p,c,dir,wet)
 end
 if p.y>120 then lose_life(p) return end
 for f in all(flags) do
  if not f.on and p.x>=f.x then
   f.on=true resx=f.x resy=f.y+16
   sfx(6) msg="checkpoint!" msgt=40
  end
 end
 if overlap(p,{x=gem.x,y=gem.y-12,w=12,h=21}) then
  state="win" winner=p
  sfx(8)
  return
 end
 -- left behind off the screen:
 -- float over to your buddy
 if p.x+p.w<camx-2 and buddy(p) then
  float(p)
  sfx(5)
 end
end

-- if you stand still while you
-- are touching your buddy, you go
-- along with them
function carry()
 for p in all(ps) do
  local o=buddy(p)
  if p.out or p.bub or not o then
   p.ride=nil
  elseif p.ride then
   local nx,ny=o.x+p.ox,o.y+p.oy
   -- you get left behind if you
   -- don't fit, or at the water. a
   -- penguin can't take you out
   -- over the water at all
   if blocked(p,nx,ny) or (p.c.name!="penguin"
    and (box_hits(nx,ny,p.w,p.h,is_water)
     or (o.c.name=="penguin" and over_water(p,nx,ny)))) then
    p.ride=nil
   else
    p.x=nx p.y=ny p.vx=0 p.vy=0
    p.ground=o.ground
    if not p.shell then p.face=o.face end
   end
  elseif p.idle and not o.idle and not o.ride and overlap(p,o) then
   p.ride=o p.ox=p.x-o.x p.oy=p.y-o.y
   p.stick=nil p.slide=0 p.fire=false
  end
 end
end

function update_bub(p)
 local o=buddy(p)
 if not o then spawn(p) return end
 p.bt+=1
 p.x+=(o.x+o.w/2-p.w/2-p.x)*0.1
 p.y+=(max(o.y+o.h-34,10)-p.y)*0.1
 if p.bt>30 and btnp(4,p.n) and can_pop(p) then
  p.bub=false
  p.hurt=60
  sfx(0)
 end
end

-- a bubble won't pop inside a
-- wall, or over water (unless
-- you're the penguin)
function can_pop(p)
 if blocked(p,p.x,p.y) then return false end
 return p.c.name=="penguin" or not over_water(p,p.x,p.y)
end

-- would p fall into water from
-- x,y?
function over_water(p,x,y)
 for i=0,1 do
  local tx=flr((x+i*(p.w-1))/8)
  for ty=flr(y/8),14 do
   local ch=tile(tx,ty)
   if ch=="w" then return true end
   if is_solid(ch) then break end
  end
 end
 return false
end

-- the camera sits between the
-- players but never lets the one
-- in front get too close to the
-- edge
function update_cam()
 local lo,hi
 for p in all(ps) do
  if not p.out and not p.bub then
   local x=p.x+p.w/2
   lo=min(lo or x,x) hi=max(hi or x,x)
  end
 end
 if not hi then return end
 local tx=max((lo+hi)/2-64,hi-84)
 camx+=(mid(0,tx,mw*8-128)-camx)*0.25
end

function walk(p,c,dir,wet)
 local onice=p.ground and tile_at(p.x+p.w/2,p.y+p.h+1)=="i"
 local spd=c.spd
 if c.name=="cheetah" and btn(5,p.n) then spd=3 end
 if onice then
  -- ice slows everyone except
  -- the penguin, who zooms
  if c.name=="penguin" then spd=2.4 else spd*=0.5 end
 end
 -- the belly slide only works on
 -- ice (it can finish a hop)
 if p.ground and not onice then p.slide=0 end
 if p.slide>0 then
  p.slide-=1
  p.vx=p.face*3
 elseif c.name=="penguin" and onice then
  -- slippery! ease toward speed
  p.vx+=(dir*spd-p.vx)*0.06
 else
  p.vx=dir*spd
 end
 if wet then
  -- penguin swimming
  p.vx=dir*1.6
  p.vy=min(p.vy+0.08,1)
  if btn(2,p.n) or btn(4,p.n) then p.vy=max(p.vy-0.25,-1.6) end
  if btn(3,p.n) then p.vy=min(p.vy+0.15,1.2) end
  -- leap out at the surface
  if btnp(4,p.n) and not box_hits(p.x,p.y-3,p.w,3,is_water) then
   p.vy=-c.jump sfx(0)
  end
 else
  if (btnp(4,p.n) or btnp(2,p.n)) and p.ground then
   p.vy=-c.jump
   sfx(0)
  end
  if p.vy<0 and not (btn(4,p.n) or btn(2,p.n)) then p.vy+=0.3 end
  p.vy=min(p.vy+grav,4)
 end
 powers(p,c)
 move(p)
 -- a sliding penguin knocks out
 -- the bad guys
 if p.slide>0 then zap(p) end
 -- snail sticks to walls and
 -- ceilings it bumps into
 if c.name=="snail" then
  if dir!=0 and p.hitx==dir then
   p.stick="wall" p.side=dir
  elseif p.hity<0 then
   p.stick="ceil"
  end
 end
end

function powers(p,c)
 local n=c.name
 if n=="dragon" then
  p.fire=false
  if btn(5,p.n) and p.fuel>0 then
   p.fire=true
   p.fuel-=1
   if p.fuel%6==0 then sfx(1) end
   local mx=p.face>0 and p.x+p.w or p.x
   zap({x=p.face>0 and mx or mx-26,y=p.y-3,w=26,h=p.h+6})
   for i=1,3 do
    add(parts,{x=mx,y=p.y+3,vx=p.face*(1.5+rnd(2)),vy=rnd(1)-0.5,
     c=rnd({8,9,10}),t=6+rnd(8)})
   end
  elseif not btn(5,p.n) then
   p.fuel=min(40,p.fuel+0.5)
  end
 elseif n=="unicorn" then
  if btnp(5,p.n) and p.cool<=0 then
   add(beams,{x=p.face>0 and p.x+p.w or p.x-12,y=p.y+2,w=12,h=6,
    vx=4*p.face,vy=btn(2,p.n) and -2.5 or 0})
   p.cool=15
   sfx(2)
  end
 elseif n=="penguin" then
  if btnp(5,p.n) and p.slide<=0 and p.ground
   and tile_at(p.x+p.w/2,p.y+p.h+1)=="i" then
   p.slide=30
   sfx(5)
  end
 end
end

-- returns true if the snail is
-- stuck to something or in its
-- shell (so normal walking is off)
function snail_update(p,dir)
 if btnp(5,p.n) then
  p.shell=not p.shell
  sfx(5)
  -- in your shell you can't hold
  -- on, so you fall off!
  if p.shell then p.stick=nil end
 end
 if p.shell then
  p.vx=0
  p.vy=min(p.vy+grav,4)
  move(p)
  return true
 end
 if p.stick=="wall" then
  local s=p.side
  p.vx=0 p.vy=0
  if btn(2,p.n) then
   if blocked(p,p.x,p.y-1) then p.stick="ceil" else p.y-=0.6 end
  elseif btn(3,p.n) then
   if blocked(p,p.x,p.y+1) then p.stick=nil else p.y+=0.6 end
  end
  if p.stick=="wall" and not blocked(p,p.x+s,p.y) then
   -- climbed past the top: hop on
   p.stick=nil
   for i=1,5 do
    if not blocked(p,p.x+s,p.y) then p.x+=s end
   end
  end
  if dir==-s then p.stick=nil end
  if btnp(4,p.n) then p.stick=nil p.vy=-2 p.vx=-s end
  return true
 elseif p.stick=="ceil" then
  p.vy=0
  p.vx=dir*0.6
  move(p)
  if p.hitx!=0 then
   p.stick="wall" p.side=p.hitx
  elseif not blocked(p,p.x,p.y-1) or btn(3,p.n) or btnp(4,p.n) then
   p.stick=nil
  end
  return true
 end
 return false
end

function update_mons()
 for m in all(mons) do
  if m.kind==1 then
   -- walkers turn at walls, edges
   -- and water
   local sp=m.vx
   if tile_at(m.x+4,m.y+9)=="i" then sp*=0.5 end
   local nx=m.x+sp
   local foot=sp>0 and nx+7 or nx
   if blocked(m,nx,m.y) or not is_solid(tile_at(foot,m.y+9)) then
    m.vx=-m.vx
   else
    m.x=nx
   end
  else
   -- bats swoop around
   m.t+=0.008
   m.x=m.ox+sin(m.t)*16
   m.y=m.oy+sin(m.t*2.3)*6
  end
  for p in all(ps) do
   if not safe(p) and overlap(m,p) then
    lose_life(p)
    if state!="play" then return end
   end
  end
 end
end

function update_beams()
 for i=#beams,1,-1 do
  local b=beams[i]
  b.x+=b.vx b.y+=b.vy
  zap(b)
  if blocked(b,b.x,b.y) or b.x<camx-20 or b.x>camx+148 or b.y<-10 then
   deli(beams,i)
  end
 end
end

function update_boss()
 local b=boss
 if b.wait>0 then
  b.wait-=1
  if b.wait==0 then msg="the boss is coming!" msgt=60 sfx(7) end
  return
 end
 if b.stun>0 then b.stun-=1 else b.x+=bspd end
 b.y=36+sin(timer/240)*22
 for p in all(ps) do
  if not safe(p) and overlap(b,p) then
   lose_life(p)
   if state!="play" then return end
  end
 end
 if b.x+8>=gem.x+6 then
  state="over"
  overmsg="the boss got the ultra diamond!"
  sfx(7)
 end
end

-->8
-- draw

function _draw()
 cls(12)
 if state=="select" then draw_select() return end
 local cx=flr(camx)
 -- clouds drift slower than the
 -- ground for a little depth
 for c in all(clouds) do
  local x=(c.x-cx*0.5)%200-30
  circfill(x,c.y+8,5,7)
  circfill(x+6,c.y+6,6,7)
  circfill(x+12,c.y+8,5,7)
 end
 camera(cx,-8)
 draw_tiles(cx)
 for f in all(flags) do
  if f.on then pal(8,11) end
  sspr(40,64,8,16,f.x,f.y)
  pal()
 end
 -- the ultra diamond shimmers
 local rc={8,9,10,11,12,14}
 pal(12,rc[flr(t()*8)%6+1])
 sspr(112,32,12,9,gem.x,gem.y)
 pal()
 if rnd()<0.2 then
  add(parts,{x=gem.x+rnd(12),y=gem.y+rnd(9),vx=0,vy=-0.3,c=7,t=10})
 end
 for m in all(mons) do
  local f=flr(t()*4)%2
  if m.kind==1 then
   sspr(80+f*8,32,8,8,m.x,m.y,8,8,m.vx>0)
  else
   sspr(80+f*8,40,8,6,m.x,m.y)
  end
 end
 for b in all(beams) do
  for i=0,5 do
   line(b.x,b.y+i,b.x+b.w-1,b.y+i,rc[i+1])
  end
 end
 for p in all(ps) do
  if not p.out then draw_player(p) end
 end
 local b=boss
 if b.stun>0 and b.stun%6<3 then for i=1,15 do pal(i,7) end end
 sspr(96,32,16,16,b.x,b.y)
 pal()
 for p in all(parts) do pset(p.x,p.y,p.c) end
 camera()
 draw_hud()
 if msgt>0 then cprint(msg,24,7) end
 if state=="win" then
  local who=#ps>1 and "p"..(winner.n+1) or "you"
  box(who.." got the ultra diamond!","time "..flr(timer/30).."s  z: play again")
 elseif state=="over" then
  box(overmsg,"z: try again")
 end
end

function draw_tiles(cx)
 for c=flr(cx/8),flr(cx/8)+16 do
  for r=0,14 do
   local ch=tile(c,r)
   local x,y=c*8,r*8
   if ch=="#" then
    spr(is_solid(tile(c,r-1)) and 129 or 128,x,y)
   elseif ch=="s" then spr(130,x,y)
   elseif ch=="i" then spr(131,x,y)
   elseif ch=="w" then
    spr(132,x,y)
    if tile(c,r-1)!="w" then
     -- wavy surface
     for i=0,7 do
      pset(x+i,y+(sin((x+i)/16+t())>0 and 0 or 1),12)
     end
    end
   end
  end
 end
end

function draw_player(p)
 local n=p.c.name
 local x,y,fl=p.x+p.w/2,p.y+p.h,p.face<0
 local top=y-p.c.sh
 if p.bub then
  -- bubble: press z to pop out
  circ(x,y-p.h/2,13,7)
  pset(x-6,y-p.h/2-8,7)
  pset(x-8,y-p.h/2-6,7)
  if p.bt>30 and t()%1<0.6 then print("\142",x-3,y+9,7) end
 elseif p.hurt>0 and p.hurt%4<2 then
  return
 end
 if n=="cheetah" then
  -- alternate the two cheetah
  -- drawings while running
  local run=not p.bub and (not p.ground or (p.vx!=0 and flr(t()*10)%2==0))
  if run then
   sspr(8,20,26,10,x-13,y-10,26,10,p.face>0)
  else
   sspr(8,1,26,16,x-13,y-16,26,16,p.face>0)
  end
 elseif n=="dragon" then
  sspr(0,32,16,12,x-8,y-12,16,12,fl)
  if p.fuel<40 then
   line(x-5,top-9,x+5,top-9,5)
   if p.fuel>0 then line(x-5,top-9,x-5+p.fuel/4,top-9,9) end
  end
 elseif n=="unicorn" then
  sspr(16,32,16,16,x-8,y-16,16,16,fl)
 elseif n=="snail" then
  if p.shell then
   sspr(52,32,8,7,x-4,y-7)
  elseif p.stick=="wall" then
   sspr(44,32,8,12,p.side>0 and p.x+p.w-8 or p.x,y-12,8,12,p.side<0)
  elseif p.stick=="ceil" then
   sspr(32,32,12,8,x-6,p.y,12,8,fl,true)
  else
   sspr(32,32,12,8,x-6,y-8,12,8,fl)
  end
 elseif n=="penguin" then
  if p.slide>0 then
   sspr(64,44,12,6,x-6,y-6,12,6,fl)
  else
   local bob=(p.ground and p.vx!=0 and flr(t()*8)%2==0) and 1 or 0
   sspr(64,32,9,11,x-4,y-11-bob,9,11,fl)
  end
 end
 -- with two players, a little
 -- arrow shows who is who
 if #ps>1 and not p.bub then
  line(x-2,top-6,x+2,top-6,p.col)
  line(x-1,top-5,x+1,top-5,p.col)
  pset(x,top-4,p.col)
 end
end

function draw_hud()
 rectfill(0,0,127,7,1)
 for p in all(ps) do
  for i=1,3 do
   print("\135",p.n==0 and i*7-6 or 128-i*7,1,
    i<=p.lives and (#ps>1 and p.col or 8) or 5)
  end
 end
 -- race bar: you vs the boss
 local x0,x1=30,86
 line(x0,4,x1,4,6)
 local function mark(x,c)
  local f=mid(0,(x+8)/(gem.x+6),1)
  circfill(x0+f*(x1-x0),4,2,c)
 end
 mark(boss.x,2)
 for p in all(ps) do
  if not p.out then mark(p.x,p.col) end
 end
 pal(12,14)
 sspr(112,32,12,9,x1+4,0,8,6)
 pal()
end

function cprint(s,y,c)
 print(s,64-#s*2,y,c)
end

function box(a,b)
 rectfill(2,48,125,76,1)
 rect(2,48,125,76,7)
 cprint(a,55,7)
 cprint(b,66,6)
end

function draw_select()
 cprint("super animals 2",4,7)
 cprint("race the boss to the",13,1)
 cprint("ultra diamond!",20,1)
 for i=1,5 do
  local x=(i-1)*25+2
  for s in all(sels) do
   if s.on and s.i==i then rectfill(x-1,30,x+24,55,7) end
  end
  local n=chars[i].name
  if n=="cheetah" then sspr(8,1,26,16,x,36,24,15,true)
  elseif n=="dragon" then sspr(0,32,16,12,x+4,38)
  elseif n=="unicorn" then sspr(16,32,16,16,x+4,36)
  elseif n=="snail" then sspr(32,32,12,8,x+6,44)
  else sspr(64,32,9,11,x+8,40) end
  -- p1 gets the outer frame, p2
  -- the inner one
  for k=1,2 do
   local s=sels[k]
   if s.on and s.i==i then
    local d=k*2-3
    rect(x-1+d,30+d,x+24-d,55-d,pcol[k])
    rect(x+d,31+d,x+23-d,54-d,pcol[k])
   end
  end
 end
 for k=1,2 do
  local s,y=sels[k],31+k*29
  rectfill(0,y-1,127,y+5,1)
  if s.on then
   local c=chars[s.i]
   cprint("p"..k.." "..c.name..(s.rdy and " - ready!" or ""),y,pcol[k])
   for i=1,3 do cprint(c.info[i],y+2+i*6,1) end
  else
   cprint("p"..k,y,pcol[k])
   cprint("press z to join",y+12,1)
  end
 end
 cprint("left/right pick  z: ready",121,7)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000a0aa0a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000a0a0aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000aaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000aaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaa0aaaaa0aaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000a0aaa0aaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000a00a0a0a0aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aa0aaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000a0a00000a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000a0a00000a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000a0a00000a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000a0a00000a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000a0a00000a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000a0a00000a0a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000a0aa0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000a0a0aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000aaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000aaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000aaa0aaaaa0aaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000a0aaa0aaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaaa00a0a0a0aaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaaaa0aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000003030000000000000000a00099990001011fff00000099990000000005550000000000022222200222222007000000000000700011111111000000
00000000003bbbb00000000000000a00094444900f0f00f1fff009444490000000555550000000002222222222222222077002222220077001c77cc7cc100000
0300000000bb1bbb0000000000e77000949999490fff1fffffff9499994900000055575000000000271227122712271200772222222277001cccccccccc10000
3b3000000bbbbbb0000000000e777700949449490f1f0000ffff9494494900000055559900000000222222222222222200222222222222001dcc7cccccd10000
3bb30000bbb0000000000000e771777094994949fff000999fff9499494900000557775500000000287878722878787202222aa22aa2222001dccccccd100000
03bb30bbbbb0000000000000c77777770944449ffff0094449ff0944449000000577777500000000228888222288882202222a122a122220001dccccd1000000
003bbbbbbbbb00000000000c07777000fffffffffff0949994ff00444400000055777775500000002222222222222222d22222222222222d0001dccd10000000
000bbbaaaabb0000000000b0077700000fffffffff00949444ff00000000000055777775500000002020020202022020dd222888888222dd00001dd100000000
b00bbbaaaabb000000000a7777777700000000000000949494ff00000000000005777775000000002000000200222200ddd2878787872ddd0000011000000000
bb0bbbbbbbbb0000e900777777777000000000000000949994ff00000000000000777770000000002202202202a22a20dd022888888220dd0000000000000000
0bbb0bb000bb00008a07777777777000000000000000094449ff00000000000000990990000000002222222222222222d00222222222200d0000000000000000
00003300003300000e97777777777000000000000000009990f0000000000000000000000000000002a22a202022220200022222222220000000000000000000
00000000000000000007707000770700000000000000000000000000000000000000555550000000002222002002200200002222222200000000000000000000
00000000000000000007007000700700000000000000000000000000000000000055555557500000000220000000000000002002200200000000000000000000
00000000000000000007007000700700000000000000000000000000000000000557777775990000000000000000000000022002200220000000000000000000
0000000000000000000d00d000d00d00000000000000000000000000000000005577777777550000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000555555555500000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000009900000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbb444444446666566677777777111111115888000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb3bbbb344454444666656667c777c77111111115888800000000000000000000000000000000000000000000000000000000000000000000000000000000000
34b34b444444449455555555c7776c7711d111115888880000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444494444446666666577777777111111115888800000000000000000000000000000000000000000000000000000000000000000000000000000000000
444544444444445466666665777c777711111d115888000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444944445444445555555577c7777c111111115000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4944444444444944666656667777777c1d1111115000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444454444444446666566666666666111111115000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccc77c7c7c777c777c777ccccc777c77cc777c777c777c7cccc77ccccc777ccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc7ccc7c7c7c7c7ccc7c7ccccc7c7c7c7cc7cc777c7c7c7ccc7ccccccccc7ccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc777c7c7c777c77cc77cccccc777c7c7cc7cc7c7c777c7ccc777ccccc777ccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccc7c7c7c7ccc7ccc7c7ccccc7c7c7c7cc7cc7c7c7c7c7ccccc7ccccc7ccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc77ccc77c7ccc777c7c7ccccc7c7c7c7c777c7c7c7c7c777c77cccccc777ccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccc111c111cc11c111ccccc111c1c1c111ccccc111cc11cc11cc11ccccc111cc11ccccc111c1c1c111ccccccccccccccccccccccccc
cccccccccccccccccccccccc1c1c1c1c1ccc1cccccccc1cc1c1c1ccccccc1c1c1c1c1ccc1cccccccc1cc1c1cccccc1cc1c1c1ccccccccccccccccccccccccccc
cccccccccccccccccccccccc11cc111c1ccc11ccccccc1cc111c11cccccc11cc1c1c111c111cccccc1cc1c1cccccc1cc111c11cccccccccccccccccccccccccc
cccccccccccccccccccccccc1c1c1c1c1ccc1cccccccc1cc1c1c1ccccccc1c1c1c1ccc1ccc1cccccc1cc1c1cccccc1cc1c1c1ccccccccccccccccccccccccccc
cccccccccccccccccccccccc1c1c1c1cc11c111cccccc1cc1c1c111ccccc111c11cc11cc11ccccccc1cc11ccccccc1cc1c1c111ccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccc1c1c1ccc111c111c111ccccc11cc111c111c111cc11c11cc11ccc1cccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccc1c1c1cccc1cc1c1c1c1ccccc1c1cc1cc1c1c111c1c1c1c1c1c1cc1cccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccc1c1c1cccc1cc11cc111ccccc1c1cc1cc111c1c1c1c1c1c1c1c1cc1cccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccc1c1c1cccc1cc1c1c1c1ccccc1c1cc1cc1c1c1c1c1c1c1c1c1c1ccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccc11c111cc1cc1c1c1c1ccccc111c111c1c1c1c1c11cc1c1c111cc1cccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aa777777777777777777777777aacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aa777777777777777777777777aacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aa777777777777777777777777aacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aa777777777777777777777777aacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aa777777777777777777777777aacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aa7777777777777777a7a7a777aaccccccccccccccccccccccccccccccccccccccccccaccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aa7777777777777777aaaaa777aacccccccccccccccccccccccccccccccccccccccccacccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aa7777777777777777aaa7a777aacccccccccccccc3c3ccccccccccccccccccccce77ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aa777777777777777aaaaaaa77aaccccccccccccc3bbbbccccccccccccccccccce7777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aa7777777777777777aaaaa777aacccc3ccccccccbb1bbbccccccccccccccccce771777cccccccccccccccccccccccccccccccccccccccccc555cccccccccccc
aa77777777777777777aaa7777aaccc3b3ccccccbbbbbbccccccccccccccccccc7777777cccccccccccccccccccccccccccccccccccccccc55555ccccccccccc
aa7aaaaaaaaa7aaaaa7aa77777aaccc3bb3ccccbbbccccccccccccccccccccccc7777ccccccccccccccccccccccccccccccccccccccccccc55575ccccccccccc
aa777777777aaaaa7aaaa77777aacccc3bb3cbbbbbccccccccccccccccccccbcc777cccccccccccccccccccccccccccccccccccccccccccc555599cccccccccc
aa777777777aaaaaaaa7a77777aaccccc3bbbbbbbbbcccccccccccccccccca77777777ccccccccccccccc9999ccc1c1cccccccccccccccc5577755cccccccccc
aa777777777a7a77777aa77777aaccccccbbbaaaabbccccccccccccce9cc777777777ccccccccccccccc944449ccfcfcccccccccccccccc5777775cccccccccc
aa777777777a7a77777aa77777aacccbccbbbaaaabbccccccccccccc8ac7777777777cccccccccccccc94999949cfffccccccccccccccc557777755ccccccccc
aa777777777a7a77777aa77777aacccbbcbbbbbbbbbcccccccccccccce97777777777cccccccccccccc94944949cf1fccccccccccccccc557777755ccccccccc
aa777777777a7a77777aa77777aaccccbbbcbbcccbbcccccccccccccccc77c7ccc77c7ccccccccccccc94994949fffccccccccccccccccc5777775cccccccccc
aa777777777a7a77777aa77777aaccccccc33cccc33cccccccccccccccc7cc7ccc7cc7cccccccccccccc944449ffffcccccccccccccccccc77777ccccccccccc
aa777777777a7a77777aa77777aaccccccccccccccccccccccccccccccc7cc7ccc7cc7cccccccccccccfffffffffffcccccccccccccccccc99c99ccccccccccc
aa777777777777777777777777aacccccccccccccccccccccccccccccccdccdcccdccdccccccccccccccfffffffffccccccccccccccccccccccccccccccccccc
aa777777777777777777777777aacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aa777777777777777777777777aacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aa777777777777777777777777aacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
aaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111aaa1aa1111111aa1a1a1aaa1aaa1aaa1aaa1a1a111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111a1a11a111111a111a1a1a111a1111a11a1a1a1a111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111aaa11a111111a111aaa1aa11aa111a11aaa1aaa111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111a1111a111111a111a1a1a111a1111a11a1a1a1a111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111a111aaa111111aa1a1a1aaa1aaa11a11a1a1a1a111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccc111c111cc11c111c111cc11c111ccccc111c1c1c11cc11cc111c111ccccc111c11cc11cccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccc1ccc1c1c1cccc1cc1ccc1cccc1cccccc1c1c1c1c1c1c1c1c1ccc1c1ccccc1c1c1c1c1c1ccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccc11cc111c111cc1cc11cc111cc1cccccc11cc1c1c1c1c1c1c11cc11cccccc111c1c1c1c1ccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccc1ccc1c1ccc1cc1cc1ccccc1cc1cccccc1c1c1c1c1c1c1c1c1ccc1c1ccccc1c1c1c1c1c1ccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccc1ccc1c1c11ccc1cc111c11ccc1cccccc1c1cc11c1c1c1c1c111c1c1ccccc1c1c1c1c111ccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc1c1c111cc11c1c1c111cc11c111ccccc111c1c1c111c111c111c111cc1cccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc1c1cc1cc1ccc1c1c1ccc1cccc1ccccccc1cc1c1c111c1c1c1ccc1c1cc1cccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc111cc1cc1ccc111c11cc111cc1ccccccc1cc1c1c1c1c111c11cc11ccc1cccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc1c1cc1cc1c1c1c1c1ccccc1cc1ccccccc1cc1c1c1c1c1ccc1ccc1c1ccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc1c1c111c111c1c1c111c11ccc1cccccc11ccc11c1c1c1ccc111c1c1cc1cccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccc1c1ccccccccc1c1cc11c1ccc11cccccc111cc11cccccc11c111c111c111c11cc111ccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccc1c1cc1cccccc1c1c1c1c1ccc1c1cccccc1cc1c1ccccc1ccc1c1c1c1cc1cc1c1cc1cccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccc1cccccccccc111c1c1c1ccc1c1cccccc1cc1c1ccccc111c111c11ccc1cc1c1cc1cccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccc1c1cc1cccccc1c1c1c1c1ccc1c1cccccc1cc1c1ccccccc1c1ccc1c1cc1cc1c1cc1cccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccc1c1ccccccccc1c1c11cc111c111cccccc1cc11cccccc11cc1ccc1c1c111c1c1cc1cccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111eee1eee1111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111e1e111e1111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111eee1eee1111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111e111e111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111e111eee1111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc111c111c111cc11cc11ccccc111ccccc111cc11ccccc111cc11c111c11cccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc1c1c1c1c1ccc1ccc1ccccccccc1cccccc1cc1c1cccccc1cc1c1cc1cc1c1ccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc111c11cc11cc111c111cccccc1ccccccc1cc1c1cccccc1cc1c1cc1cc1c1ccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc1ccc1c1c1ccccc1ccc1ccccc1cccccccc1cc1c1cccccc1cc1c1cc1cc1c1ccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc1ccc1c1c111c11cc11cccccc111cccccc1cc11cccccc11cc11cc111c1c1ccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc7ccc777c777c777ccc7c777c777cc77c7c7c777ccccc777c777cc77c7c7ccccccccc777ccccccccc777c777c777c77cc7c7ccccccccccccccc
cccccccccccccc7ccc7ccc7cccc7ccc7cc7c7cc7cc7ccc7c7cc7cccccc7c7cc7cc7ccc7c7ccccccccccc7cc7cccccc7c7c7ccc7c7c7c7c7c7ccccccccccccccc
cccccccccccccc7ccc77cc77ccc7ccc7cc77ccc7cc7ccc777cc7cccccc777cc7cc7ccc77ccccccccccc7cccccccccc77cc77cc777c7c7c777ccccccccccccccc
cccccccccccccc7ccc7ccc7cccc7ccc7cc7c7cc7cc7c7c7c7cc7cccccc7cccc7cc7ccc7c7ccccccccc7cccc7cccccc7c7c7ccc7c7c7c7ccc7ccccccccccccccc
cccccccccccccc777c777c7cccc7cc7ccc7c7c777c777c7c7cc7cccccc7ccc777cc77c7c7ccccccccc777ccccccccc7c7c777c7c7c777c777ccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__sfx__
00040000183501c350203402433028320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000c6700e6600c6700f6600d6500c6400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000024050280502b0503005034040370300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001f2401a24016230122200f210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600001825014250102400c24008230042200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000181401c140181300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000245502b550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a00000c2400b2400a2400924008230072300622000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005000024550285502b550305502b550305503455037540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000306402c640286302462020610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
