unit ubads;

{$mode delphi}

interface

uses
  Classes, SysUtils, utypes, Laz_And_Controls, AndroidWidget;

const
  MaxBad = 5000;
type
  TBadState = (bsStay, bsLive, bsGone, bsSleep);
  TBad = record
    Center : TPointF;
    BadState : TBadState;
    Orange : boolean;
    ind  : integer;
    Bad  : boolean;
    Gems : boolean;
    bmp  : jBitMap;
    mass : Single;
    Border : Boolean;
    DX, DY : Single;
  end;


procedure DrawBads(Canvas : jCanvas);
procedure Collide_Ball(var ball: TBad; var ball2: TBad);
procedure SetBad(aX, aY : Single; Bord : boolean = False; ForceOrange : boolean = False);
function  BallHitBad(pBall : TPointF; var Bonus : integer) : boolean;
procedure CheckCollides;
procedure BadOnTimer;

var
  Bads  : array[ 0.. MaxBad ] of TBad;
  BadCount : integer = 0;
  StartBad : integer = 0;

implementation

uses uball, ubgr, ucurr, ububble, asset, Math, ttcalc, udbg;

function Check(P : TPointF) : boolean;
var I : integer;
    dx0, dy0 : Single;
begin
  Result := False;
  I := BadCount - 1;
  while (I >= StartBad) do with Bads[ I ] do
  begin
    dx0 := P.x - Center.x;
    dy0 := P.y - Center.y;
    if dx0 * dx0 + dy0 * dy0 < WallWallGap then
      Exit;
    Dec(I);
  end;
  Result := True;
end;

procedure  BadOnTimer;
var I : integer;
begin
  for I := StartBad to BadCount - 1 do with Bads[ I ] do if BadState = bsLive then
  begin
    Center.Y := Center.Y + DY;
    Center.X := Center.X + DX;
  //  end else
  //  begin
  //    if (BadState = bsSleep) and (Cent.Y - Center.Y < ScreenHeight4) then
  //      BadState := bsLive;
  end;
end;

function BallHitBad(pBall : TPointF; var Bonus : integer) : boolean;
var I : integer;
    d : Single;
begin
  Result := False;
  Bonus := 0;
  d  := (gm.BallDiam + gm.StoneDiam) / 2;
  for I := StartBad to BadCount - 1 do with Bads[ I ] do
    if (BadState < bsGone) and (Distance(pBall, Center) < d) then
    begin
      BadState := bsGone;
      if Bad then
      begin
        Result := True;
        Exit;;
      end else
      begin
        if Gems then
        begin
          Bonus := GemBonus;
          Play('bleep.mp3');
        end
        else if Orange then
        begin
          Bonus := OrangeBonus;
          Play('chime.mp3');
        end
        else
        begin
          Bonus := FruitBonus;
          Play('chime1.mp3');
        end;
        MakeBubbles(Center.X - LeftX, Center.Y - TopY, Bonus);
      end;
    end;
end;

procedure SetBad(aX, aY : Single; Bord : boolean = False; ForceOrange : boolean = False);
begin
//  zz('setBad,aX=' + inttostr(round(aX)) + ',aY='+inttostr(round(aY)) + ifthen(bord, ',bord',''));
  if aY > StartLimY then
    Exit;
{$IFDEF DEBUG}
try
{$ENDIF}
  with Bads[ BadCount ] do
  begin
    Center := PointF(aX, aY);
    bmp    := nil;
    BadState := bsStay;
    DX     := 0;
    DY     := 0;
    ind    := 0;
    Border := Bord;
    Mass   := 100;
    Orange := False;
    if Bord then
    begin
      if not Check(Center) then
        Exit;
      Bad  := True;
      if Cat then
        bmp  := GetCats(ind)
      else
        bmp  := GetAlien(ind);
    end else
    begin
      Bad  := False;
      if ForceOrange then
      begin
        if not Check(Center) then
          Exit;
//zz('Orange ' + ifthen((aX > LeftX) and (aX < LeftX + gm.ScreenWidth), 'scr ', '--- ') + p2s(pointf(ax,ay)));
        Orange := True;
        bmp  := GetFruit(ind);
      end
      else
      begin
        Center := PointF(aX + gm.Pad + gm.Off * (random(100) * 0.01),
                         aY + gm.Pad + gm.Off * (random(100) * 0.01));
        if not Check(Center) then
          Exit;
        if random(100) < MulDiv(70 - Level * 3, BadNum, GoodNum) then
        begin
          Inc(GoodNum);
          if random(100) < 20 then
            bmp := GetGem(ind)
          else
            bmp := GetFruit(ind);
        end
        else
        begin
          Inc(BadNum);
          Bad  := True;
          mass := 1;
          if Cat then
            bmp  := GetCats(ind)
          else
            bmp  := GetAlien(ind);
        end;
      end;
    end;
  end;
  Inc(BadCount);
  if MaxBad = BadCount then
    Fatal('MaxBad = BadCount');
{$IFDEF DEBUG}
  except
    zz('*setbad');
    raise;
  end;
{$ENDIF}
end;


