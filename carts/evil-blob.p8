pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- the evil blob
-- game idea and art by abel
-- code by dad and claude

pnames={"head","arms","body","legs"}
-- abel's robot parts: sx,sy,w,h
pspr={{35,6,6,5},{59,7,6,3},{84,7,6,6},{109,10,4,4}}
maxlevel=8
-- the land changes every 2 levels
lands={
 {n="the woods",g=3,d=11},
 {n="the desert",g=15,d=9},
 {n="the snow",g=7,d=6},
 {n="blob land",g=2,d=14},
}

function _init()
 state="title" t=0
end

function new_game()
 lives=3 gold=0 level=1
 start_level()
end

function say(s,n)
 msg=s msgt=n or 90
end

function overlap(x,y,w,h,o,m)
 return x<o.x+o.w+m and x+w>o.x-m
  and y<o.y+o.h+m and y+h>o.y-m
end

-- put a thing somewhere free
function place(o)
 for try=1,300 do
  o.x=flr(14+rnd(ww-28-o.w))
  o.y=flr(26+rnd(wh-40-o.h))
  local ok=not overlap(ww/2-24,wh/2-24,48,48,o,0)
  for s in all(solids) do
   if (overlap(o.x,o.y,o.w,o.h,s,11)) ok=false
  end
  if ok then add(solids,o) return o end
 end
end

function start_level()
 ww=min(256+level*64,512) wh=ww
 land=lands[(level+1)\2]
 px=ww/2-3 py=wh/2-6
 pdir=1 fdx=1 fdy=0 pwalk=0
 inv=0 punch=0
 solids={} boxes={} items={}
 fx={} balls={} decor={}
 got={} nparts=0 bot=nil
 msg="" msgt=0
 -- what is in the boxes
 local nb=min(10+level*4,26)
 local c={1,2,3,4,"heart","diamond"}
 for i=7,nb do
  add(c,i%5<3 and "gold" or "none")
 end
 for i=#c,2,-1 do
  local j=flr(rnd(i))+1
  c[i],c[j]=c[j],c[i]
 end
 for i=1,nb do
  local b=place{k="box",w=10,h=8,hp=2,shake=0}
  if b then b.inside=c[i] add(boxes,b) end
 end
 for i=1,min(3+level,8) do place{k="pond",w=26,h=14} end
 for i=1,min(6+level*3,24) do place{k="tree",w=6,h=4} end
 for i=1,min(5+level*2,16) do place{k="rock",w=10,h=6} end
 for i=1,ww/3 do
  add(decor,{x=rnd(ww),y=rnd(wh),c=rnd({land.d,land.d,land.d,10,14})})
 end
 -- the evil blob starts far away
 blob=new_blob(.65+level*.35,6+level*2,110)
 -- baby blobs from level 4
 minis={}
 for i=1,level-3 do
  local m=new_blob(.5,1,70)
  m.mini=true
  add(minis,m)
 end
 say("level "..level..": "..land.n,120)
end

function new_blob(s,hp,far)
 local b={s=s,hp=hp,maxhp=hp,flash=0,wt=0}
 repeat
  b.x=20+rnd(ww-40)
  b.y=30+rnd(wh-50)
 until dist(b.x,b.y,px,py)>far
 b.tx=b.x b.ty=b.y
 return b
end

function dist(x1,y1,x2,y2)
 local dx,dy=(x1-x2)/16,(y1-y2)/16
 return sqrt(dx*dx+dy*dy)*16
end

function hit(x,y,w,h)
 if (x<2 or y<12 or x+w>ww-2 or y+h>wh-2) return true
 for s in all(solids) do
  if (overlap(x,y,w,h,s,0)) return true
 end
 return false
end

function puff(x,y,c,n)
 for i=1,n do
  add(fx,{x=x,y=y,dx=rnd(3)-1.5,dy=rnd(3)-2,c=c,l=10+rnd(10)})
 end
end

function _update()
 t+=1
 if state=="title" then
  if (btnp(4) or btnp(5)) new_game() state="play"
 elseif state=="play" then
  upd_play()
 elseif state=="clear" then
  upd_fx()
  if t>45 and (btnp(4) or btnp(5)) then
   level+=1
   start_level() state="play"
  end
 else
  upd_fx()
  if (t>45 and (btnp(4) or btnp(5))) state="title" t=0
 end
