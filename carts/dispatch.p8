pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- dispatch
-- a firefighting penguin in
-- ruraltown usa. take the call,
-- pick an apparatus, drive to the
-- scene without crashing, size
-- it up, pick your hose and put
-- the fire out.

function _init()
 apps={
  {n="engine 1",d="1000 gal, all the hoses",w=1000,h=20,pc=6,ls={1,2,3}},
  {n="engine 2",d="2000 gal, all the hoses",w=2000,h=22,pc=13,ls={1,2,3}},
  {n="rescue 1",d="tools, but no water",w=0,h=18,pc=7,ls={}},
  {n="brush 1",d="250 gal, goes off road",w=250,h=14,pc=10,ls={4,5},off=true},
  {n="brush 2",d="150 gal, small + quick",w=150,h=11,pc=9,ls={4,5},off=true},
 }
 lines={
  {n="cross-lay",flow=.8,dmg=.12,reach=30,hose=56,sp=1,dep=2},
  {n="bumper line",flow=.8,dmg=.12,reach=30,hose=34,sp=1,dep=0},
  {n="2.5in off the bed",flow=1.5,dmg=.3,reach=44,hose=90,sp=.5,dep=5,big=true},
  {n="booster reel",flow=.3,dmg=.08,reach=24,hose=48,sp=1.2,dep=0},
  {n="forestry line",flow=.35,dmg=.08,reach=24,hose=100,sp=1,dep=3},
 }
 calls={
  {t="brush fire",a="wendell rd",d="1/4 acre of grass burning",
   su="small grass fire by the road",
   n=3,kind="brush",size=1,dist=500,lim=.6},
  {t="car fire",a="route 202",d="engine compartment on fire",
   su="car on the shoulder, hood shut",
   n=2,kind="car",size=1,dist=650,lim=.3},
  {t="brush fire",a="montague rd",d="2 acres, way off the road",
   su="fire is far back in the field",
   n=4,kind="brush",far=true,size=3,dist=800,lim=.6},
  {t="kitchen fire",a="leverett rd",d="smoke from a 2 story house",
   su="smoke showing, fire in 1 room",
   n=4,kind="house",size=2,dist=900,lim=.5},
  {t="barn fire",a="pratt corner rd",d="hay barn, flames showing",
   su="hay is burning, grass is dry",
   n=5,kind="barn",size=3,dist=1000,lim=.55},
  {t="brush fire",a="lake wyola",d="5 acres and a strong wind",
   su="wind is pushing it east",
   n=5,kind="brush",far=true,wind=true,size=4,dist=1100,lim=.65},
  {t="structure fire",a="cooleyville rd",d="house, fire through the roof",
   su="heavy fire, a lot of house left",
   n=6,kind="house",size=6,dist=1200,lim=.65},
 }
 -- fuel: {how long it burns, how
 -- much water to knock it down}
 -- 1 grass 2 trees 3 building
 -- 4 hay/engine (shielded) 5 car
 -- and how easily it spreads}
 tp={{5,.6,.22},{10,2,.2},{20,4,.06},{30,4,.06},{30,3,.1}}
 helpers={
  {n="leverett tanker",t=1},
  {n="amherst ladder",t=2},
  {n="new salem tanker",t=1},
  {n="wendell tanker",t=1},
 }
 level=1
 saved={}
 state="title"
 msg="" msgt=0
end

function say(s,n)
 msg=s msgt=n or 90
end

function start_call()
 c=calls[level]
 state="tones"
 onscene=false
 sel=1
 sfx(0)
end

-->8
-- driving

function rx(w)
 return 64+sin(w/900)*16+sin(w/400)*6
end

function start_drive()
 ap=apps[sel]
 state="drive"
 dw=0 dsp=1.5 dt=0
 tx=rx(0)+9
 obs={}
 local w=160
 while w<c.dist-80 do
  local o={w=w,k=1,o=9,col=rnd({12,10,7,14,9})}
  local r=rnd()
  if r<.3 then o.k=2 o.o=-34
  elseif r<.65 then o.o=-9 end
  add(obs,o)
  w+=max(60,100+rnd(70)-level*6)
 end
 sfx(1,3)
