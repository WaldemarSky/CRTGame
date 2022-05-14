program startgame;
uses crt, dateutils, sysutils;

const
    PointCharacterCount = 7;
    FieldLvShift = -3;
    DelayDuration = 70;
    DurStair = 2;
    EndDelay = 5000;
    GaOvPoints = 102;
    ScrWidthShift = -1;
    ScrHeightShift = -4;
    left = 'l';
    rigth = 'r';
    ChanceForLevel = 0.20;

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

    itemptr = ^itemlevel;
    itemstptr = ^itemStair;

    itemlevel = record
        data: chain;
        next: itemptr;
    end;

    itemStair = record
        data: chain;
        duration: smallint;
        next: itemstptr;
    end;

var
    LevelPtr: itemptr = nil;
    StPtFirst: itemstptr = nil; 
    StPtLast: itemstptr = nil; 
    score: integer = 0;

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

procedure ShowSymbol (symb: char; bg, fg: word; x, y: integer);
begin
    TextBackground(bg);
    TextColor(fg);
    GotoXY(x, y);
    write(symb)
end;

procedure BuildLevel(x, y, size: integer);
var
    i: integer;
    GroundPoint: chain;
    tmp: itemptr = nil;
begin
    for i := x to (x + size - 1) do begin
        GroundPoint.x := i;
        GroundPoint.y := y;
        new(tmp);
        tmp^.data := GroundPoint;
        tmp^.next := LevelPtr;
        LevelPtr := tmp;
        ShowSymbol('@', Green, Black, GroundPoint.x, GroundPoint.y)
    end;
    GotoXY(1, 1)
end;

procedure BuildStair(x, y: integer);
var
    StairPoint: chain;
begin
    StairPoint.x := x;
    StairPoint.y := y;
    if StPtFirst = nil then begin
        new(StPtFirst);
        StPtLast := StPtFirst
    end
    else begin
        new(StPtLast^.next);
        StPtlast := StPtlast^.next
    end;
    StPtlast^.data := StairPoint;
    StPtlast^.duration := DurStair;
    StPtlast^.next := nil;
    ShowSymbol('=', LightGray, Black, StairPoint.x, StairPoint.y);
    GotoXY(1, 1)
end;

procedure InitBorder;
var
    i: integer;
    levelcount, levelsize, levelseed, levelx, levely, levelcorr: integer;
begin
    BuildLevel(1, ScreenHeight, (ScreenHeight + ScrHeightShift)); 

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
        BuildLevel(levelx, levely + levelcorr, levelsize);
    end;
    GotoXY(1, 1)
end;

procedure GenNewLevel;
var
    LevelChance: real;
    levelsize, levelx, levely: integer;
    i: SmallInt;
begin
    score := score + 1;
    LevelChance := random;
    i := random(2);
    if LevelChance < ChanceForLevel then begin
        levelx := random(ScreenWidth + ScrWidthShift) + 1;
        levely := 1; 
        levelsize := random(40-15 +1) + 15;
        if (levelsize + levelx) > (ScreenWidth + ScrWidthShift) then
            levelsize := (ScreenWidth + ScrWidthShift) - levelx;
        if i = 1 then
            levelx := (ScreenWidth + ScrWidthShift) - (levelsize + levelx) + 1;
        BuildLevel(levelx, levely, levelsize);
    end;
    GotoXY(1, 1)
end;

procedure ShowChar(X, Y: integer; ch: character);
var
    i: integer;
begin
    for i := 1 to PointCharacterCount do 
        ShowSymbol('#', Blue, Red, X + ch.ArrayPos[i].X, Y + ch.ArrayPos[i].Y);
    GotoXY(1, 1)
end;

procedure HideChar(X, Y: integer; ch: character);
var
    i: integer;
begin
    for i := 1 to PointCharacterCount do 
        ShowSymbol(' ', Black, Black, X + ch.ArrayPos[i].X, Y + ch.ArrayPos[i].Y);
    GotoXY(1, 1)
end;

procedure RewriteField(X, Y: integer; ch: character);
var
    tmp: itemptr;
    tmps: itemstptr; 
    i: integer;
    charFlag: boolean;
begin
    tmp := LevelPtr;
    while true do begin
        charFlag := false;
        if (tmp^.data.y <= (Y-ScrHeightShift+2)) and
           (tmp^.data.y >= Y - 1) then begin
            for i := 1 to PointCharacterCount do begin  
                if (ch.ArrayPos[i].X + X = tmp^.data.x) and
                   (ch.ArrayPos[i].Y + Y = tmp^.data.y) then begin
                   charFlag := true;
                   break
                end
            end;
            if not charFlag then begin
                GotoXY(tmp^.data.x, tmp^.data.y);
                ShowSymbol('@', Green, Black, tmp^.data.x, tmp^.data.y);
            end
        end;
        tmp := tmp^.next;
        if tmp = nil then
            break
    end;
    tmps := StPtFirst;
    charFlag := false;
    while true do begin
        if tmps = nil then
            break;
        for i := 1 to PointCharacterCount do begin  
            if (ch.ArrayPos[i].X + X = tmps^.data.x) and
               (ch.ArrayPos[i].Y + Y = tmps^.data.y) then begin
               charFlag := true;
               break
            end
        end;
        if not charFlag then begin
            GotoXY(tmps^.data.x, tmps^.data.y);
            ShowSymbol('=', LightGray, Black, tmps^.data.x, tmps^.data.y);
        end;
        tmps := tmps^.next
    end;
    GotoXY(1,1)
