program startgame;
uses crt;

const
    PointCharacterCount = 7;
    RigthScreenBorder = 0;
    DelayDuration = 70;
    EndDelay = 5000;
    GaOvPoints = 102;
    ScrWidthShift = -1;
    ScrHeightShift = -4;
    left = 'l';
    rigth = 'r';

type
    Point = record
        X, Y: integer;
        TextColor, BgColor: byte;
    end;

    character = record
        ArrayPos: array[1..PointCharacterCount] of Point;
    end;

    chain = record
        x, y: integer;
    end;

    itemptr = ^item;

    item = record
        data: chain;
        next: itemptr;
    end;

var
    first: itemptr = nil;

procedure GetKey(var code: integer);
var
    c: char;
begin
    c := ReadKey;
    if c = #0 then begin
        c := ReadKey;
        code := -ord(c)
    end
    else begin
        code := ord(c)
    end
end;

procedure InitChar(var ch: character);
begin
    ch.ArrayPos[1].X := 2; 
    ch.ArrayPos[1].Y := 1; 
    ch.ArrayPos[2].X := 1;
    ch.ArrayPos[2].Y := 2; 
    ch.ArrayPos[3].X := 2;
    ch.ArrayPos[3].Y := 2; 
    ch.ArrayPos[4].X := 3;
    ch.ArrayPos[4].Y := 2; 
    ch.ArrayPos[5].X := 2;
    ch.ArrayPos[5].Y := 3; 
    ch.ArrayPos[6].X := 1;
    ch.ArrayPos[6].Y := 4; 
    ch.ArrayPos[7].X := 3;
    ch.ArrayPos[7].Y := 4; 
end;

procedure ShowSymbol (symb: char; x, y: integer);
begin
    GotoXY(x, y);
    write(symb)
end;

procedure BuildLevel(x, y, size: integer; symbol: char);
var
    i: integer;
    GroundPoint: chain;
    tmp:itemptr = nil;
begin
    for i := x to (x + size - 1) do begin
        GroundPoint.x := i;
        GroundPoint.y := y;
        new(tmp);
        tmp^.data := GroundPoint;
        tmp^.next := first;
        first := tmp;
        ShowSymbol(symbol, GroundPoint.x, GroundPoint.y)
    end
end;

procedure InitBorder;
var
    i: integer;
    levelcount, levelsize, levelseed, levelx, levely, levelcorr: integer;
begin
    BuildLevel(1, ScreenHeight, (ScreenHeight + ScrHeightShift), '@'); 

    levelcount := random(7-4+1) + 4;
    levelseed := (ScreenHeight + ScrHeightShift) div levelcount;
    levely := 0;
    for i := 1 to levelcount do begin
        levelx := random(ScreenWidth + ScrWidthShift) + 1;
        levelcorr := random(2 - (-2) + 1) + (-2); 
        levely := levely + levelseed;
        levelsize := random(40-15 +1) + 15;
        if (levelsize + levelx) > (ScreenWidth + ScrWidthShift) then
            levelsize := (ScreenWidth + ScrWidthShift) - levelx;
        if levely + levelcorr > ScreenHeight then
            break;
        if (i mod 2) = 0 then
            levelx := (ScreenWidth + ScrWidthShift) - (levelsize + levelx) + 1;
        BuildLevel(levelx, levely + levelcorr, levelsize, '@');
    end;
    GotoXY(1, 1)
end;

procedure ShowChar(X, Y: integer; ch: character);
var
    i: integer;
begin
    for i := 1 to PointCharacterCount do 
        ShowSymbol('#', X + ch.ArrayPos[i].X, Y + ch.ArrayPos[i].Y);
    GotoXY(1, 1)
end;

procedure HideChar(X, Y: integer; ch: character);
var
    i: integer;
begin
    for i := 1 to PointCharacterCount do 
        ShowSymbol(' ', X + ch.ArrayPos[i].X, Y + ch.ArrayPos[i].Y);
    GotoXY(1, 1)
end;

procedure RewriteField(X, Y: integer; ch: character);
var
    tmp: itemptr;
    i: integer;
    charFlag: boolean;
begin
    tmp := first;
    while true do begin
        charFlag := false;
        if (tmp^.data.y <= (Y-ScrHeightShift+2)) and
           (tmp^.data.y >= Y - 1) then begin
            for i := 1 to PointCharacterCount do begin  
                if (ch.ArrayPos[i].X + X = tmp^.data.x) and
                   (ch.ArrayPos[i].Y + Y = tmp^.data.y) then begin
                   charFlag := true;
                   break;
                end
            end;
            if not charFlag then begin
                GotoXY(tmp^.data.x, tmp^.data.y);
                ShowSymbol('@',tmp^.data.x, tmp^.data.y);
            end
        end;
        tmp := tmp^.next;
        if tmp = nil then
            break
    end;
    GotoXY(1,1)
end;

procedure MoveChar(var X, Y: integer; ch: character; shiftX, shiftY: SmallInt);
begin
    HideChar(X, Y, ch);
    X := X + shiftX;
    Y := Y + shiftY;
    if X < 0 then
        X := 0;
    if X > (ScreenWidth + ScrWidthShift) then
        X := ScreenWidth + ScrWidthShift;
    if Y < 0 then
        Y := 0;
    if Y > (ScreenHeight + ScrHeightShift) then
        Y := (ScreenHeight + ScrHeightShift);
    ShowChar(X, Y, ch);
    RewriteField(X, Y, ch)