end

function upd_fx()
 for p in all(fx) do
  p.x+=p.dx p.y+=p.dy p.dy+=.15 p.l-=1
  if (p.l<0) del(fx,p)
 end
end

function upd_play()
 -- walk
 local dx,dy=0,0
 if (btn(0)) dx=-1
 if (btn(1)) dx=1
 if (btn(2)) dy=-1
 if (btn(3)) dy=1
 if dx!=0 or dy!=0 then
  fdx=dx fdy=dy pwalk+=1
  if (dx!=0) pdir=dx
  local s=1.2
  if (dx!=0 and dy!=0) s=.85
  if (not hit(px+dx*s,py+9,6,4)) px+=dx*s
  if (not hit(px,py+9+dy*s,6,4)) py+=dy*s
 end
 local cx,cy=px+3,py+8
 if (inv>0) inv-=1
 if (punch>0) punch-=1
 if (msgt>0) msgt-=1

 -- smash a box
 if btnp(5) then
  punch=6
  local best,bd=nil,15
  for b in all(boxes) do
   local d=dist(b.x+5+fdx*-3,b.y+3+fdy*-3,cx,cy)
   if (d<bd) best=b bd=d
  end
  if best then
   best.hp-=1 best.shake=6
   puff(best.x+5,best.y+2,4,4)
   if best.hp<=0 then
    open_box(best)
   else
    sfx(0)
   end
  else
   sfx(0)
  end
 end
 for b in all(boxes) do
  if (b.shake>0) b.shake-=1
 end

 -- pick things up
 for i in all(items) do
  i.t+=1
  if i.t>12 and dist(i.x,i.y,cx,cy)<9 then
   del(items,i)
   if i.k=="gold" then
    gold+=1 sfx(2)
   elseif i.k=="part" then
    got[i.id]=true nparts+=1 sfx(3)
    say("you found the robot "..pnames[i.id].."!")
   else
    lives+=1 sfx(4)
    say("extra life!")
   end
  end
 end

 -- build the bot
 if nparts==4 and not bot then
  say("press \142 to build the bot!",2)
  if btnp(4) then
   bot={x=cx,y=py+12,cool=30,d=1}
   puff(cx,cy,7,16) sfx(8)
   say("your bot shoots fire balls!",120)
  end
 end

 upd_blob(cx,cy)
 if (state!="play") return
 upd_bot(cx,cy)
 upd_fx()
end

function open_box(b)
 del(boxes,b) del(solids,b)
 puff(b.x+5,b.y+2,4,10)
 puff(b.x+5,b.y+2,5,4)
 sfx(1)
 local k=b.inside
 if k=="none" then
  say("empty!",30)
 else
  local i={x=b.x+5,y=b.y+4,t=0,k=k}
  if (type(k)=="number") i.k="part" i.id=k
  add(items,i)
 end
end

function upd_blob(cx,cy)
 upd_one(blob,cx,cy)
 for m in all(minis) do
  if (state=="play") upd_one(m,cx,cy)
 end
end

function upd_one(b,cx,cy)
 if (b.flash>0) b.flash-=1
 local d=dist(b.x,b.y,cx,cy)
 local sp=.25
 if b.mini then
  if (d<50) b.tx=cx b.ty=cy sp=.4
 elseif bot or d<min(56+level*8,100) then
  -- chase the player
  b.tx=cx b.ty=cy
  sp=min(.33+level*.07,.8)
  if (bot) sp+=.1
 end
 if sp==.25 then
  b.wt-=1
  if b.wt<=0 or dist(b.x,b.y,b.tx,b.ty)<4 then
   b.tx=20+rnd(ww-40)
   b.ty=30+rnd(wh-50)
   b.wt=200
  end
 end
 local td=dist(b.x,b.y,b.tx,b.ty)
 if td>1 then
  b.x+=(b.tx-b.x)/td*sp
  b.y+=(b.ty-b.y)/td*sp
 end
 -- you can not touch him
 if inv==0 and abs(cx-b.x)<6*b.s+2 and abs(cy-b.y)<5*b.s+5 then
  lives-=1 inv=90 sfx(5)
  puff(cx,cy,8,8)
  if lives<=0 then
   state="over" t=0
  else
   say(b.mini and "a baby blob got you!" or "the evil blob got you!")
  end
 end