end;

procedure RewriteAllField;
var
    tmp: itemptr;
    tmps: itemstptr; 
begin
    tmp := LevelPtr;
    while tmp <> nil do begin
        GotoXY(tmp^.data.x, tmp^.data.y);
        ShowSymbol('@', Green, Black, tmp^.data.x, tmp^.data.y);
        tmp := tmp^.next;
    end;
    tmps := StPtFirst;
    while true do begin
        if tmps = nil then
            break;
        GotoXY(tmps^.data.x, tmps^.data.y);
        ShowSymbol('=', LightGray, Black, tmps^.data.x, tmps^.data.y);
        tmps := tmps^.next
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
    tmps: itemstptr; 
    pointleg: chain;
    i: integer;
begin
    for i := 1 to 3 do begin
        pointleg.x := x + i;
        pointleg.y := y + 5;
        tmp := LevelPtr;
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
        if StPtFirst <> nil then begin
            tmps := StPtFirst;
            while true do begin
                if (tmps^.data.x = pointleg.x) and (tmps^.data.y = pointleg.y) then begin
                    CheckGround := true;
                    goto quit
                end;
                if tmps^.next = nil then
                    break
                else
                    tmps := tmps^.next
            end
        end
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
        ShowSymbol('#', Red, LightBlue, CenX + x, CenY + y);
        gap := gap + 1
    end;
    GotoXY(CenX - 7, CenY + 3);
    writeln('Total score: ', score);
    GotoXY(1, 1);
    delay(EndDelay);
    clrscr;
    write(#27'[0m');
    halt
end;

procedure DoJump (var x,y: integer; ch: character);
var
    i: integer;
    g: integer;
    c: SmallInt;
    pp: ^itemptr;
    tmp: itemptr;
    pps: ^itemstptr;
    tmps: itemstptr;
begin
    for i := 1 to 5 do begin
        if Y <= (ScreenHeight div 2 + FieldLvShift) then begin
            GotoXY(2, 1);
            TextBackground(Black);
            writeln('score: ', score);
            pp := @LevelPtr;
            while pp^ <> nil do begin
                ShowSymbol(' ', Black, Black, pp^^.data.x, pp^^.data.y);
                pp^^.data.y := pp^^.data.y + 1;
                if pp^^.data.y > ScreenHeight then begin 
                    tmp := pp^;
                    pp^ := pp^^.next;
                    dispose(tmp)
                end
                else
                    pp := @(pp^^.next)
            end;
            pps := @StPtFirst;
            while pps^ <> nil do begin
                ShowSymbol(' ', Black, Black, pps^^.data.x, pps^^.data.y);
                pps^^.data.y := pps^^.data.y + 1;
                if pps^^.data.y > ScreenHeight then begin 
                    tmps := pps^;
                    pps^ := pps^^.next;
                    dispose(tmps)
                end
                else
                    pps := @(pps^^.next)
            end;
            RewriteAllField;
            GenNewLevel
        end
        else
            MoveChar(X, Y, ch, 0, -1);
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

procedure SetStair(var x, y: integer; ch: character; side: char);
var
    stairX, stairY: integer;
begin
    stairY := y + 1;
    if side = left then
        stairX := x - 7
    else if side = rigth then
        stairX := x + 11;
    if (StairX < 2) or (StairX > (ScreenWidth + ScrWidthShift - 8)) then
        exit;
    BuildStair(StairX, StairY);
end;

procedure RemoveStairs;
var
    tmps: itemstptr;
begin
    tmps := StPtFirst;
    while tmps <> nil do begin
        tmps^.duration := tmps^.duration - 1;
        tmps := tmps^.next
    end;
    if (StPtFirst <> nil) and (StPtFirst^.duration <= 0) then begin
        tmps := StPtFirst;
        StPtFirst := StPtFirst^.next;
        if StPtFirst = nil then
            StPtLast := nil;
        ShowSymbol(' ', Black, Black, tmps^.data.x, tmps^.data.y);
        GotoXY(1,1);
        dispose(tmps)
    end
end;

procedure OneStep(var x, y: integer; ch: character);
var
    c: SmallInt;
begin
    CheckGround(x, y, ch);
    if y = (ScreenHeight + ScrHeightShift) then
        GameOver;
    if KeyPressed then begin
        GetKey(c);
        case c of
        -75: MoveChar(x, y, ch, -1, 0);
        -77: MoveChar(x, y, ch, 1, 0);
        113: SetStair(x, y, ch, left);
        119: SetStair(x, y, ch, rigth);
        32: DoJump(x, y, ch);
        27: begin
            clrscr;
            write(#27'[0m');
            halt
        end
        end
    end
end;

var
    X, Y: integer;
    StartSec, LastSec: int64;
    ch: character;
begin
    assign(stderr, 'log.txt');
    rewrite(stderr);
    randomize;
    clrscr;
    InitChar(ch);
    InitBorder;
    X := 0;
    Y := (ScreenHeight + ScrHeightShift - 1);
    ShowChar(X, Y, ch);
    GotoXY(2, 1);
    TextBackground(Black);
    writeln('score: ', score);
    StartSec := DateTimeToUnix(Now());
    while true do begin
        OneStep(x, y, ch);
        LastSec := DateTimeToUnix(Now());
        if LastSec <> StartSec then begin
            StartSec := LastSec;
            RemoveStairs
        end
    end
end.