end;
        
function CheckGround (var x, y: integer; ch: character): boolean;
label
    quit;
var
    tmp: itemptr;
    pointleg: chain;
    i: integer;
begin
    for i := 1 to 3 do begin
        pointleg.x := x + i;
        pointleg.y := y + 5;
        tmp := first;
        while true do begin
            if (tmp^.data.x = pointleg.x) and (tmp^.data.y = pointleg.y) then begin
                CheckGround := true;
                goto quit
            end;
            if tmp^.next = nil then
                break
            else
                tmp := tmp^.next
        end;
    end;
    MoveChar(x, y, ch, 0, 1);
    delay(DelayDuration);
    CheckGround := false;
quit:
end;

procedure GameOver;
var
    arrOver: array[1..(GaOvPoints*2)] of integer = (-25,-2,  -25,-1,  -25,0,  -25,1, -25,2,
        -24,-2,  -24,2,  -23,-2,  -23,0,  -23,2,  -22,-2, -22,0, -22,1, -22,2,  -19,-1, -19,0, -19,1, -19,2,
        -18,-2,  -18,0,  -17,-2,  -17,0,  -16,-1,  -16,0,  -16,1,  -16,2,  -13,-2,  -13,-1,  -13,0,  -13,1,  -13,2,
        -12,-1,  -11,0,  -10,-1,  -9,-2,  -9,-1,  -9,0,  -9,1,  -9,2,  -6,-2,  -6,-1,  -6,0,  -6,1, -6,2,
        -5,-2,  -5,0,  -5,2,  -4,-2,  -4,0,  -4,2,  -3,-2,  -3,0,  -3,2,  3,2,  3,1,  3,0,  3,-1,  3,-2,
        4,2,  4,-2,  5,2,  5,-2,  6,2,  6,1,  6,0,  6,-1,  6,-2,  9,-2,  9,-1,  10,0,  10,1,  11,2,  12,0,  12,1,
        13,-2,  13,-1,  16,-2,  16,-1,  16,0,  16,1,  16,2,  17,-2,  17,0,  17,2,  18,-2,  18,0,  18,2,  19,-2,
        19,0,  19,2,  22,-2,  22,-1,  22,0,  22,1,  22,2,  23,-2,  23,0,  24,-2,  24,0,  24,1,  25,-1, 25,2);
    i, gap: integer;
    x, y, cenX, cenY: integer;
begin
    clrscr;
    gap := 0;
    CenX := (ScreenWidth + ScrWidthShift) div 2;
    CenY := ScreenHeight div 2;
    for i := 1 to GaOvPoints do begin
        x := arrOver[i + gap];
        y := arrOver[i + gap + 1];
        ShowSymbol('#', CenX + x, CenY + y);
        gap := gap + 1
    end;
    GotoXY(1, 1);
    delay(EndDelay);
    clrscr;
    halt
end;

procedure DoJump (var x,y: integer; ch: character);
var
    i: integer;
    g: integer;
    c: SmallInt;
begin
    for i := 1 to 5 do begin
        MoveChar(x, y, ch, 0, -1);
        for g:= 1 to 2 do begin
            if KeyPressed then begin
                GetKey(c);
                case c of
                -75: MoveChar(X, Y, ch, -2, 0);
                -77: MoveChar(X, Y, ch, 2, 0);
                27: break;
                end
            end;
            delay(DelayDuration)
        end
    end;
    while not CheckGround(x, y, ch) do begin
        if Y = (ScreenHeight + ScrHeightShift) then
            GameOver;
        if KeyPressed then begin
            GetKey(c);
            case c of
            -75: MoveChar(X, Y, ch, -1, 0);
            -77: MoveChar(X, Y, ch, 1, 0);
            27: break;
            end
        end
    end
end;

procedure SetStair(x, y: integer; side: char);
var
    stairX, stairY: integer;
begin
    stairY := y + 1;
    if side = left then
        stairX := x - 8
    else if side = rigth then
        stairX := x + 11;
    if (StairX < 2) or (StairX > (ScreenWidth + ScrWidthShift - 8)) then
        exit;
    BuildLevel(StairX, StairY, 2, '=')
end;

var
    X, Y: integer;
    ch: character;
    c: SmallInt;

begin
    randomize;
    clrscr;
    InitChar(ch);
    InitBorder;
    X := 0;
    Y := (ScreenHeight + ScrHeightShift - 1);
    // Y := 1;
    ShowChar(X, Y, ch);
    while true do begin
        CheckGround(X, Y, ch);
        if Y = (ScreenHeight + ScrHeightShift) then
            GameOver;
        if KeyPressed then begin
            GetKey(c);
            case c of
            -75: MoveChar(X, Y, ch, -1, 0);
            -77: MoveChar(X, Y, ch, 1, 0);
            113: SetStair(X, Y, left);
            119: SetStair(X, Y, rigth);
            32: DoJump(X, Y, ch);
            27: break;
            end
        end
    end;
    clrscr
end.