procedure TrimBads;
begin
  while Bads[StartBad].Center.Y > FisScrSt.Bottom do
  begin
    Bads[StartBad].BadState := bsGone;
    Inc(StartBad);
    if StartBad = BadCount then
      Break;
  end;
end;

procedure DrawBads(Canvas : jCanvas);
var I : integer;
    NowAlive : boolean;
    Cent : TPointF;
    sp : Single;
begin
  TrimBads;
  NowAlive := (User <> uNovice) and (TimeCount mod 12 = 2) and not (asDemo in AppState);
  for I := StartBad to BadCount - 1 do with Bads[I] do
  begin
    if (BadState < bsGone) and PtInRect(FisScrSt, Center) then
    begin
      if NowAlive and (BadState = bsStay) and (mass = 1) then
      begin
        BadState := bsLive;
        if not Border then
        begin
          sp := speed * 0.2;
          DX := sp * ((50 - random(100)) / 100);
          DY := sp * (random(100) / 100);
        end;
      end;
      Cent.X := Center.X - LeftX;
      Cent.Y := Center.Y - TopY;
      PutBitMap(Canvas, bmp, Cent);
    end;
  end;
end;

procedure Collide_Ball(var ball: TBad; var ball2: TBad);
var
  dx, dy, D : Single;
  collisionision_angle : Single;
  magnitude_1, magnitude_2, direction_1, direction_2 : Single;
  new_xspeed_1, new_yspeed_1, new_xspeed_2, new_yspeed_2 : Single;
  final_xspeed_1, final_xspeed_2, final_yspeed_1, final_yspeed_2 : Single;
  pa, pb : TPointF;
begin
  if (ball.BadState <> bsLive) and (ball2.BadState <> bsLive) or (abs(ball.Center.X - ball2.Center.X) > gm.BallDiam) or (abs(ball.Center.Y - ball2.Center.Y) > gm.BallDiam) then
    Exit;
  pa := ball.Center;
  pb := ball2.Center;
  D  := Distance(pa, pb);
  if D < 1 then
    Exit;
  if D > gm.StoneDiam then
    Exit;
  pa.x := pa.x + ball.dx;
  pa.y := pa.y + ball.dy;
  pb.x := pb.x + ball2.dx;
  pb.y := pb.y + ball2.dy;
  if Distance(pa, pb) > D then
    Exit;
  dx := ball.Center.x - ball2.Center.x;
  dy := ball.Center.y - ball2.Center.y;
  collisionision_angle := arctan2(dy, dx);

  magnitude_1  := sqrt(ball.dx * ball.dx + ball.dy * ball.dy);
  magnitude_2  := sqrt(ball2.dx * ball2.dx + ball2.dy * ball2.dy);

  direction_1  := arctan2(ball.dy, ball.dx);
  direction_2  := arctan2(ball2.dy, ball2.dx);


  new_xspeed_1 := magnitude_1 * cos(direction_1 - collisionision_angle);
  new_yspeed_1 := magnitude_1 * sin(direction_1 - collisionision_angle);

  new_xspeed_2 := magnitude_2 * cos(direction_2 - collisionision_angle);
  new_yspeed_2 := magnitude_2 * sin(direction_2 - collisionision_angle);

  final_xspeed_1 := ((ball.mass - ball2.mass) * new_xspeed_1 + (ball2.mass + ball2.mass) * new_xspeed_2) / (ball.mass + ball2.mass);
  final_xspeed_2 := ((ball.mass + ball.mass)  * new_xspeed_1 + (ball2.mass - ball.mass)  * new_xspeed_2) / (ball.mass + ball2.mass);
  final_yspeed_1 := new_yspeed_1;
  final_yspeed_2 := new_yspeed_2;
  ball.dx  := cos(collisionision_angle) * final_xspeed_1 + cos(collisionision_angle + PI/2) * final_yspeed_1;
  ball.dy  := sin(collisionision_angle) * final_xspeed_1 + sin(collisionision_angle + PI/2) * final_yspeed_1;
  ball2.dx := cos(collisionision_angle) * final_xspeed_2 + cos(collisionision_angle + PI/2) * final_yspeed_2;
  ball2.dy := sin(collisionision_angle) * final_xspeed_2 + sin(collisionision_angle + PI/2) * final_yspeed_2;
  ball.BadState := bsLive;
  ball2.BadState := bsLive;
end;

procedure CheckCollides;
var I, J : integer;
begin
  for I := StartBad to BadCount - 1 do
    for J := I + 1 to BadCount - 1 do
      Collide_Ball(Bads[ I ], Bads[ J ]);
end;


end.