end

function update_drive()
 dt+=1
 if btn(0) then tx-=1.5 end
 if btn(1) then tx+=1.5 end
 if btn(2) then dsp=min(3,dsp+.05) end
 if btn(3) then dsp=max(1,dsp-.05) end
 dw+=dsp
 local half=ap.h*.3
 if abs(tx-rx(dw))+half>27 then
  crash("you drove off the road")
  return
 end
 for o in all(obs) do
  local r=o.w-dw
  if o.k==2 then
   -- a deer steps out: slow down
   -- and it gets across
   if r<110 and o.o<40 then o.o+=.6 end
  else
   -- cars pull over for the siren
   if o.o<0 then o.w-=.8 else o.w+=.4 end
   if r<70 and abs(o.o)<21 then o.o+=sgn(o.o)*.3 end
  end
  r=o.w-dw
  if r>-ap.h and r<(o.k==2 and 8 or 12)
   and abs(rx(o.w)+o.o-tx)<half+3 then
   crash(o.k==2 and "you hit a deer" or "you hit a car")
   return
  end
 end
 if dw>=c.dist then
  sfx(-1,3)
  start_sizeup()
 end
end

function crash(s)
 sfx(-1,3)
 sfx(5)
 state="fail"
 why=s
end

-->8
-- the scene

function start_sizeup()
 state="size"
 onscene=true
 row=1
 li=1
 ls={}
 for q in all(ap.ls) do add(ls,q) end
 hl=lines[ls[1]]
 pierce=false
 wantvent=false
 vented=false
 ladder=false
 help={}
 water=ap.w
 msgt=0
 build()
end

function build()
 srand(level*7+3)
 k={} fl={} fr={} bt={} wet={}
 local kd=c.kind
 for i=1,192 do k[i]=0 fr[i]=0 wet[i]=0 bt[i]=false end
 for y=0,9 do
  for x=0,15 do
   local v=0
   if kd=="brush" or kd=="barn"
    or (kd=="car" and y<9) then
    v=rnd()<.12 and 2 or 1
   end
   if kd=="house" and x>=4 and x<=11
    and y>=2 and y<=7 then v=3 end
   if kd=="barn" and x>=3 and x<=12
    and y>=1 and y<=6 then
    v=(x>=6 and x<=9 and y>=3 and y<=4) and 4 or 3
   end
   k[y*16+x+1]=v
  end
 end
 local ix,iy=7,3
 if kd=="car" then
  k[152]=5 k[153]=5 k[154]=4
  ix,iy=9,9
 elseif kd=="brush" then
  ix=c.far and 10+flr(rnd(4)) or 5+flr(rnd(5))
  if c.wind then ix=2+flr(rnd(3)) end
  iy=c.far and 1+flr(rnd(2)) or 6+flr(rnd(2))
 elseif kd=="house" then
  ix,iy=5+flr(rnd(6)),3+flr(rnd(4))
 end
 total=0
 for i=1,192 do
  fl[i]=0
  if k[i]>0 then
   fl[i]=tp[k[i]][1]
   total+=1
  end
 end
 struct=kd=="house" or kd=="barn"
 nfire=1 nburnt=0
 -- the truck: brush trucks can
 -- pull off the road
 trk={x=20,y=103}
 if ap.off then trk={x=64,y=90} end
 local j=iy*16+ix+1
 seed={j,j-1,j+1,j+16}
 for q in all(seed) do light(q,true) end
 burn(c.size+flr(dt/300))
 srand(t()*997+stat(95)+stat(94)*60)
end

function light(j,force)
 if k[j]>0 and not bt[j] and fr[j]<=0
  and (force or wet[j]<=0) then
  fr[j]=tp[k[j]][2]
 end
end

-- let it burn for n ticks. it
-- never goes out by itself
-- before you start on it
function burn(n)
 for i=1,n do
  tick()
  if nfire==0 then
   for q in all(seed) do
    bt[q]=false
    fl[q]=3
    light(q,true)
   end
   nfire=1
  end
 end
end

