unit wwTypes;
{ Базовые типы мира червяков  }

interface

type
 TwwDirection = (dtNone, dtStop, dtLeft, dtUp, dtRight, dtDown);
 TwwDirections = set of TwwDirection;
 TwwEntity = (weLive, weNotLive, weThink);
 TwwEntities = set of TwwEntity;
 TCurve = (ctNone, ctUp, ctDown, ctLeft, ctRight,
           ctLeftUp, ctLeftDown, ctRightUp, ctRightDown);
 TwwFavoriteType = (ftVertical, ftHorizontal);


const
  { Номера фрагментов червяка }
  ws_NoBody = 0; // пустая клетка
  ws_BodyV  = 1; // вертикальное тело
  ws_BodyH  = 2; // горизонтальное тело
  ws_HeadD  = 3; // голова вниз
  ws_HeadL  = 4; // голова вправо
  ws_HeadR  = 5; // голова влево
  ws_HeadU  = 6; // голова вверх
  ws_RotD   = 7; // поворот слева вниз
  ws_RotL   = 8; // поворот снизу направо
  ws_RotUL  = 9; // поворот слева вверх
  ws_RotUR  = 10; // поворот сверху направо
  ws_TailD  = 11; // хвост сверху
  ws_TailL  = 12; // хвост слева
  ws_TailR  = 13; // хвост справа
  ws_TailU  = 14; // хвост снизу
  ws_Target = 15; // цель

const
  weAny = [weLive, weNotLive];

const
  MoveDirs = [dtLeft, dtUp, dtRight, dtDown];
  
implementation


end.
