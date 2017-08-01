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
  Result:= '—умасшедшее €блоко'
end;

function TCrazyAppleMind.GetEnglishCaption: string;
begin
  Result:= 'Crazy Apple'
end;

function TCrazyAppleMind.Thinking: TwwDirection;
begin
  Result:= dtStop;
end;

end.