-- the fire burns and spreads
function tick()
 local new={}
 local smoky=struct and not vented
 nfire=0 nburnt=0
 for i=1,192 do
  if wet[i]>0 then wet[i]-=1 end
  if fr[i]>0 then
   fl[i]-=1
   if fl[i]<=0 then
    fr[i]=0
    bt[i]=true
   else
    nfire+=1
    local p=tp[k[i]][3]
    if smoky and k[i]>2 then p+=.03 end
    for d in all({-1,1,-16,16}) do
     local q=p
     -- the wind pushes it east
     if c.wind then q*=(d==1 and 2.5 or d==-1 and .5 or 1.2) end
     local j=i+d
     if rnd()<q and j>=1 and j<=192 and (abs(d)==16
      or flr((i-1)/16)==flr((j-1)/16)) then
      add(new,j)
     end
    end
   end
  end
  if bt[i] then nburnt+=1 end
 end
 for j in all(new) do
  if fr[j]<=0 then
   light(j)
   if fr[j]>0 then nfire+=1 end
  end
 end
end

function update_size()
 local nr=struct and 3 or 2
 if btnp(2) then row=(row-2)%nr+1 end
 if btnp(3) then row=row%nr+1 end
 if btnp(0) or btnp(1) then
  if row==1 and #ls>0 then
   li=(li-1+(btnp(1) and 1 or -1))%#ls+1
   hl=lines[ls[li]]
  elseif row==2 then pierce=not pierce
  else wantvent=not wantvent end
  sfx(6)
 end
 if btnp(5) then call_help() end
 if btnp(4) then start_fight() end
end