end

function upd_bot(cx,cy)
 if (not bot) return
 local o,b=bot,blob
 -- aim at the closest blob
 local bd=dist(o.x,o.y-9,b.x,b.y)
 for m in all(minis) do
  local d=dist(o.x,o.y-9,m.x,m.y)
  if (d<bd and d<84) b=m bd=d
 end
 -- follow the player
 local gx,gy=cx-pdir*10,py+12
 local d=dist(o.x,o.y,gx,gy)
 if d>3 then
  local sp=min(1.3,d/4)
  o.x+=(gx-o.x)/d*sp
  o.y+=(gy-o.y)/d*sp
 end
 if (b.x<o.x) o.d=-1 else o.d=1
 -- shoot fire balls
 o.cool-=1
if o.cool<=0 and bd<84 then
  o.cool=40
  add(balls,{x=o.x,y=o.y-9,dx=(b.x-o.x)/bd*2.2,dy=(b.y-o.y+9)/bd*2.2,l=50})
  sfx(6)
 end
 for f in all(balls) do
  f.x+=f.dx f.y+=f.dy f.l-=1
  if (f.l%2==0) add(fx,{x=f.x,y=f.y,dx=0,dy=0,c=9,l=5})
  local b=nil
  if (near(f,blob)) b=blob
  for m in all(minis) do
   if (near(f,m)) b=m
  end
  if b then
   del(balls,f)
   b.hp-=1 b.flash=6
   b.x+=f.dx*2 b.y+=f.dy*2
   puff(f.x,f.y,10,6) sfx(7)
   if b.hp<=0 and b.mini then
    del(minis,b)
    puff(b.x,b.y,11,12)
   elseif b.hp<=0 then
    for i=1,5 do
     puff(b.x+rnd(16)-8,b.y+rnd(12)-6,rnd({11,3,10}),8)
    end
    sfx(9)
    balls={}
    t=0
    if (level>=maxlevel) state="win" else state="clear"
    return
   end
  elseif f.l<0 then
   del(balls,f)
  end
 end
end

function near(f,b)
 return abs(f.x-b.x)<7*b.s+1 and abs(f.y-b.y)<6*b.s+1
end

-- drawing ------------------

function draw_part(id,x,y)
 local p=pspr[id]
 sspr(p[1],p[2],p[3],p[4],x,y)
end

-- the bot is made of abel's parts
function draw_bot(x,y,fl)
 sspr(35,6,6,5,x-3,y-18,6,5,fl)
 sspr(59,7,6,3,x-3,y-13)
 sspr(84,7,6,6,x-3,y-10)
 sspr(109,10,4,4,x-2,y-4)
end

function draw_guy(x,y,fl)
 sspr(11,3,6,13,x,y,6,13,fl)
end

function draw_blob(x,y,s,fl)
 local w=16*s*(1+sin(t/40)*.06)
 local h=14*s*(1-sin(t/40)*.06)
 if fl then
  for c=1,15 do pal(c,7) end
 end
 sspr(32,18,16,14,x-w/2,y+7*s-h,w,h)
 pal()
end

function draw_box(x,y)
 sspr(12,23,5,5,x,y,10,10)
end

function draw_gold(x,y)
 circfill(x,y,3,9)
 circfill(x,y,2,10)
 pset(x-1,y-1,7)
end

function draw_diamond(x,y)
 for i=0,3 do
  line(x-1-i,y-3+i,x+1+i,y-3+i,12)
  line(x-4+i,y+1+i,x+4-i,y+1+i,i<2 and 12 or 13)
 end
 line(x-1,y-2,x-2,y-1,7)
end

function draw_fire(x,y)
 circfill(x,y,3,8)
 circfill(x,y,2,9)
 circfill(x,y,1,10)
end

