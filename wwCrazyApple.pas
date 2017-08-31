unit wwCrazyApple;

interface

Uses
 wwMinds, wwTypes, wwClasses;

type
  TCrazyAppleMind = class (TwwMind)
  protected
    function GetCaption: string; override;
    function GetEnglishCaption: string; override;
    function Thinking: TwwDirection; override;
  end;

implementation

Uses
 Types,
 wwWorms, wwUtils, WormsWorld;


{ TCrazyAppleMind }

function TCrazyAppleMind.GetCaption: string;
begin
  Result:= 'Сумасшедшее яблоко'
end;

function TCrazyAppleMind.GetEnglishCaption: string;
begin
  Result:= 'Crazy Apple'
end;

function TCrazyAppleMind.Thinking: TwwDirection;
var
 l_Hunter: TwwWorm;
 l_H, l_Me, l_New, l_B, l_B2: TPoint;
 l_FavDir: TwwFavoriteType;
 l_LegalDirs: TwwDirections;
 l_DirToWorm, l_DirToWall,
 l_DirToWall2, l_DirToNeck: TwwDirection;
 l_Distance: Integer;

 function lp_ShiftDir(aDir: TwwDirection): TwwDirection;
 begin
   Result:= aDir;
   repeat
     Exclude(l_LegalDirs, Result);
     Result:= ShiftDir(Result);
   until (Result in l_LegalDirs) or (l_LegalDirs = []);
 end;

begin
  Result:= dtNone;
  l_Me:= Thing.Head.Position;
  l_Hunter:= (Thing.World as TWormsField).NearestWorm(l_Me);
  if l_Hunter <> nil then
  begin
    l_H:= l_Hunter.Head.Position;
    l_Distance:= CalcDistance(l_H, l_Me);

    if l_Distance < 10 then
    begin
      // Нужно убегать
      if Abs(l_H.X-l_Me.X) < Abs(l_Me.Y-l_H.Y) then
       l_FavDir:= ftHorizontal
      else
       l_FavDir:= ftVertical;
      l_LegalDirs:= MoveDirs;
      l_DirToWorm:= CalcDir(l_Me, l_H, l_FavDir);
      if l_DirToWorm <> dtStop then
      begin
        Exclude(l_LegalDirs, l_DirToWorm); // на червяка не ползем
        Result:= InvertDir(l_DirToWorm);

        l_New:= MovePoint(l_Me, Result);
        // Нужно избегать стен и уходить с горизонтали головы червяка
        l_B:= Thing.World.GetNearestBorder(l_New, Direction2FavType(Result));
        l_DirToWall:= CalcDir(l_Me, l_B, l_FavDir);

        {
        if CalcDistance(l_B, l_New) < 3 then
        begin
          l_B2:= Thing.World.GetNearestBorder(l_New, Direction2FavType(ShiftDir(Result)));
          l_DirToWall2:= CalcDir(l_Me, l_B2, Direction2FavType(ShiftDir(Result)));
          Exclude(l_LegalDirs, l_DirToWall);
          Exclude(l_LegalDirs, l_DirToWall2);
          (*
          if l_Hunter.ToNeck <> l_DirToWorm then
            result:= l_Hunter.ToNeck
          else
            Result:= lp_ShiftDir(Result);
          *)
          Result:= lp_ShiftDir(Result);
          l_New:= MovePoint(l_Me, Result);
        end;
        }
        (*
        if CalcDistance(l_New, l_H) <= l_Distance then
          Result:= lp_ShiftDir(Result);
         *)

          while (not CheckPoint(l_Me, Result, weAny)) and (l_LegalDirs <> []) do
          begin
           Result:= lp_ShiftDir(Result);
           if l_LegalDirs = [] then
           begin
            if CheckPoint(l_Me, l_DirToWall, weAny) then
              Result:= l_DirToWall
            else
              Result:= dtNone;
            break;
           end;
          end; // while

        if not CheckPoint(l_Me, Result, weAny) then
          Result:= dtNone;
      end;
    end; // < 10
  end;
end;

end.