function call_help()
 local h=helpers[#help+1]
 if not h then
  say("no one else to call")
  return
 end
 add(help,{n=h.n,t=h.t,eta=360+#help*150})
 say(h.n.." is on the way")
 sfx(0)
end

function start_fight()
 state="fight"
 ft=0
 pull=0
 pl={x=trk.x+10,y=trk.y,ax=0,ay=-14,sr=0}
 buddy=nil
 if c.n>=4 then
  buddy={x=trk.x+18,y=trk.y+4,ax=0,ay=-14,sr=0}
 end
 if hl then
  burn(hl.dep)
  say("hold z: spray. arrows aim it",150)
 else
  say("no hose! x: call for an engine",150)
 end
 try_vent()
end

function try_vent()
 if not wantvent or vented then return end
 if ladder then
  vented=true
  say("the ladder crew vents the roof",120)
 elseif c.n>=5 then
  vented=true
  buddy=nil
  say("2 penguins vent the roof",120)
 else
  say("can't vent: no ladder truck yet",120)
 end
end

function update_fight()
 ft+=1
 if ft%60==0 then tick() end
 for h in all(help) do
  if h.eta>0 then
   h.eta-=1
   if h.eta==0 then
    if h.t==1 then
     water+=2000
     if not hl then
      hl=lines[1]
      ls={1,2,3} li=1
      say(h.n..": hose+2000 gal",120)
     else
      say(h.n..": +2000 gal",120)
     end
    else
     ladder=true
     say(h.n.." is on scene",120)
     try_vent()
    end
    sfx(6)
   end
  end
 end
 -- at the truck x pulls a
 -- different hose, anywhere else
 -- it is the radio
 if pull>0 then pull-=1 end
 attrk=#ls>1 and dist(pl.x,pl.y,trk.x,trk.y)<18
 if btnp(5) then
  if attrk then
   li=li%#ls+1
   hl=lines[ls[li]]
   pull=hl.dep*20
   say("you pull the "..hl.n,60)
   sfx(6)
  else
   call_help()
  end
 end
 local dx,dy=0,0
 if btn(0) then dx=-1 end
 if btn(1) then dx=1 end
 if btn(2) then dy=-1 end
 if btn(3) then dy=1 end
 local z=btn(4)
 local p=pl
 local r=hl and hl.reach or 14
 if dx!=0 or dy!=0 then
  local m=(dx!=0 and dy!=0) and .7 or 1
  if z then
   -- holding the nozzle open:
   -- the stick moves where the
   -- water lands
   p.ax+=dx*m*2 p.ay+=dy*m*2
  else
   -- walking: the nozzle swings
   -- round to where you're going
   local l=max(12,dist(0,0,p.ax,p.ay))
   p.ax+=(dx*m*l-p.ax)*.15
   p.ay+=(dy*m*l-p.ay)*.15
   step(p,dx*m,dy*m)
  end
 end
 local l=dist(0,0,p.ax,p.ay)
 if l>r then p.ax*=r/l p.ay*=r/l end
 p.sr=0
 if z and hl and pull<=0 then
  if water>0 then
   spray(p)
   if ft%6==0 then sfx(2) end
  elseif ft%30==0 then
   say("out of water! x: call for more")
  end
 end
 if buddy then ai(buddy) end
 if nfire==0 then
  add(saved,100-flr(nburnt/total*100))
  state="won"
  sfx(3)
 elseif nburnt/total>=c.lim then
  state="fail"
  why="the fire got away from you"
  sfx(5)
 end
end

function dist(ax,ay,bx,by)
 local dx,dy=(ax-bx)/8,(ay-by)/8
 return sqrt(dx*dx+dy*dy)*8
end

function cell(x,y)
 if x<0 or x>127 or y<16 or y>111 then return end
 return flr((y-16)/8)*16+flr(x/8)+1
end

-- walk, but not into the fire and
-- not past the end of the hose
function step(e,dx,dy)
 local sp=1
 if hl then
  sp=hl.sp
  if hl.big and c.n<3 then sp=.3 end
 end
 local nx=mid(4,e.x+dx*sp,123)
 local ny=mid(20,e.y+dy*sp,123)
 local i=cell(nx,ny)
 if i and fr[i]>0 then return end
 if hl and dist(nx,ny,trk.x,trk.y)>hl.hose
  and dist(nx,ny,trk.x,trk.y)>dist(e.x,e.y,trk.x,trk.y) then
  return
 end
 e.x=nx e.y=ny
end

-- water hits everything on the
-- way and hardest where it lands
function spray(e)
 water=max(0,water-hl.flow)
 e.sr=1
 local n=max(1,ceil(dist(0,0,e.ax,e.ay)/4))
 local last
 for q=1,n do
  local i=cell(e.x+e.ax*q/n,e.y+e.ay*q/n)
  if i and i!=last then douse(i) end
  last=i
 end
 if last then
  douse(last)
  if hl.big then
   douse(last-1) douse(last+1)
   douse(last-16) douse(last+16)
  end
 end
end

function douse(i)
 if i<1 or i>192 or fr[i]<=0 then return end
 local d=hl.dmg
 -- water runs off a shut hood or
 -- a hay bale: use the piercing
 -- nozzle
 if k[i]==4 then d*=pierce and 2 or .1
 elseif pierce then d*=.5 end
 fr[i]-=d
 if fr[i]<=0 then
  fr[i]=0
  wet[i]=10
  nfire-=1
 end
end

-- the other penguins on the line
function ai(e)
 if not hl or water<=0 or pull>0 then e.sr=0 return end
 if ft%10==0 or not e.tg or fr[e.tg]<=0 then
  e.tg=nil
  local bd=999
  for i=1,192 do
   if fr[i]>0 then
    local x,y=(i-1)%16*8+4,flr((i-1)/16)*8+20
    local d=dist(x,y,e.x,e.y)
    if d<bd and dist(x,y,trk.x,trk.y)<hl.hose+hl.reach then
     bd=d e.tg=i
    end
   end
  end
 end
 e.sr=0
 if not e.tg then return end
 local x,y=(e.tg-1)%16*8+4,flr((e.tg-1)/16)*8+20
 local d=dist(x,y,e.x,e.y)
 if d<1 then return end
 local r=hl.reach
 if d>r-4 then step(e,(x-e.x)/d,(y-e.y)/d) end
 local m=min(1,r/d)
 e.ax=(x-e.x)*m e.ay=(y-e.y)*m
 if d<=r+2 then spray(e) end
end

-->8
-- update

function _update()
 if msgt>0 then msgt-=1 end
 if state=="title" then
  if btnp(4) then
   level=1 saved={}
   start_call()
  end
 elseif state=="tones" then
  if btnp(4) then state="app" sfx(6) end
 elseif state=="app" then
  if btnp(2) then sel=(sel-2)%5+1 sfx(6) end
  if btnp(3) then sel=sel%5+1 sfx(6) end
  if btnp(4) then start_drive() end
 elseif state=="drive" then update_drive()
 elseif state=="size" then update_size()
 elseif state=="fight" then update_fight()
 elseif state=="fail" then
  if btnp(4) then start_call() end
 elseif state=="won" then
  if btnp(4) then
   level+=1
   if level>#calls then
    state="done"
    sfx(3)
   else
    start_call()
   end
  end
 elseif state=="done" then
  if btnp(4) then state="title" end
 end
end

-->8
-- draw

function cp(s,y,c)
 print(s,64-#s*2,y,c)
end

function truck(a,x,y,sc)
 sc=sc or 1
 local w=flr(a.h*.6+.5)
 pal(6,a.pc)
 if t()%.4<.2 then pal(12,8) pal(14,12) end
 sspr(72,0,12,20,x-w*sc/2,y,w*sc,a.h*sc)
 pal()
end

function peng(x,y,walk)
 sspr(walk and t()%.3<.15 and 16 or 8,0,8,8,x-4,y-5)
end

function _draw()
 if state=="title" then draw_title()
 elseif state=="tones" then draw_tones()
 elseif state=="app" then draw_app()
 elseif state=="drive" then draw_drive()
 elseif state=="done" then draw_done()
 elseif state=="fail" and not onscene then draw_drive() draw_fail()
 else
  draw_scene()
  if state=="size" then draw_size()
  elseif state=="fail" then draw_fail()
  elseif state=="won" then
   box("the fire is out!",
    "you saved "..saved[#saved].."%",
    "z: next call")
  end
 end
 if msgt>0 and (state=="size" or state=="fight") then
  rectfill(0,8,127,15,1)
  cp(msg,10,10)
 end
end

function box(a,b,d)
 rectfill(6,40,121,78,1)
 rect(6,40,121,78,7)
 cp(a,46,7)
 cp(b,56,10)
 cp(d,67,6)
end

function draw_fail()
 box(why,"call "..level.." failed","z: take the call again")
end

function draw_title()
 cls(0)
 for i=0,15 do
  sspr(i%2*8+48,0,8,8,i*8,100+(i*5+flr(t()*4))%3,8,10)
 end
 rectfill(0,110,127,127,5)
 cp("dispatch",10,7)
 cp("ruraltown usa fire dept",20,9)
 sspr(32,0,16,16,20,38,32,32)
 truck(apps[1],88,36,2)
 cp("take the call. pick a truck.",84,7)
 cp("drive there. put it out.",92,7)
 cp("press z to start",116,7)
end

function draw_tones()
 cls(0)
 rectfill(0,0,127,9,8)
 cp("** tones **  call "..level.." of "..#calls,2,7)
 cp("ruraltown fire:",18,6)
 cp(c.t,30,10)
 cp(c.a,40,7)
 cp(c.d,50,7)
 cp(c.n.." penguins are responding",68,12)
 for i=1,c.n do peng(64-c.n*6+i*12-6,86) end
 cp("z: respond",112,7)
end

function draw_app()
 cls(0)
 cp(c.t..", "..c.a,2,10)
 cp("which apparatus do you bring?",12,7)
 for i=1,5 do
  local a=apps[i]
  local y=4+i*20
  if i==sel then
   rectfill(0,y-2,127,y+16,1)
   print(">",2,y+4,7)
  end
  truck(a,18,y-3+(22-a.h)/2,.8)
  print(a.n,32,y,i==sel and 7 or 6)
  print(a.d,32,y+8,i==sel and 12 or 5)
 end
 cp("up/down pick   z: roll",122,6)
end

function draw_drive()
 cls(3)
 for y=0,126,2 do
  local w=dw+100-y
  local x=rx(w)
  rectfill(x-27,y,x+27,y+1,4)
  rectfill(x-22,y,x+22,y+1,5)
  if w%16<8 then rectfill(x,y,x,y+1,10) end
 end
 local w0=flr(dw/24)*24-24
 for w=w0,w0+168,24 do
  local x=rx(w)
  local j=sin(w/97)*6
  sspr(64,0,8,8,x-44+j,100-(w-dw),12,12)
  sspr(64,0,8,8,x+33-j,92-(w-dw),12,12)
 end
 for o in all(obs) do
  local y=100-(o.w-dw)
  if y>-14 and y<128 then
   local x=rx(o.w)+o.o
   if o.k==2 then
    sspr(96,0,8,8,x-4,y-8)
   else
    pal(12,o.col)
    sspr(88,0,8,12,x-4,y-12,8,12,false,o.o<0)
    pal()
   end
  end
 end
 truck(ap,tx,100)
 rectfill(0,0,127,7,1)
 print("to "..c.a,1,1,7)
 rectfill(70,2,125,5,5)
 rectfill(70,2,70+55*min(1,dw/c.dist),5,11)
 print("\148 faster  \131 slower",24,121,7)
end

function draw_scene()
 cls(11)
 rectfill(0,96,127,111,5)
 rectfill(0,112,127,127,3)
 if c.kind=="car" then rectfill(0,88,127,95,4) end
 for i=1,192 do
  local x,y=(i-1)%16*8,flr((i-1)/16)*8+16
  local v=k[i]
  if bt[i] then
   rectfill(x,y,x+7,y+7,0)
   pset(x+2,y+5,5) pset(x+5,y+2,5)
  elseif v==3 then
   rectfill(x,y,x+7,y+7,c.kind=="barn" and 2 or 13)
   line(x,y+7,x+7,y+7,c.kind=="barn" and 4 or 6)
  elseif v==4 and c.kind=="barn" then
   rectfill(x,y,x+7,y+7,10)
   rect(x,y,x+7,y+7,9)
  elseif v==4 then
   rectfill(x,y+1,x+7,y+6,12)
   rectfill(x+5,y+2,x+6,y+5,10)
  elseif v==5 then
   rectfill(x,y+1,x+7,y+6,12)
   rectfill(x+2,y+2,x+5,y+5,1)
  elseif v==2 then
   sspr(64,0,8,8,x,y)
  elseif v==1 and i%3==0 then
   pset(x+3,y+4,3)
  end
  if wet[i]>0 and v>0 and not bt[i] then
   pset(x+1,y+2,12) pset(x+5,y+5,12)
  end
 end
 -- smoke hides a building that
 -- isn't vented
 if struct and not vented then
  fillp(0b0101101001011010.1)
  if c.kind=="barn" then rectfill(24,24,103,71,6)
  else rectfill(32,32,95,79,6) end
  fillp()
 end
 for i=1,192 do
  if fr[i]>0 then
   local x,y=(i-1)%16*8,flr((i-1)/16)*8+16
   sspr(48+(i+flr(t()*6))%2*8,0,8,8,x,y)
  end
 end
 truck(ap,trk.x,trk.y-ap.h/2)
 if state!="size" then
  for e in all({pl,buddy}) do
   if hl then
    line(trk.x,trk.y,e.x,e.y,9)
    local ex,ey=e.x+e.ax,e.y+e.ay
    if e.sr>0 then
     line(e.x,e.y-3,ex,ey,12)
     line(e.x+1,e.y-3,ex+1,ey,12)
     circ(ex,ey,1+flr(t()*10)%3,7)
    elseif e==pl then
     -- where the water will land
     pset(ex-2,ey,7) pset(ex+2,ey,7)
     pset(ex,ey-2,7) pset(ex,ey+2,7)
    end
   end
   peng(e.x,e.y,true)
  end
 end
 -- hud
 rectfill(0,0,127,7,1)
 print("water",1,1,12)
 rectfill(23,2,58,5,5)
 if water>0 then
  rectfill(23,2,23+35*min(1,water/2000),5,12)
 end
 print(flr(water),61,1,7)
 local b=flr(nburnt/total*100)
 print("burned "..b.."%",84,1,b>c.lim*70 and 8 or 7)
 if state=="fight" then
  local s=hl and hl.n or "no hose"
  for h in all(help) do
   if h.eta>0 then
    s=h.n.." "..ceil(h.eta/30).."s"
    break
   end
  end
  if pull>0 then s="pulling hose..." end
  print(s,1,121,7)
  s=attrk and "\151swap hose" or "\151help"
  print(s,128-#s*4-4,121,10)
 end
end

function draw_size()
 rectfill(0,66,127,127,1)
 rect(0,66,127,127,7)
 print("size-up: call "..level,3,69,10)
 print(c.su,3,77,7)
 local function opt(r,l,v)
  local y=78+r*8
  print((row==r and ">" or " ")..l,3,y,row==r and 7 or 6)
  print("\139"..v.."\145",44,y,row==r and 10 or 6)
 end
 opt(1,"hose",hl and hl.n or "none!")
 opt(2,"nozzle",pierce and "piercing" or "fog")
 if struct then opt(3,"vent roof",wantvent and "yes" or "no") end
 local s="x: call for help"
 if #help>0 then s="x: more help ("..#help.." coming)" end
 print(s,3,111,12)
 print("z: fight the fire!",3,119,11)
end

function draw_done()
 cls(0)
 cp("every call is done!",12,7)
 local a=0
 for i=1,#saved do
  a+=saved[i]
  print(calls[i].t,10,22+i*8,6)
  print(saved[i].."% saved",80,22+i*8,10)
 end
 cp("you saved "..flr(a/#saved).."% of ruraltown",94,11)
 sspr(32,0,16,16,56,102)
 cp("z: back to the station",121,6)
end
__gfx__
0000000000aaaa0000aaaa000000000000000aaaaaa0000000008000000800000033330000cc77ee000000000cccccc004000040000000000000000000000000
000000000aaaaaa00aaaaaa0000000000000aaaaaaaa00000008800008088000033333300888888880000000cccccccc00444400000000000000000000000000
00700700017117100171171000000000000aaaa88aaaa000008980800808980033b33333788888888e000000c111111c004f4f00000000000000000000000000
0007700001199110011991100000000000aaaaaaaaaaaa0008998080088998003333b3330877777780000000c111111c00444400000000000000000000000000
000770001177771111777711000000000000111111110000089a98808899a980333333330871111780000000cccccccc04444440000000000000000000000000
00700700117777111177771100000000000117111171100089aa9980899aa9803b3333330888888880000000cccccccc04444440000000000000000000000000
00000000017777100177771000000000000111199111100089a7a98089a7a980033333300888888880000000cccccccc04044040000000000000000000000000
000000000990099099000099000000000001119999111000089aa80008aa9800003333000866666680000000cccccccc04000040000000000000000000000000
0000000000000000000000000000000000111177771111000000000000000000000000000866666680000000c111111c00000000000000000000000000000000
0000000000000000000000000000000001111777777111100000000000000000000000000865665680000000cccccccc00000000000000000000000000000000
00000000000000000000000000000000011177777777111000000000000000000000000008666666800000008cccccc800000000000000000000000000000000
000000000000000000000000000000000111a7777777a11000000000000000000000000008656656800000000cccccc000000000000000000000000000000000
000000000000000000000000000000000011a7777777a10000000000000000000000000008666666800000000000000000000000000000000000000000000000
00000000000000000000000000000000000177777777100000000000000000000000000008656656800000000000000000000000000000000000000000000000
00000000000000000000000000000000000099000099000000000000000000000000000008666666800000000000000000000000000000000000000000000000
00000000000000000000000000000000000999000099900000000000000000000000000008666666800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000008888888800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000008777777800000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000588888888c0000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000005500005500000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000c00002105021050210502105021050210502605026050260502605026050260502605026050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600101e22020220222202422026220282202a2202c2202a22028220262202422022220202201e2201c22000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000286202d620266200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000180501c0501f05024050280502b0503005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000014240102400c2400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005000016660126600e6600a66006660046600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002414028140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