function draw_item(i)
 local x,y=i.x,i.y-2+sin(t/30)*1.5
 if (i.t<12) y-=sin(i.t/24)*8
 if i.k=="gold" then
  draw_gold(x,y)
 elseif i.k=="heart" then
  print("\135",x-3,y-2,8)
 elseif i.k=="diamond" then
  draw_diamond(x,y)
 else
  local p=pspr[i.id]
  circ(x,y,5+t%20/5,7)
  draw_part(i.id,x-p[3]/2,y-p[4]/2)
 end
end

function draw_solid(s)
 local x,y=s.x,s.y
 if s.k=="box" then
  if (s.shake>0) x+=s.shake%2*2-1
  draw_box(x,y-2)
 elseif s.k=="tree" then
  rectfill(x+1,y-6,x+4,y+3,4)
  circfill(x+3,y-11,7,9)
  circfill(x+1,y-13,3,10)
  circfill(x+6,y-9,2,4)
 elseif s.k=="rock" then
  ovalfill(x,y-3,x+9,y+5,5)
  ovalfill(x+1,y-3,x+8,y+3,6)
  pset(x+3,y-1,7)
 end
end

function draw_world()
 local cx=mid(0,px-61,ww-128)
 local cy=mid(0,py-58,wh-128)
 camx=cx camy=cy
 cls(land.g)
 camera(cx,cy)
 for d in all(decor) do
  pset(d.x,d.y,d.c)
  if (d.c==land.d) pset(d.x+1,d.y-1,d.c)
 end
 for s in all(solids) do
  if s.k=="pond" then
   ovalfill(s.x,s.y,s.x+s.w-1,s.y+s.h-1,1)
   ovalfill(s.x+1,s.y+1,s.x+s.w-2,s.y+s.h-3,12)
   line(s.x+6,s.y+4,s.x+10,s.y+4,7)
  end
 end
 -- sort by feet so things overlap right
 local l={}
 local function put(y,f,a,b,c,d)
  if (y<cy-8 or y>cy+170) return
  local o={y=y,f=f,a=a,b=b,c=c,d=d}
  local i=#l
  while i>0 and l[i].y>y do i-=1 end
  add(l,o,i+1)
 end
 for s in all(solids) do
  if (s.k!="pond") put(s.y+s.h,draw_solid,s)
 end
 for i in all(items) do put(i.y+3,draw_item,i) end
 if state!="win" and state!="clear" then
  put(blob.y+7*blob.s,draw_blob,blob.x,blob.y,blob.s,blob.flash>0)
 end
 for m in all(minis) do
  put(m.y+4,draw_blob,m.x,m.y,m.s,m.flash>0)
 end
 if bot then
  put(bot.y,draw_bot,bot.x,bot.y+(t%16<8 and 0 or -1),bot.d<0)
 end
 if state!="over" and inv%4<2 then
  local bob=0
  if (pwalk%8>=4) bob=-1
  put(py+13,draw_guy,px,py+bob,pdir<0)
 end
 for o in all(l) do o.f(o.a,o.b,o.c,o.d) end
 -- punch
 if punch>0 then
  local hx,hy=px+3+fdx*8,py+8+fdy*8
  circ(hx,hy,2+(6-punch)/2,land.g==7 and 5 or 7)
 end
 for f in all(balls) do draw_fire(f.x,f.y) end
 for p in all(fx) do pset(p.x,p.y,p.c) end
 -- blob health
 if bot and state=="play" then
  local b=blob
  local w=b.maxhp*2
  local y=b.y-8*b.s-4
  rectfill(b.x-w/2-1,y-1,b.x+w/2,y+2,1)
  rectfill(b.x-w/2,y,b.x-w/2+b.hp*2-1,y+1,8)
 end
 camera()
end

-- arrow at the screen edge
function hint(x,y,c)
 local sx,sy=x-camx,y-camy
 if (sx>=0 and sx<128 and sy>=10 and sy<128) return
 sx=mid(3,sx,124) sy=mid(13,sy,124)
 circfill(sx,sy,2,c)
 circ(sx,sy,2+t%30/10,7)
end

function draw_hud()
 rectfill(0,0,127,9,1)
 print("\135",2,2,8)
 print(lives,10,2,7)
 draw_gold(25,4)
 print(gold,31,2,7)
 print("level "..level,48,2,6)
 for i=1,4 do
  local p=pspr[i]
  local x=84+i*9
  if (not got[i]) for c=1,15 do pal(c,5) end
  draw_part(i,x-p[3]/2,5-p[4]/2)
  pal()
 end
 -- help find the last boxes
 if nparts<4 then
  local best,bd=nil,9999
  for b in all(boxes) do
   local d=dist(b.x,b.y,px,py)
   if (d<bd) best=b bd=d
  end
  if (best) hint(best.x+5,best.y+4,4)
 end
 if (bot) hint(blob.x,blob.y,11)
 if msgt>0 then
  local w=tw(msg)
  rectfill(62-w/2,115,65+w/2,125,1)
  print(msg,64-w/2,118,7)
 end
end

function tw(s)
 local w=0
 for i=1,#s do
  w+=ord(s,i)>=128 and 8 or 4
 end
 return w
end

function cprint(s,y,c)
 print(s,64-tw(s)/2,y,c)
end

function _draw()
 if state=="title" then
  cls(3)
  rectfill(0,8,127,30,1)
  cprint("the evil blob",13,11)
  cprint("a game by abel",22,7)
  draw_blob(64,52,1.5,false)
  draw_guy(20,48)
  draw_box(31,52)
  draw_bot(104,62)
  draw_fire(92,50)
  cprint("smash boxes to find gold",72,7)
  cprint("and the 4 robot parts.",79,7)
  cprint("build the bot. it shoots",86,7)
  cprint("fire balls at the evil blob!",93,7)
  cprint("do not touch the blob!",100,8)
  cprint("arrows walk \151 smash \142 build",111,10)
  if (t%30<20) cprint("press \151 to start",120,7)
  return
 end
 draw_world()
 draw_hud()
 if state=="over" then
  rectfill(14,44,113,84,1)
  cprint("the evil blob got you!",50,8)
  cprint("gold: "..gold,60,10)
  if (t>45) cprint("press \151 to try again",74,7)
 elseif state=="clear" then
  rectfill(10,44,117,84,1)
  cprint("you beat the blob!",50,11)
  cprint("but a bigger blob is coming",60,7)
  if (t>45) cprint("press \151 for level "..(level+1),74,10)
 elseif state=="win" then
  rectfill(10,40,117,88,1)
  cprint("you win!",46,10)
  cprint("the evil blob is destroyed",56,11)
  cprint("gold: "..gold,66,10)
  if (t>45) cprint("press \151 to play again",78,7)
 end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000099990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000099990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000044440000000000000000000888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000affa0000000000000000000cccccc00000000000000000065656500000000000000000008c8c8c00000000000000000000000000000000000000
000000000000f55f0000000000000000000c0c0cc0000000000000000000000000000000000000000000cccccc00000000000000000000000000000000000000
00000000000c8558c000000000000000000cccccc0000000000000000006565650000000000000000000cccccc00000000000000000000000000000000000000
00000000000c8888c000000000000000000cccccc0000000000000000000000000000000000000000000cccccc00000000000000000006006000000000000000
00000000000f8888f0000000000000000000000000000000000000000000000000000000000000000000cccccc00000000000000000006006000000000000000
000000000000888800000000000000000000000000000000000000000000000000000000000000000000c8c8c800000000000000000006006000000000000000
000000000000c00c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006006000000000000000
00000000000040040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000440044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000bbbb00bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000bbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000bb555bbbb555bb000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000bb555bbbb555bb000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000b3bbbbb3bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000455450000000000000000bbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000444440000000000000000bbbbbbbbb3bbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000444440000000000000000b3b5a5a5abbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000455450000000000000000bbba5a5a5b3bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000454440000000000000000bbbbbbbbbbbbb3000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000bb3bb3bbb3bbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000003bbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbbbbbbb3bbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbbbbbbbbbbbbbb00000000000000000000005000000000000000000000000000000000000000000000000000000000
__sfx__
000300000c65008630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000146600e6600a6500664003620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000240502b050300300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000185501c5501f5502455024530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001f05024050280502b05030050300200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000014260102600c2500824004230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002844024440204301c42000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000a660123500a6400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700000c150131501815013150181501f1502415024130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008000018550185501f5502455028550245502b55030550305300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
